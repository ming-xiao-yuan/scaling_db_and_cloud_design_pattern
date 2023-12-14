#!/bin/bash

# Access the ip addresses
source ip_addresses.sh

# Function to check if a service is up and running
check_service() {
  local url=$1
  http_status_code=$(curl -m 5 -s -o /dev/null -w "%{http_code}" "$url")
  echo $http_status_code
}

# Function to poll a service until it's up or the timeout is reached
poll_service() {
  local url=$1
  local service_name=$2
  SECONDS=0
  TIMEOUT=300 # Set a 5-minute timeout

  echo "Waiting for $service_name service at $url to start..."

  while true; do
      http_status=$(check_service $url)

      echo "Checking $service_name service... HTTP status: $http_status"

      if [ "$http_status" -eq 200 ]; then
          echo "$service_name service is now available."
          break
      fi

      if [ $SECONDS -ge $TIMEOUT ]; then
          echo "Timeout reached, $service_name service at $url is not available."
          return 1
      fi

      echo "Service not ready yet. Waiting for 10 seconds before retrying..."
      sleep 10 # Wait for 10 seconds before trying again
  done
  echo "Completed waiting for $service_name service."
  echo "MySQL cluster is ready."

}

# Check Proxy service
poll_service "http://$MANAGER_DNS/health_check" "Proxy"
