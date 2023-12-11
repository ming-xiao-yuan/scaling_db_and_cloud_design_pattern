#!/bin/bash

# Set environment variables for non-interactive frontend and PATH
export DEBIAN_FRONTEND=noninteractive
export PATH=/opt/mysqlcluster/home/mysqlc/bin:$PATH

{
    # Update and upgrade the system packages
    sudo apt-get update -y
    sudo apt-get upgrade -y

    # Create a directory structure for MySQL Cluster
    sudo mkdir -p /opt/mysqlcluster/home
    cd /opt/mysqlcluster/home

    # Download MySQL Cluster package
    MYSQL_CLUSTER_URL="http://dev.mysql.com/get/Downloads/MySQL-Cluster-7.2/mysql-cluster-gpl-7.2.1-linux2.6-x86_64.tar.gz"
    sudo wget $MYSQL_CLUSTER_URL

    # Extract the downloaded package
    sudo tar xvf mysql-cluster-gpl-7.2.1-linux2.6-x86_64.tar.gz

    # Create a symbolic link to the extracted directory for easier reference
    sudo ln -s mysql-cluster-gpl-7.2.1-linux2.6-x86_64 mysqlc

    # Set environment variables for MySQL Cluster and update the system PATH
    echo 'export MYSQLC_HOME=/opt/mysqlcluster/home/mysqlc' | sudo tee /etc/profile.d/mysqlc.sh
    echo 'export PATH=$MYSQLC_HOME/bin:$PATH' | sudo tee -a /etc/profile.d/mysqlc.sh
    
    # Reload the profile to apply the new PATH
    source /etc/profile.d/mysqlc.sh

    # Install additional required packages
    sudo apt-get update && sudo apt-get -y install libncurses5

    sudo mkdir -p /opt/mysqlcluster/deploy/ndb_data

    # Create an empty log file for node with ID 4
    sudo touch /opt/mysqlcluster/deploy/ndb_data/ndb_4_out.log
    sudo chown ubuntu:ubuntu /opt/mysqlcluster/deploy/ndb_data/ndb_4_out.log

    ndbd -c ec2-3-92-166-68.compute-1.amazonaws.com:1186
}>> /var/log/progress.log 2>&1