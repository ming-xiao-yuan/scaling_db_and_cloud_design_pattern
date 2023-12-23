import os
import requests

# Fetch the PROXY_DNS environment variable
trusted_host_dns = os.environ.get("TRUSTED_HOST_DNS")
print("Trusted host dns is: {}".format(trusted_host_dns))
if not trusted_host_dns:
    raise ValueError("TRUSTED_HOST_DNS environment variable not set")

# Proxy populate URL
TRUSTED_HOST_POPULATE_URL = f"http://{trusted_host_dns}/populate_tables"

# Proxy direct URL
TRUSTED_HOST_DIRECT_URL = f"http://{trusted_host_dns}/fetch_direct"

# Proxy random URL
TRUSTED_HOST_RANDOM_URL = f"http://{trusted_host_dns}/fetch_random"

# Proxy customized URL
TRUSTED_HOST_CUSTOMIZED_URL = f"http://{trusted_host_dns}/fetch_customized"


def send_write_sql_requests(table_name, num_requests):
    write_query = f"INSERT INTO {table_name} (column1, column2) VALUES ('column1_value', 'column2_value')"
    print(f"Starting to send write requests to {table_name}...")

    for i in range(num_requests):
        # Send the SQL write query to the proxy server
        response = requests.post(TRUSTED_HOST_POPULATE_URL, json={"sql": write_query})
        if response.status_code != 200:
            print(f"Error executing query for {table_name}: {write_query}")
        else:
            print(f"Write request {i+1}/{num_requests} to {table_name} successful.")

    print(f"Completed sending {num_requests} write SQL requests to {table_name}.")


def send_read_sql_requests_direct():
    read_query = "SELECT * FROM direct_table LIMIT 1"
    print("Starting to send read direct requests to direct_table...")

    for i in range(20):
        # Send the SQL read query to the proxy server
        response = requests.post(TRUSTED_HOST_DIRECT_URL, json={"sql": read_query})
        if response.status_code != 200:
            print(f"Error executing direct read query: {read_query}")
        else:
            # Extract and print the response data
            response_data = response.json()
            print(
                f"Read direct request {i+1}/20 to direct_table successful. Response: {response_data}"
            )

    print("Completed sending 20 read SQL requests to direct_table.")


def send_read_sql_requests_random():
    read_query = "SELECT * FROM random_table LIMIT 1"
    print("Starting to send random read requests to random_table...")

    for i in range(20):
        # Send the SQL read query to the proxy server
        response = requests.post(TRUSTED_HOST_RANDOM_URL, json={"sql": read_query})
        if response.status_code != 200:
            print(f"Error executing random read query: {read_query}")
        else:
            # Extract and print the response data
            response_data = response.json()
            print(
                f"Read random request {i+1}/20 to random_table successful. Response: {response_data}"
            )

    print("Completed sending 20 random read SQL requests to random_table.")


def send_read_sql_requests_customized():
    read_query = "SELECT * FROM customized_table LIMIT 1"
    print("Starting to send customized read requests to customized_table...")

    for i in range(20):
        # Send the SQL read query to the proxy server
        response = requests.post(TRUSTED_HOST_CUSTOMIZED_URL, json={"sql": read_query})
        if response.status_code != 200:
            print(f"Error executing customized read query: {read_query}")
        else:
            # Extract and print the response data
            response_data = response.json()
            print(
                f"Read customized request {i+1}/20 to customized_table successful. Response: {response_data}"
            )

    print("Completed sending 20 customized read SQL requests to customized_table.")


def main():
    print("Script started. Sending SQL write requests...")

    # Send write requests for each table
    for table in ["direct_table", "random_table", "customized_table"]:
        send_write_sql_requests(table, 20)

    print("Finish populating tables.")

    print(
        "===================================DIRECT HIT==================================="
    )
    # Send read requests to direct_table
    send_read_sql_requests_direct()
    print("Script completed. All direct requests have been sent.")
    print(
        "===================================DIRECT HIT FINISHED==================================="
    )

    print(
        "===================================RANDOM HIT==================================="
    )
    # Send read requests to random_table
    send_read_sql_requests_random()
    print("Script completed. All radndom requests have been sent.")
    print(
        "===================================RANDOM HIT FINISHED==================================="
    )

    print(
        "===================================CUSTOMIZED HIT==================================="
    )
    # Send read requests to customized_table
    send_read_sql_requests_customized()
    print(
        "===================================CUSTOMIZED HIT FINISHED==================================="
    )


if __name__ == "__main__":
    main()
