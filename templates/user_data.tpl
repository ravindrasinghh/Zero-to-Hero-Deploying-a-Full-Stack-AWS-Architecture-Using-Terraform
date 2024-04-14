#!/bin/bash
# Install Apache HTTP Server
yum install httpd stress amazon-efs-utils nfs-utils -y


# Start the httpd service
systemctl start httpd
systemctl enable httpd

# Ensure the directory exists and set permissions
mkdir -p /var/www/html/
chmod 755 /var/www/html


# Create a mount point
mkdir /mnt/efs
mount -t efs ${efs_file_system_id}:/ /mnt/efs
echo '${efs_file_system_id}:/ /mnt/efs efs defaults,_netdev 0 0' >> /etc/fstab

# Fetch the hostname of the instance
hostname=$(hostname)

# Create an index.html file and write the hostname to it
echo "Welcome to the world from $hostname" > /var/www/html/index.html

# Ensure the httpd service is enabled on boot
chkconfig httpd on
