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
MANAGER_IP=$(terraform.exe output -raw mysql_cluster_manager_ip)

# Assuming the worker IPs output is a list of IPs in a JSON array format
WORKER_IPS=$(terraform.exe output -json mysql_cluster_worker_ips | grep -oP '(?<=\[|\,)\s*"\K[^"]+')

# Export IPs to be used in the user data script
export MANAGER_IP
export WORKER_IPS
