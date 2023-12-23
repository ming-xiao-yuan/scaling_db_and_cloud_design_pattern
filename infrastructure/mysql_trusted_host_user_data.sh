#!/bin/bash

# Set environment variables for non-interactive frontend and PATH
export DEBIAN_FRONTEND=noninteractive

{
    # Update package listings and upgrade the system
    sudo apt update -y
    sudo apt upgrade -y

    # Install necessary dependencies (Docker)
    sudo apt install -y docker.io

    # Start Docker
    sudo systemctl start docker
    sudo systemctl enable docker
    
    # Source the IP addresses
    source /tmp/ip_addresses.sh

    # Pull the latest proxy image from Docker Hub
    echo "Starting Docker image pull at $(date)"
    sudo docker pull mingxiaoyuan/trusted_host:latest
    echo "Docker image pull completed at $(date)"

    # Run the Flask app inside a Docker container
    sudo docker run -e PROXY_DNS="$PROXY_DNS" -p 80:5000 mingxiaoyuan/trusted_host:latest
} >> /var/log/progress.log 2>&1