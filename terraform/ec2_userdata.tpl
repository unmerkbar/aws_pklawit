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
echo "[debug] Pause for 1 minute"
sleep 60

# Change OWNER and permission of directory /var/www
usermod -a -G www-data ubuntu
chown -R ubuntu:www-data /var/www
find /var/www -type d -exec chmod 2775 {} \;
find /var/www -type f -exec chmod 0664 {} \;
echo "[debug] Changing permissions for /var/www/html"
chown -R ubuntu:www-data /var/www/html

#**********************Installing Wordpress using WP CLI********************************* 
echo "[debug] Installing WP"
curl -O https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar
chmod +x wp-cli.phar
# mv wp-cli.phar /usr/local/bin/wp
./wp-cli.phar core download --path=/var/www/html --allow-root
./wp-cli.phar config create --dbname=$db_name --dbuser=$db_username --dbpass=$db_user_password --dbhost=$db_RDS --path=/var/www/html --allow-root --extra-php <<PHP
define('FS_METHOD', 'direct');
define('WP_MEMORY_LIMIT', '128M');
define('WP_ENVIRONMENT_TYPE', 'development');
PHP

# https://www.digitalocean.com/community/tutorials/how-to-use-wp-cli-to-manage-your-wordpress-site-from-the-command-line
echo "[debug] triggering initial setup"
./wp-cli.phar core install \
  --url="wordpress.net" \
  --title="WordPress in the cloud" \
  --admin_user="wordpress_admin" \
  --admin_password="wordpress_password" \
  --admin_email="pklawit@gmail.com" \
  --path=/var/www/html \
  --allow-root

# Change permission of /var/www/html/
chown -R ubuntu:www-data /var/www/html
chmod -R 774 /var/www/html
rm /var/www/html/index.html
#  enable .htaccess files in Apache config using sed command
sed -i '/<Directory \/var\/www\/>/,/<\/Directory>/ s/AllowOverride None/AllowOverride all/' /etc/apache2/apache2.conf
a2enmod rewrite

# restart apache
systemctl restart apache2

echo "[debug] WordPress Installed"
echo "db_username: ${db_username}"
echo "db_user_password: ${db_user_password}"
echo "db_name: ${db_name}"
echo "db_RDS: ${db_RDS}"

# enable ssl module in apache2
echo "[debug] enabling ssl module in apache2"
a2enmod ssl
systemctl restart apache2

# generate self-signed certificate - this will create: /etc/ssl/certs/apache-selfsigned.crt
echo "[debug] creating self-signed cert - will be stored under: /etc/ssl/certs/apache-selfsigned.crt"
openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout /etc/ssl/private/apache-selfsigned.key -out /etc/ssl/certs/apache-selfsigned.crt -subj "/C=PL/ST=KujPom/L=Bydgoszcz/O=Private/OU=IT Department/CN=wordpress.net"

echo "[debug] creating /etc/apache2/sites-available/wordpress.net.conf file" 
cat << 'EOF' > /etc/apache2/sites-available/wordpress.net.conf
<VirtualHost *:443>
   ServerName wordpress.net
   DocumentRoot /var/www/html

   SSLEngine on
   SSLCertificateFile /etc/ssl/certs/apache-selfsigned.crt
   SSLCertificateKeyFile /etc/ssl/private/apache-selfsigned.key
</VirtualHost>
EOF

echo "[debug] enabling wordpress.net site"
a2ensite wordpress.net.conf
systemctl restart apache2

#echo "[debug] simple ssl plugin install - not needed anymore"
#./wp-cli.phar plugin install really-simple-ssl --allow-root

# this script needs to be launched after the initial setup has been done
echo "[debug] creating php script to add admin user: /var/www/html/create-admin.php"
cat << 'EOF' > /var/www/html/create-admin.php
<?php
define('WP_USE_THEMES', true);
// Load the WordPress library.
require_once( dirname(__FILE__) . '/wp-load.php' );

// Set up the WordPress query.
wp();

$username = 'developer';
$password = 'developer123';
$email = 'developer@localhost.com';

// Create the new user
$user_id = wp_create_user( $username, $password, $email );

// Get current user object
$user = get_user_by( 'id', $user_id );

// Remove role
$user->remove_role( 'subscriber' );

// Add role
$user->add_role( 'administrator' );
EOF
