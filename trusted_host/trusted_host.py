from flask import Flask, request, jsonify
import os
import requests


app = Flask(__name__)

# Fetch the PROXY_DNS environment variable
proxy_dns = os.environ.get("PROXY_DNS")
app.logger.warning("Proxy DNS is: {}".format(proxy_dns))
if not proxy_dns:
    raise ValueError("PROXY_DNS environment variable not set")

# Define the proxy URLs
PROXY_POPULATE_URL = f"http://{proxy_dns}/populate_tables"
PROXY_DIRECT_URL = f"http://{proxy_dns}/fetch_direct"
PROXY_RANDOM_URL = f"http://{proxy_dns}/fetch_random"
PROXY_CUSTOMIZED_URL = f"http://{proxy_dns}/fetch_customized"


@app.route("/health_check", methods=["GET"])
def health_check():
    return "<h1>Hello, I am the trusted_host app {} and I am running!.</h1>".format(
        os.environ.get("TRUSTED_HOST_DNS", "Unknown"),
    )


@app.route("/populate_tables", methods=["POST"])
def populate_tables():
    app.logger.warning("Received request to populate tables")
    try:
        response = requests.request(
            method=request.method, url=PROXY_POPULATE_URL, json=request.get_json()
        )
        return jsonify(response.json()), response.status_code
    except Exception as e:
        app.logger.error("Error in /populate_tables: {}".format(e))
        return jsonify({"error": str(e)}), 500


@app.route("/fetch_direct", methods=["POST"])
def fetch_direct():
    app.logger.warning("Received direct fetch request")
    try:
        response = requests.post(PROXY_DIRECT_URL, json=request.get_json())
        return jsonify(response.json()), response.status_code
    except Exception as e:
        app.logger.error("Error in /fetch_direct: {}".format(e))
        return jsonify({"error": str(e)}), 500


@app.route("/fetch_random", methods=["GET", "POST"])
def fetch_random():
    app.logger.warning("Received random fetch request")
    try:
        response = requests.post(PROXY_RANDOM_URL, json=request.get_json())
        return jsonify(response.json()), response.status_code
    except Exception as e:
        app.logger.error("Error in /fetch_random: {}".format(e))
        return jsonify({"error": str(e)}), 500


@app.route("/fetch_customized", methods=["GET", "POST"])
def fetch_customized():
    app.logger.warning("Received customized fetch request")
    try:
        response = requests.post(PROXY_CUSTOMIZED_URL, json=request.get_json())
        return jsonify(response.json()), response.status_code
    except Exception as e:
        app.logger.error("Error in /fetch_customized: {}".format(e))
        return jsonify({"error": str(e)}), 500


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000)
