from flask import Flask, request, jsonify
import mysql.connector
import os

app = Flask(__name__)

# Configuration for the MySQL Manager Node
manager_db_config = {
    "host": os.environ.get(
        "MANAGER_DNS", "Unknown"
    ),  # Manager IP from environment variable
    "user": "root",  # Replace with your MySQL username
    "password": "",  # Replace with your MySQL password
    "database": "direct_db",  # Replace with your database name
}


@app.route("/health_check", methods=["GET"])
def health_check():
    print("Received health check request.")

    return "<h1>Hello, I am the proxy app {} and I am running! I have the manager DNS it's {}.</h1>".format(
        os.environ.get("PROXY_DNS", "Unknown"), manager_db_config["host"]
    )


@app.route("/query", methods=["POST"])
def query_db():
    data = request.json
    sql = data.get("sql")

    print("Received query request: {}".format(sql))

    if not sql:
        print("No SQL query provided.")
        return jsonify({"error": "No SQL query provided"}), 400

    try:
        conn = mysql.connector.connect(**manager_db_config)
        cursor = conn.cursor()
        cursor.execute(sql)

        if sql.strip().lower().startswith("select"):
            # Fetch results for SELECT queries
            result = cursor.fetchall()
            print("Query result: {}".format(result))
        else:
            # Commit changes for INSERT, UPDATE, DELETE queries
            conn.commit()
            result = {"message": "Query executed successfully"}
            print("Query executed successfully.")

        return jsonify(result)
    except mysql.connector.Error as err:
        print("Error executing query: {}".format(err))
        return jsonify({"error": str(err)}), 500
    finally:
        if conn and conn.is_connected():
            cursor.close()
            conn.close()
            print("MySQL connection closed.")


if __name__ == "__main__":
    print("Starting Proxy Flask App...")
    app.run(host="0.0.0.0", port=5000)
