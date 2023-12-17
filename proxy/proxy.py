from flask import Flask, request, jsonify
import mysql.connector
import os

app = Flask(__name__)

# Global request counter
request_counter = 0

# Configuration for the MySQL Manager Node
manager_db_config = {
    "host": os.environ.get(
        "MANAGER_DNS", "Unknown"
    ),  # Manager IP from environment variable
    "user": "root",  # MySQL username
    "password": "",  # MySQL password
    "database": "main_db",  # Database name
}


@app.route("/health_check", methods=["GET"])
def health_check():
    print("Received health check request.")

    return "<h1>Hello, I am the proxy app {} and I am running! I have the manager DNS it's {}.</h1>".format(
        os.environ.get("PROXY_DNS", "Unknown"), manager_db_config["host"]
    )


@app.route("/populate_tables", methods=["POST"])
def populate_tables():
    global request_counter
    print("Populating tables...")
    data = request.json
    sql_template = data.get("sql")
    table_names = ["direct_table", "random_table", "customized_table"]

    if not sql_template:
        print("No SQL query provided.")
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
        print(f"Insert query executed successfully in {target_table}.")

        # Increment and reset the request counter
        request_counter = (request_counter + 1) % 60

        return jsonify(result)
    except mysql.connector.Error as err:
        print("Error executing query:", err)
        return jsonify({"error": str(err)}), 500
    finally:
        # Close cursor and connection if they were successfully created
        if cursor:
            cursor.close()
        if conn and conn.is_connected():
            conn.close()
            print("MySQL connection closed.")


@app.route("/fetch_direct", methods=["POST"])
def fetch_direct():
    print("Received direct query request")
    data = request.json
    sql = data.get("sql")

    print("Received query request: {}".format(sql))

    if not sql:
        print("No SQL query provided.")
        return jsonify({"error": "No SQL query provided"}), 400

    # Check if the query is a SELECT query for direct_table
    if (
        not sql.strip().lower().startswith("select")
        or "direct_table" not in sql.lower()
    ):
        print("Invalid query. Only SELECT queries for direct_table are allowed.")
        return jsonify({"error": "Invalid query"}), 400

    # Initialize 'conn' and 'cursor' as None
    conn = None
    cursor = None

    try:
        conn = mysql.connector.connect(**manager_db_config)
        cursor = conn.cursor()
        cursor.execute(sql)

        # Fetch results for SELECT queries
        result = cursor.fetchall()
        print("Received select query result:", result)

        return jsonify(result)
    except mysql.connector.Error as err:
        print("Error executing query:", err)
        return jsonify({"error": str(err)}), 500
    finally:
        # Close cursor and connection if they were successfully created
        if cursor:
            cursor.close()
        if conn and conn.is_connected():
            conn.close()
            print("MySQL connection closed.")


if __name__ == "__main__":
    print("Starting Proxy Flask App...")
    app.run(host="0.0.0.0", port=5000)
