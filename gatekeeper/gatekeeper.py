from flask import Flask, request, jsonify
import os
import requests
from sshtunnel import SSHTunnelForwarder


app = Flask(__name__)

# Fetch the TRUSTED_HOST_DNS environment variable
trusted_host_dns = os.environ.get("TRUSTED_HOST_DNS")
app.logger.warning("Trust Host DNS is: {}".format(trusted_host_dns))
if not trusted_host_dns:
    raise ValueError("Trust Host environment variable not set")

# SSH Tunnel setup
server = SSHTunnelForwarder(
    (trusted_host_dns, 22),  # Remote SSH server
    ssh_username="ubuntu",
    ssh_pkey="/etc/gatekeeper/my_terraform_key",
    remote_bind_address=(trusted_host_dns, 9000),  # Trusted Host server port
    local_bind_address=("127.0.0.1", 80),
)

try:
    server.start()  # Start SSH tunnel
    app.logger.warning("SSH Tunnel successfully established!")
except Exception as e:
    app.logger.error(f"Error establishing SSH Tunnel: {e}")
    raise


@app.route("/health_check", methods=["GET"])
def health_check():
    return "<h1>Hello, I am the gatekeeper app {} and I am running!.</h1>".format(
        os.environ.get("GATEKEEPER_DNS", "Unknown"),
    )


@app.route("/populate_tables", methods=["POST"])
def populate_tables():
    app.logger.warning("Received request to populate tables")
    try:
        trusted_host_url = f"http://{trusted_host_dns}/populate_tables"
        response = requests.post(trusted_host_url, json=request.get_json())
        return jsonify(response.json()), response.status_code
    except Exception as e:
        app.logger.error(f"Error in /populate_tables: {e}")
        return jsonify({"error": str(e)}), 500


@app.route("/fetch_direct", methods=["POST"])
def fetch_direct():
    app.logger.warning("Received direct fetch request")
    try:
        trusted_host_url = f"http://{trusted_host_dns}/fetch_direct"
        response = requests.post(trusted_host_url, json=request.get_json())
        return jsonify(response.json()), response.status_code
    except Exception as e:
        app.logger.error(f"Error in /fetch_direct: {e}")
        return jsonify({"error": str(e)}), 500


@app.route("/fetch_random", methods=["GET", "POST"])
def fetch_random():
    app.logger.warning("Received random fetch request")
    try:
        trusted_host_url = f"http://{trusted_host_dns}/fetch_random"
        response = requests.post(trusted_host_url, json=request.get_json())
        return jsonify(response.json()), response.status_code
    except Exception as e:
        app.logger.error(f"Error in /fetch_direct: {e}")
        return jsonify({"error": str(e)}), 500


@app.route("/fetch_customized", methods=["GET", "POST"])
def fetch_customized():
    app.logger.warning("Received customized fetch request")
    try:
        trusted_host_url = f"http://{trusted_host_dns}/fetch_customized"
        response = requests.post(trusted_host_url, json=request.get_json())
        return jsonify(response.json()), response.status_code
    except Exception as e:
        app.logger.error(f"Error in /fetch_direct: {e}")
        return jsonify({"error": str(e)}), 500


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000)
