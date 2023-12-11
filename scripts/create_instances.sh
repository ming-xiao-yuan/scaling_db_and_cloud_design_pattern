#!/bin/bash

# Access the environment variables
source env_vars.sh

# Change to the infrastructure directory
cd ../infrastructure

# Initialize and apply Terraform configuration
echo -e "Creating instances...\n"
terraform init
terraform apply -auto-approve -var="AWS_ACCESS_KEY=$AWS_ACCESS_KEY" -var="AWS_SECRET_ACCESS_KEY=$AWS_SECRET_ACCESS_KEY" -var="AWS_SESSION_TOKEN=$AWS_SESSION_TOKEN"

# Capture the IP addresses
MANAGER_IP=$(terraform output -raw mysql_cluster_manager_ip)
WORKER_IPS=$(terraform output -json mysql_cluster_worker_ips | grep -oP '(?<=\[|\,)\s*"\K[^"]+')

# Export the IPs to a file
echo "MANAGER_IP=$MANAGER_IP" > ../scripts/ip_addresses.sh
echo "WORKER_IPS=(${WORKER_IPS[@]})" >> ../scripts/ip_addresses.sh

# Convert IP addresses and transfer the file to the EC2 instance
cd ../scripts
echo -e "Converting IP addresses...\n"
./convert_ip_addresses.sh
scp -o StrictHostKeyChecking=no -i ../infrastructure/my_terraform_key ip_addresses.sh ubuntu@$MANAGER_IP:/tmp/ip_addresses.sh
