#!/bin/bash
export DEBIAN_FRONTEND=noninteractive
export PATH=/opt/mysqlcluster/home/mysqlc/bin:$PATH

{
    # Update the system
    sudo apt-get update -y
    sudo apt-get upgrade -y

    # Create a directory for MySQL Cluster
    sudo mkdir -p /opt/mysqlcluster/home
    cd /opt/mysqlcluster/home

    MYSQL_CLUSTER_URL="https://downloads.mysql.com/archives/get/p/14/file/mysql-cluster-gpl-7.2.1-linux2.6-i686.tar.gz"
    
    sudo wget $MYSQL_CLUSTER_URL

    sudo tar xvf mysql-cluster-gpl-7.2.1-linux2.6-i686.tar.gz

    sudo ln -s mysql-cluster-gpl-7.2.1-linux2.6-i686 mysqlc

    echo 'export MYSQLC_HOME=/opt/mysqlcluster/home/mysqlc' | sudo tee /etc/profile.d/mysqlc.sh

    echo 'export PATH=$MYSQLC_HOME/bin:$PATH' | sudo tee -a /etc/profile.d/mysqlc.sh
    
    source /etc/profile.d/mysqlc.sh

    sudo mkdir -p /opt/mysqlcluster/deploy

    cd /opt/mysqlcluster/deploy

    sudo mkdir conf mysqld_data ndb_data

    cd conf

    # Create and write to my.cnf
    sudo bash -c 'cat <<EOF > /opt/mysqlcluster/deploy/conf/my.cnf
        [mysqld]
        ndbcluster
        datadir=/opt/mysqlcluster/deploy/mysqld_data
        basedir=/opt/mysqlcluster/home/mysqlc
        port=3306
        EOF'

    # Generate config.ini with dynamic IPs
    MANAGER_IP_CONTENT="[ndb_mgmd]
    hostname=${MANAGER_IP}
    datadir=/opt/mysqlcluster/deploy/ndb_data
    nodeid=1

    [ndbd default]
    noofreplicas=3
    datadir=/opt/mysqlcluster/deploy/ndb_data
    "

    echo "$MANAGER_IP_CONTENT" | sudo tee /opt/mysqlcluster/deploy/conf/config.ini

    # Add worker nodes
    NODEID=2
    for WORKER_IP in $WORKER_IPS; do
        WORKER_IP_CONTENT="[ndbd]
    hostname=${WORKER_IP}
    nodeid=${NODEID}
    "
        echo "$WORKER_IP_CONTENT" | sudo tee -a /opt/mysqlcluster/deploy/conf/config.ini
        ((NODEID++))
    done

    # Append mysqld to config.ini
    echo "[mysqld]
    nodeid=50" | sudo tee -a /opt/mysqlcluster/deploy/conf/config.ini

    cd /opt/mysqlcluster/home/mysqlc


} >> /var/log/progress.log 2>&1
