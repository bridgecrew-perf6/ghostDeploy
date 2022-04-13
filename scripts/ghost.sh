#!/bin/bash

apt-get update && apt-get -y upgrade
apt-get -y install nginx

ufw allow 'Nginx Full'

apt-get -y install mysql-server
mysql -u root -e "ALTER USER 'root'@'localhost' IDENTIFIED WITH mysql_native_password BY '${sql_pass}';"


curl -sL https://deb.nodesource.com/setup_16.x | sudo -E bash
apt-get install -y nodejs

npm install ghost-cli@latest -g

chown -R ubuntu:ubuntu /var/www/
sudo -u ubuntu mkdir -p /var/www/${ghost_site} && chmod 775 /var/www/${ghost_site} && cd /var/www/${ghost_site}

sudo -u ubuntu ghost install \
            --url "${ghost_url}" \
            --admin-url "${ghost_admin_url}" \
            --ip "${server_ip}" \
            --db "mysql" \
            --dbhost "localhost" \
            --dbuser "root" \
            --dbpass "${sql_pass}" \
            --dbname "${ghost_site}_prod" \
            --process systemd \
            --no-prompt

# backup user for db dump
mysql -uroot -p${sql_pass} -e "CREATE USER 'backup'@'localhost' IDENTIFIED BY '###';GRANT ALL ON ${ghost_site}_prod.* TO 'backup'@'localhost';FLUSH PRIVILEGES;"

# Password here can also be more secure
cat > /home/ubuntu/.my.cnf <<EOF
[client]
user=backup
password="###"
EOF

chown ubuntu:ubuntu /home/ubuntu/.my.cnf && chmod 600 /home/ubuntu/.my.cnf

# Correct priviliges for the backup directory
mkdir /backup && chown -R ubuntu:ubuntu /backup && chmod 775 /backup

cat > /home/ubuntu/dbdump.sh <<EOF
#!/bin/bash

echo "Saving ${ghost_site} Database Backup $now"
mysqldump ${ghost_site}_prod | gzip > "/backup/$(date +'%Y-%m-%d')/ghost_prod.sql.gz"

echo "Compressing content folder"
tar -zcvf "/backup/$(date +'%Y-%m-%d')/content.tar.gz" --absolute-names /var/www/${ghost_site}/content/ > /dev/null
EOF

chmod +x /home/ubuntu/dbdump.sh

# Creating our cronjobs

sudo -u ubuntu crontab -l > mycron
echo "MAILTO=amuawiakha@gmail.com" >> mycron
echo "@daily bash /home/ubuntu/dbdump.sh" >> mycron
sudo -u ubuntu crontab mycron
rm mycron

# Should I set up a SMTP server