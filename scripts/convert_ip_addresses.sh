#!/bin/bash

# Source the IP addresses
source ./ip_addresses.sh

# Function to convert IP to AWS EC2 DNS format
convert_ip_to_dns() {
    local ip=$1
    echo "ec2-${ip//./-}.compute-1.amazonaws.com"
}

# Prepare a new file to store the converted addresses
converted_file="converted_ip_addresses.sh"

# Convert Manager IP and write to new file
manager_dns=$(convert_ip_to_dns $MANAGER_IP)
echo "MANAGER_DNS=$manager_dns" > $converted_file

# Convert Worker IPs and append to new file
echo -n "WORKER_DNS=(" >> $converted_file
for ip in "${WORKER_IPS[@]}"; do
    worker_dns=$(convert_ip_to_dns $ip)
    echo -n "\"$worker_dns\" " >> $converted_file
done
echo ")" >> $converted_file

# Move the new file to replace the original ip_addresses.sh
mv $converted_file ip_addresses.sh
