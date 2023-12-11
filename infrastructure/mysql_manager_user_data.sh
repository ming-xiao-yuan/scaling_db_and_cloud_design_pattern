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

    # Source the IP addresses
    source /tmp/ip_addresses.sh

    # Define the path to your config.ini file
    CONFIG_FILE="/opt/mysqlcluster/deploy/conf/config.ini"

    # Start writing to the config file
    echo "[ndb_mgmd]" > $CONFIG_FILE
    echo "hostname=${MANAGER_DNS}" >> $CONFIG_FILE
    echo "datadir=/opt/mysqlcluster/deploy/ndb_data" >> $CONFIG_FILE
    echo "nodeid=1" >> $CONFIG_FILE
    echo "" >> $CONFIG_FILE

    echo "[ndbd default]" >> $CONFIG_FILE
    echo "noofreplicas=3" >> $CONFIG_FILE
    echo "datadir=/opt/mysqlcluster/deploy/ndb_data" >> $CONFIG_FILE
    echo "" >> $CONFIG_FILE

    # Add each worker node
    NODEID=2
    for WORKER_DNS in "${WORKER_DNS[@]}"
    do
        echo "[ndbd]" >> $CONFIG_FILE
        echo "hostname=${WORKER_DNS}" >> $CONFIG_FILE
        echo "nodeid=${NODEID}" >> $CONFIG_FILE
        echo "" >> $CONFIG_FILE
        ((NODEID++))
    done

    echo "[mysqld]" >> $CONFIG_FILE
    echo "nodeid=50" >> $CONFIG_FILE

    # Go back to MySQLC directory
    cd /opt/mysqlcluster/home/mysqlc

    # Initialize MySQL data directory
    sudo scripts/mysql_install_db --no-defaults --datadir=/opt/mysqlcluster/deploy/mysqld_data

    # Start the MySQL Cluster Management Node
    sudo /opt/mysqlcluster/home/mysqlc/bin/ndb_mgmd -f /opt/mysqlcluster/deploy/conf/config.ini --initial --configdir=/opt/mysqlcluster/deploy/conf/ --ndb-nodeid=1

    sudo /opt/mysqlcluster/home/mysqlc/bin/ndb_mgm -e show

} >> /var/log/progress.log 2>&1
