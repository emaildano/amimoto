#!/bin/sh
SERVERNAME=$1
INSTANCEID=`/usr/bin/curl -s http://169.254.169.254/latest/meta-data/instance-id`
PUBLICNAME=`/usr/bin/curl -s http://169.254.169.254/latest/meta-data/public-hostname`

cd /tmp/

/bin/cp -Rf /tmp/amimoto/etc/nginx/* /etc/nginx/
sed -e "s/\$host\([;\.]\)/$INSTANCEID\1/" /tmp/amimoto/etc/nginx/conf.d/default.conf > /etc/nginx/conf.d/default.conf
sed -e "s/\$host\([;\.]\)/$INSTANCEID\1/" /tmp/amimoto/etc/nginx/conf.d/backend.conf > /etc/nginx/conf.d/default.backend.conf
/bin/rm /etc/nginx/conf.d/backend.conf 
if [ "$SERVERNAME" != "$INSTANCEID" ]; then
  sed -e "s/\$host\([;\.]\)/$SERVERNAME\1/" /tmp/amimoto/etc/nginx/conf.d/default.conf | sed -e "s/ default;/;/" | sed -e "s/\(server_name \)_/\1$SERVERNAME/" > /etc/nginx/conf.d/$SERVERNAME.conf
  sed -e "s/\$host\([;\.]\)/$SERVERNAME\1/" /tmp/amimoto/etc/nginx/conf.d/backend.conf | sed -e "s/ default;/;/" | sed -e "s/\(server_name \)_/\1$SERVERNAME/" > /etc/nginx/conf.d/$SERVERNAME.backend.conf
fi
/sbin/service nginx restart

if [ "$SERVERNAME" = "$INSTANCEID" ]; then
  /bin/cp /tmp/amimoto/etc/php.ini /etc/
  /bin/cp -Rf /tmp/amimoto/etc/php.d/* /etc/php.d/
  /bin/cp /tmp/amimoto/etc/php-fpm.conf /etc/
  /bin/cp -Rf /tmp/amimoto/etc/php-fpm.d/* /etc/php-fpm.d/
  /sbin/service php-fpm restart
fi

if [ "$SERVERNAME" = "$INSTANCEID" ]; then
  /bin/cp /tmp/amimoto/etc/my.cnf /etc/
  /sbin/service mysql stop
  /bin/rm /var/lib/mysql/ib_logfile*
  /sbin/service mysql start
fi

/usr/bin/wget http://ja.wordpress.org/latest-ja.tar.gz > /dev/null 2>&1
/bin/tar xvfz /tmp/latest-ja.tar.gz > /dev/null 2>&1
/bin/rm /tmp/latest-ja.tar.gz
/bin/mv /tmp/wordpress /var/www/vhosts/$SERVERNAME

if [ -f /tmp/amimoto/wp-setup.php ]; then
  /usr/bin/php /tmp/amimoto/wp-setup.php $SERVERNAME $INSTANCEID $PUBLICNAME
fi

/bin/chown -R nginx:nginx /var/www/vhosts/$SERVERNAME
