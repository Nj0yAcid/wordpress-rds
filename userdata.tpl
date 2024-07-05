#!/bin/bash
# variable will be populated by terraform template
db_username=${db_username}
db_user_password=${db_user_password}
db_name=${db_name}
db_RDS=${db_RDS}
sudo yum install wget httpd mysql php php-mysql -y
sudo wget https://wordpress.org/latest.tar.gz
sudo tar -xzf latest.tar.gz
sudo cp -r wordpress/* /var/www/html
sudo amazon-linux-extras install -y lamp-mariadb10.2-php7.2 php7.2
sudo cd /var/www/html
sudo cp /var/www/html/wp-config-sample.php /var/www/html/wp-config.php
sudo sed -i 's/database_name_here/${db_name}/' /var/www/html/wp-config.php
sudo sed -i 's/username_here/${db_username}/' /var/www/html/wp-config.php
sudo sed -i 's/password_here/${db_user_password}/' /var/www/html/wp-config.php
sudo sed -i 's/localhost/${db_RDS}/' /var/www/html/wp-config.php
sudo sed -i "s/wp_/wp1_/g" wp-config.php
sudo sed -i "s/\$table_prefix = 'wp_';/\$table_prefix = 'wp2_';/g" /var/www/html/wp-config.php
sudo chown -R apache:apache /var/www/html
sudo systemctl start httpd 
sudo systemctl enable httpd 