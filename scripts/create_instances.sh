#!/bin/bash

# Access the env variables
source env_vars.sh

# Initialize Terraform
echo -e "Creating instances...\n"
cd ../infrastructure

# Initialize Terraform
terraform.exe init

# Plan Terraform and create a plan file
terraform.exe plan -out=tfplan -var="AWS_ACCESS_KEY=$AWS_ACCESS_KEY" -var="AWS_SECRET_ACCESS_KEY=$AWS_SECRET_ACCESS_KEY" -var="AWS_SESSION_TOKEN=$AWS_SESSION_TOKEN"

# Apply the Terraform configuration
terraform.exe apply -auto-approve tfplan

# Capture the IP addresses
export MANAGER_IP=$(terraform.exe output -raw mysql_cluster_manager_ip)

# Assuming the worker IPs output is a list of IPs in a JSON array format
export WORKER_IPS=$(terraform.exe output -json mysql_cluster_worker_ips | grep -oP '(?<=\[|\,)\s*"\K[^"]+')

# Export the IPs to a file
echo "MANAGER_IP=$MANAGER_IP" > ip_addresses.sh
echo "WORKER_IPS=(${WORKER_IPS[@]})" >> ip_addresses.sh

