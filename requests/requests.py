import os
from flask import Flask, request, jsonify, render_template
import requests

app = Flask(__name__)

# Fetch the MANAGER_DNS environment variable
manager_dns = os.environ.get("MANAGER_DNS")

# Check if MANAGER_DNS is set
if not manager_dns:
    raise ValueError("MANAGER_DNS environment variable not set")

# Proxy server URL
PROXY_SERVER_URL = f"http://{manager_dns}:5000/query"


@app.route("/", methods=["GET", "POST"])
def index():
    if request.method == "POST":
        sql_query = request.form.get("sql_query")

        # Send the SQL query to the proxy server
        response = requests.post(PROXY_SERVER_URL, json={"sql": sql_query})

        if response.status_code == 200:
            return jsonify(response.json())
        else:
            return jsonify({"error": "Failed to execute query"}), response.status_code

    return render_template("index.html")


if __name__ == "__main__":
    app.run(debug=True)
