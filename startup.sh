#!/bin/bash

pkill mysql
/usr/bin/mysqld_safe &
sleep 10s
#mysql -uroot -pNag123  -e 'create database  nconf';
# echo "GRANT ALL ON *.* TO admin@'%' IDENTIFIED BY 'changeme' WITH GRANT OPTION; FLUSH PRIVILEGES" | mysql
#echo "GRANT SELECT, INSERT, UPDATE, DELETE, CREATE, DROP, ALTER ON nconf.* \
#TO 'root'@'localhost' IDENTIFIED BY 'Nag123'"|mysql;
#s3cmd -c /.s3cfg  get   "s3://example-appops-nconf/${stack}/${colo}/nconf_dump.sql"
#mysql -u root -pNag123 nconf < nconf_dump.sql
mysql -uroot -pNag123 < /create_database.sql
cp -dpR /var/www/nconf/config.orig/* /var/www/nconf/config/
sed -ie "10s/NConf/nconf/g" /var/www/nconf/config/mysql.php
sed -ie "12s/link2db/nconf/g" /var/www/nconf/config/mysql.php
sed -ie "11s/^/#/g" /var/www/nconf/config/nconf.php
sed -ie "16s|^|define('NCONFDIR', \"/var/www/nconf/\")\;|g" /var/www/nconf/config/nconf.php
sed -ie "23s|/var/www/nconf/bin/nagios|/usr/local/nagios/bin/nagios|g" /var/www/nconf/config/nconf.php
mysql -unconf -pnconf nconf < /var/www/nconf/INSTALL/create_database.sql
rm -rfv /var/www/nconf/INSTALL /var/www/nconf/INSTALL.php /var/www/nconf/UPDATE /var/www/nconf/UPDATE.php


#killall mysqld
#sleep 10s

#/usr/bin/mysqld_safe

