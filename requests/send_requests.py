import os
import random
import requests

# Fetch the PROXY_DNS environment variable
proxy_dns = os.environ.get("PROXY_DNS")

# Check if PROXY_DNS is set
if not proxy_dns:
    raise ValueError("PROXY_DNS environment variable not set")

# Proxy server URL
PROXY_SERVER_URL = f"http://{proxy_dns}/direct"


def send_direct_sql_requests():
    read_query = "SELECT * FROM direct_table LIMIT 1"
    write_query = (
        "INSERT INTO direct_table (column1, column2) VALUES ('value1', 'value2')"
    )

    for _ in range(20):
        # Randomly choose between read and write query
        sql_query = random.choice([read_query, write_query])

        # Send the SQL query to the proxy server
        response = requests.post(PROXY_SERVER_URL, json={"sql": sql_query})
        if response.status_code != 200:
            print(f"Error executing query: {sql_query}")

    print("Completed sending 20 SQL requests.")


# Automatically send requests when the script is run
send_direct_sql_requests()
