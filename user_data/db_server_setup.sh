cat > user_data/db_server_setup.sh << 'EOF'
#!/bin/bash
yum update -y
amazon-linux-extras install postgresql14 -y
/usr/bin/postgresql-setup --initdb

sudo sed -i 's/peer/md5/g' /var/lib/pgsql/data/pg_hba.conf
sudo sed -i 's/ident/md5/g' /var/lib/pgsql/data/pg_hba.conf
echo "host    all             all             10.0.0.0/16            md5" | sudo tee -a /var/lib/pgsql/data/pg_hba.conf
sudo sed -i "s/#listen_addresses = 'localhost'/listen_addresses = '*'/g" /var/lib/pgsql/data/postgresql.conf

systemctl start postgresql
systemctl enable postgresql
sleep 5

sudo -u postgres psql <<PSQLEOF
ALTER USER postgres PASSWORD 'postgres123';
CREATE DATABASE techcorp_db;
\q
PSQLEOF

sed -i 's/PasswordAuthentication no/PasswordAuthentication yes/' /etc/ssh/sshd_config
systemctl restart sshd
useradd -m dbadmin
echo "dbadmin:DbPassword123!" | chpasswd
usermod -aG wheel dbadmin
echo "Database setup completed" > /tmp/setup_complete.txt
EOF
