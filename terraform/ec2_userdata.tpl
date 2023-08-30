#!/bin/bash
# Apache and WordPress installation at EC2 creation

# varaible will be populated by terraform template
db_username=${db_username}
db_user_password=${db_user_password}
db_name=${db_name}
db_RDS=${db_RDS}

# install LAMP Server
apt update  -y
apt upgrade -y
apt update  -y
apt upgrade -y
apt install -y apache2

apt install -y php
apt install -y php php-{pear,cgi,common,curl,mbstring,gd,mysqlnd,bcmath,json,xml,intl,zip,imap,imagick}

#and download mysql package to yum  and install mysql client from yum
apt install -y mysql-client-core-8.0

# starting apache  and register them to startup
systemctl enable --now  apache2

# wait for apache to start
echo "[pklawit] Pause for 1 minute"
sleep 60

# Change OWNER and permission of directory /var/www
usermod -a -G www-data ubuntu
chown -R ubuntu:www-data /var/www
find /var/www -type d -exec chmod 2775 {} \;
find /var/www -type f -exec chmod 0664 {} \;
echo "[pklawit] Changing permissions for /var/www/html"
chown -R ubuntu:www-data /var/www/html

#**********************Installing Wordpress using WP CLI********************************* 
echo "[pklawit] Installing WP"
curl -O https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar
chmod +x wp-cli.phar
# mv wp-cli.phar /usr/local/bin/wp
./wp-cli.phar core download --path=/var/www/html --allow-root
./wp-cli.phar config create --dbname=$db_name --dbuser=$db_username --dbpass=$db_user_password --dbhost=$db_RDS --path=/var/www/html --allow-root --extra-php <<PHP
define('FS_METHOD', 'direct');
define('WP_MEMORY_LIMIT', '128M');
define('WP_ENVIRONMENT_TYPE', 'development');
PHP

# Change permission of /var/www/html/
chown -R ubuntu:www-data /var/www/html
chmod -R 774 /var/www/html
rm /var/www/html/index.html
#  enable .htaccess files in Apache config using sed command
sed -i '/<Directory \/var\/www\/>/,/<\/Directory>/ s/AllowOverride None/AllowOverride all/' /etc/apache2/apache2.conf
a2enmod rewrite

# restart apache
systemctl restart apache2

echo "[pklawit] WordPress Installed"
echo "db_username: ${db_username}"
echo "db_user_password: ${db_user_password}"
echo "db_name: ${db_name}"
echo "db_RDS: ${db_RDS}"
