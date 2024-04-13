#!/bin/bash
# Install Apache HTTP Server
yum install httpd -y

# Start the httpd service
systemctl start httpd
systemctl enable httpd

# Ensure the directory exists and set permissions
mkdir -p /var/www/html/
chmod 755 /var/www/html

# Fetch the hostname of the instance
hostname=$(hostname)

# Create an index.html file and write the hostname to it
echo "Welcome to the world from $hostname" > /var/www/html/index.html

# Ensure the httpd service is enabled on boot
chkconfig httpd on
