# **************************************************************************** #
#                                                                              #
#                                                         :::      ::::::::    #
#    Dockerfile                                         :+:      :+:    :+:    #
#                                                     +:+ +:+         +:+      #
#    By: asaadi <marvin@42.fr>                      +#+  +:+       +#+         #
#                                                 +#+#+#+#+#+   +#+            #
#    Created: 2020/01/24 11:41:31 by asaadi            #+#    #+#              #
#    Updated: 2020/01/30 19:46:17 by asaadi           ###   ########.fr        #
#                                                                              #
# **************************************************************************** #

FROM	debian:buster

#UPDATE
RUN		apt-get update && apt-get upgrade

#INSTALL NGINX WEB-SERVER
RUN		apt-get install -y nginx

#INSTALL MARIADB 'OPEN SOURCE' instead MYSQL (MANAGEMENT DATATBASES)
RUN		apt-get install -y mariadb-server	

#INSTAL PHP7.3
RUN		apt-get install -y php-fpm php-mysql php-mbstring php-zip php-gd php-xml php-pear; \
		apt-get install -y php-gettext php-cgi php-curl php-intl php-soap php-xmlrpc

#CONFIG NGINX FOR PHP PROCESSING "include index.php as value for 'index' to process PHP pages and
#Config nginx to pass PHP scripts to fastCGI server"
COPY	srcs/default /etc/nginx/sites-available/default

#DOWNLOAD PHPMYADMIN PACKAGES (wget command to Download ,unzip command to extract)
RUN		apt-get install -y wget unzip
RUN		wget https://files.phpmyadmin.net/phpMyAdmin/4.9.0.1/phpMyAdmin-4.9.0.1-all-languages.zip

#Extract to web server directory ,rename ,rename and edit the file config.inc.php
RUN		unzip phpMyAdmin-4.9.0.1-all-languages.zip -d /var/www/html/
RUN		mv	/var/www/html/phpMyAdmin-4.9.0.1-all-languages /var/www/html/phpmyadmin
RUN		rm /var/www/html/phpmyadmin/config.sample.inc.php
COPY	srcs/config.inc.php /var/www/html/phpmyadmin/
RUN		chmod 660 /var/www/html/phpmyadmin/config.inc.php
RUN		chown -R www-data:www-data /var/www/html/phpmyadmin

#Starting mysql service and create database phpmyadmin ,user
RUN		service mysql start; \
		mysql -u root -e "CREATE DATABASE phpmyadmin"; \
		mysql -u root -e "GRANT ALL PRIVILEGES ON *.* TO 'pma'@'localhost' IDENTIFIED BY 'pmapass';"; \
		mysql -u root -e "FLUSH PRIVILEGES;"

#INSTALL WORDPRESS
#1.Config a WP-DB
RUN		service mysql start; \
		mysql -u root -e "CREATE DATABASE wordpress;"; \
		mysql -u root -e "CREATE USER 'wp'@'localhost' identified by 'WPpass123'"; \
		mysql -u root -e "GRANT ALL PRIVILEGES ON wordpress.* TO 'wp'@'localhost';"; \
		mysql -u root -e "FLUSH PRIVILEGES;"
#2.Download and Install WP
RUN		cd /var/www/html/ && wget https://wordpress.org/latest.tar.gz; \
		tar -xvzf latest.tar.gz; \
		cd wordpress && rm wp-config-sample.php
COPY	srcs/wp-config.php /var/www/html/wordpress/
RUN		chown -R www-data:www-data /var/www/html/wordpress

#GENERATE SSL CERTIFICAT (The SSL kept secret ont the server andis used to encrypt content senty to clients
#The SSL cerf. is publicly shared with anyone requesting thecontemnt)
#1. Install SSL_utils
RUN		apt-get install -y openssl

#2. Create the SSL cert. self-signed
RUN		printf 'MA\ns\na\na\na\na\na\n' | openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout /etc/ssl/private/nginx-selfsigned.key -out /etc/ssl/certs/nginx-selfsigned.crt

#3. Config nginx to use ssl
COPY	srcs/self-signed.conf /etc/nginx/snippets/

#ROOT
CMD			service nginx start; \
			service mysql start; \
			service php7.3-fpm start; \
			bash
