#!/bin/bash

# Set environment variables for non-interactive frontend and PATH
export DEBIAN_FRONTEND=noninteractive
export PATH=/opt/mysqlcluster/home/mysqlc/bin:$PATH

# Source the IP addresses from a separate file
source ip_addresses.sh

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

    # Create directories for configuration, data for MySQLD and NDB
    sudo mkdir -p /opt/mysqlcluster/deploy
    cd /opt/mysqlcluster/deploy
    sudo mkdir conf mysqld_data ndb_data

    # Go to the configuration directory
    cd conf

    # Create and write the MySQLD configuration file
    sudo bash -c 'cat <<EOF > /opt/mysqlcluster/deploy/conf/my.cnf
    [mysqld]
    ndbcluster
    datadir=/opt/mysqlcluster/deploy/mysqld_data
    basedir=/opt/mysqlcluster/home/mysqlc
    port=3306
    EOF'

    # Display the Manager and Worker IPs for verification
    echo "Manager IP: $MANAGER_IP"
    echo "Worker IPs: ${WORKER_IPS[@]}"

    # Prepare the content for the MySQL Cluster configuration file
    CONFIG_INI_CONTENT="[ndb_mgmd]
    hostname=${MANAGER_IP}
    datadir=/opt/mysqlcluster/deploy/ndb_data
    nodeid=1

    [ndbd default]
    noofreplicas=3
    datadir=/opt/mysqlcluster/deploy/ndb_data

    [ndbd]
    hostname=${WORKER_IPS[0]}
    nodeid=2

    [ndbd]
    hostname=${WORKER_IPS[1]}
    nodeid=3

    [ndbd]
    hostname=${WORKER_IPS[2]}
    nodeid=4

    [mysqld]
    nodeid=50
    "

    # Write the MySQL Cluster configuration to the config.ini file
    echo "$CONFIG_INI_CONTENT" | sudo tee /opt/mysqlcluster/deploy/conf/config.ini

    # Go back to MySQLC directory
    cd /opt/mysqlcluster/home/mysqlc

    # Initialize MySQL data directory
    sudo scripts/mysql_install_db --no-defaults --datadir=/opt/mysqlcluster/deploy/mysqld_data

    # Start the MySQL Cluster Management Node
    sudo /opt/mysqlcluster/home/mysqlc/bin/ndb_mgmd -f /opt/mysqlcluster/deploy/conf/config.ini --initial --configdir=/opt/mysqlcluster/deploy/conf/ --ndb-nodeid=1

} >> /var/log/progress.log 2>&1
