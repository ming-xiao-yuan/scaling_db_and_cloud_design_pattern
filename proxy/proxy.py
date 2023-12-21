import time
from flask import Flask, request, jsonify
from sshtunnel import SSHTunnelForwarder
import mysql.connector
import os
import random
import threading


app = Flask(__name__)

# Global variable to store the chosen worker node
chosen_worker_node = None

# Global variable for the SSH tunnel
ssh_tunnel = None

# Configuration for the MySQL Manager Node
manager_db_config = {
    "host": os.environ.get(
        "MANAGER_DNS", "Unknown"
    ),  # Manager IP from environment variable
    "user": "root",  # MySQL username
    "password": "",  # MySQL password
    "database": "main_db",  # Database name
}


def choose_random_worker_node():
    global chosen_worker_node
    worker_dns_list = os.environ.get("WORKER_DNS", "").split(",")
    if not worker_dns_list:
        raise ValueError("Worker DNS list is empty or not set")
    chosen_worker_node = random.choice(worker_dns_list)
    app.logger.warning("The chosen worker node is: {}".format(chosen_worker_node))


def create_ssh_tunnel():
    global ssh_tunnel
    while True:
        try:
            # Ensure a worker node is chosen
            if chosen_worker_node is None:
                choose_random_worker_node()

            # Establish SSH tunnel
            ssh_tunnel = SSHTunnelForwarder(
                (manager_db_config["host"], 22),
                ssh_username="ubuntu",
                ssh_pkey="/etc/proxy/my_terraform_key",
                remote_bind_address=(chosen_worker_node, 3306),
                local_bind_address=("127.0.0.1", 9000),
            )
            ssh_tunnel.start()
            app.logger.info("SSH tunnel established successfully.")
            break
        except Exception as e:
            app.logger.error(f"Failed to establish SSH tunnel: {e}")
            time.sleep(10)  # Retry after a delay


# Initialize the SSH tunnel when the app starts
threading.Thread(target=create_ssh_tunnel).start()


@app.route("/health_check", methods=["GET"])
def health_check():
    return "<h1>Hello, I am the proxy app {} and I am running! I have the manager DNS it's {}.</h1>".format(
        os.environ.get("PROXY_DNS", "Unknown"), manager_db_config["host"]
    )


@app.route("/populate_tables", methods=["POST"])
def populate_tables():
    request_counter = 0
    data = request.json
    sql_template = data.get("sql")
    table_names = ["direct_table", "random_table", "customized_table"]

    if not sql_template:
        return jsonify({"error": "No SQL query provided"}), 400

    # Determine the target table based on the request counter
    target_table = table_names[(request_counter // 20) % len(table_names)]
    sql = sql_template.format(table=target_table)

    # Initialize 'conn' and 'cursor' as None
    conn = None
    cursor = None

    try:
        conn = mysql.connector.connect(**manager_db_config)
        cursor = conn.cursor()
        cursor.execute(sql)

        conn.commit()
        result = {"message": f"Insert query executed successfully in {target_table}"}

        # Increment and reset the request counter
        request_counter = (request_counter + 1) % 60

        return jsonify(result)
    except mysql.connector.Error as err:
        return jsonify({"error": str(err)}), 500
    finally:
        # Close cursor and connection if they were successfully created
        if cursor:
            cursor.close()
        if conn and conn.is_connected():
            conn.close()


@app.route("/fetch_direct", methods=["POST"])
def fetch_direct():
    data = request.json
    sql = data.get("sql")

    if not sql:
        return jsonify({"error": "No SQL query provided"}), 400

    # Check if the query is a SELECT query for direct_table
    if (
        not sql.strip().lower().startswith("select")
        or "direct_table" not in sql.lower()
    ):
        return jsonify({"error": "Invalid query"}), 400

    # Initialize 'conn' and 'cursor' as None
    conn = None
    cursor = None

    try:
        conn = mysql.connector.connect(**manager_db_config)

        cursor = conn.cursor()
        cursor.execute(sql)
        result = cursor.fetchall()
        return jsonify(result)
    except mysql.connector.Error as err:
        return jsonify({"error": str(err)}), 500
    finally:
        # Close cursor and connection if they were successfully created
        if cursor:
            cursor.close()
        if conn and conn.is_connected():
            conn.close()


@app.route("/fetch_random", methods=["POST"])
def fetch_random():
    global chosen_worker_node
    data = request.json
    sql = data.get("sql")

    if not sql:
        return jsonify({"error": "No SQL query provided"}), 400

    if not sql.strip().lower().startswith("select"):
        return jsonify({"error": "Invalid query"}), 400

    conn = None
    cursor = None  # Initialize cursor to None

    if ssh_tunnel is None or not ssh_tunnel.is_active:
        return jsonify({"error": "SSH tunnel is not established"}), 500

    # Use the existing SSH tunnel for the database connection
    manager_tunnel = {
        "host": manager_db_config["host"],
        "user": "root",
        "password": "",
        "database": "main_db",
    }
    try:
        conn = mysql.connector.connect(**manager_tunnel)
        cursor = conn.cursor()
        cursor.execute(sql)
        result = cursor.fetchall()
        return jsonify(result)
    except mysql.connector.Error as err:
        app.logger.error("MySQL Error: {}".format(str(err)))
        return jsonify({"error": "MySQL Error: {}".format(str(err))}), 500
    finally:
        if cursor is not None:
            cursor.close()
        if conn is not None and conn.is_connected():
            conn.close()


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000)
