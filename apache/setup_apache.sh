#!/bin/bash
# setup apache, caching, and install bc for 95th percentile script
# Ian Haddock Aug 5 2021


# install apache, tools, and bc for the script
#sudo yum update -y
sudo yum install -y httpd httpd-tools bc

# add folders
if [ ! -d /var/www/cache ]; then
  sudo mkdir /var/www/cache
  sudo chown apache:apache /var/www/cache
fi

if [ ! -d /var/www/html/logs_output ]; then
  sudo mkdir /var/www/html/logs_output
fi

# add test content
sudo cp -v ./part3and4.txt /var/www/html/logs_output/
sudo cp -v ./part1and2.txt /var/www/html/logs_output/

# add apache configs
sudo cp -v ./99-mod_cache_disk.conf /etc/httpd/conf.modules.d/99-mod_cache_disk.conf
sudo cp -v ./output.conf /etc/httpd/conf.d/output.conf

# add 18080 to SELinux http port allow rules
sudo semanage port -a -t http_port_t -p tcp 18080

# add firewall rule
firewall-cmd --add-port 18080/tcp

# optional make firewall rule permanent
firewall-cmd --add-port 18080/tcp --permanent

# startup apache 
sudo systemctl enable httpd
sudo systemctl start httpd

# test
echo "### httpd -t output:"
sudo httpd -t 


exit 0

