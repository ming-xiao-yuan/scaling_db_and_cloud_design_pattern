import os
import requests

# Fetch the PROXY_DNS environment variable
proxy_dns = os.environ.get("PROXY_DNS")

# Check if PROXY_DNS is set
if not proxy_dns:
    raise ValueError("PROXY_DNS environment variable not set")

# Proxy populate URL
PROXY_POPULATE_URL = f"http://{proxy_dns}/populate_tables"

# Proxy direct URL
PROXY_DIRECT_URL = f"http://{proxy_dns}/fetch_direct"


def send_write_sql_requests(table_name, num_requests):
    write_query = (
        f"INSERT INTO {table_name} (column1, column2) VALUES ('value1', 'value2')"
    )
    print(f"Starting to send write requests to {table_name}...")

    for i in range(num_requests):
        # Send the SQL write query to the proxy server
        response = requests.post(PROXY_POPULATE_URL, json={"sql": write_query})
        if response.status_code != 200:
            print(f"Error executing query for {table_name}: {write_query}")
        else:
            print(f"Write request {i+1}/{num_requests} to {table_name} successful.")

    print(f"Completed sending {num_requests} write SQL requests to {table_name}.")


def send_read_sql_requests_direct():
    read_query = "SELECT * FROM direct_table LIMIT 1"
    print("Starting to send read requests to direct_table...")

    for i in range(20):
        # Send the SQL read query to the proxy server
        response = requests.post(PROXY_DIRECT_URL, json={"sql": read_query})
        if response.status_code != 200:
            print(f"Error executing read query: {read_query}")
        else:
            # Extract and print the response data
            response_data = response.json()
            print(
                f"Read request {i+1}/20 to direct_table successful. Response: {response_data}"
            )

    print("Completed sending 20 read SQL requests to direct_table.")


def main():
    print("Script started. Sending SQL write requests...")

    # Send write requests for each table
    for table in ["direct_table", "random_table", "customized_table"]:
        send_write_sql_requests(table, 20)

    print("Finish populating tables.")

    print("Script started. Sending SQL read requests for direct hit...")
    # Send read requests to direct_table
    send_read_sql_requests_direct()

    print("Script completed. All requests have been sent.")


if __name__ == "__main__":
    main()
