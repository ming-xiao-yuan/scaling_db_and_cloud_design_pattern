#!/bin/bash

# Update all installed packages and their dependencies to their latest versions
sudo yum update -y

# Install expect 
sudo yum install expect -y

{
    echo "Start MySQL Server installation at $(date)"
    # Download the MySQL 8.0 community release package from the official MySQL repository
    sudo wget https://dev.mysql.com/get/mysql80-community-release-el9-1.noarch.rpm 

    # Install the downloaded MySQL community release package, which configures the MySQL repository on your system
    sudo dnf install mysql80-community-release-el9-1.noarch.rpm -y

    # Install MySQL Community Server from the newly configured repository
    sudo dnf install mysql-community-server -y

    # Start the MySQL server service
    sudo systemctl start mysqld

    # Wait for MySQL to fully start up and create the log file
    sleep 10

    # Extract the temporary password
    TEMP_PASSWORD=$(sudo grep 'temporary password' /var/log/mysqld.log | awk '{print $NF}')


    # Automate the mysql_secure_installation script

    sudo expect -f - <<-EOF
    spawn mysql_secure_installation

    expect "Enter password for user root:"
    send "$TEMP_PASSWORD\r"

    expect "New password:"
    send "Xinisboosted123!\r"

    expect "Re-enter new password:"
    send "Xinisboosted123!\r"

    expect "Change the password for root ? ((Press y|Y for Yes, any other key for No) :"
    send "y\r"

    expect "New password:"
    send "Xinisboosted123!\r"

    expect "Re-enter new password:"
    send "Xinisboosted123!\r"

    expect "Do you wish to continue with the password provided?(Press y|Y for Yes, any other key for No) :"
    send "y\r"

    expect "Remove anonymous users? (Press y|Y for Yes, any other key for No) :"
    send "n\r"

    expect "Disallow root login remotely? (Press y|Y for Yes, any other key for No) :"
    send "n\r"

    expect "Remove test database and access to it? (Press y|Y for Yes, any other key for No) :"
    send "n\r"

    expect "Reload privilege tables now? (Press y|Y for Yes, any other key for No) :"
    send "y\r"

    expect eof
EOF

    # Check the current status of the MySQL server service
    sudo systemctl status mysqld


sudo expect -f - <<-EOF
    spawn mysql -u root -p

    expect "Enter password:"
    send "Xinisboosted123!\r"

    expect eof
EOF

    echo "Finish MySQL Server installation at $(date)"

} >> /var/log/process.log 2>&1