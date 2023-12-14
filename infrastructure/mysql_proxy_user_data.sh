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
    sudo docker pull mingxiaoyuan/proxy:latest
    echo "Docker image pull completed at $(date)"

    # Run the Flask app inside a Docker container
    sudo docker run -e MANAGER_DNS="$MANAGER_DNS" -p 80:5000 mingxiaoyuan/proxy:latest

} >> /var/log/progress.log 2>&1

