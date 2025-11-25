cat > user_data/web_server_setup.sh << 'EOF'
#!/bin/bash
yum update -y
yum install -y httpd

INSTANCE_ID=$(ec2-metadata --instance-id | cut -d " " -f 2)
AVAILABILITY_ZONE=$(ec2-metadata --availability-zone | cut -d " " -f 2)

cat > /var/www/html/index.html <<HTMLEOF
<!DOCTYPE html>
<html>
<head>
    <title>TechCorp Web Server</title>
    <style>
        body { font-family: Arial, sans-serif; max-width: 800px; margin: 50px auto; padding: 20px; background-color: #f0f0f0; }
        .container { background-color: white; padding: 30px; border-radius: 10px; box-shadow: 0 2px 10px rgba(0,0,0,0.1); }
        h1 { color: #0066cc; }
        .info { background-color: #e7f3ff; padding: 15px; border-left: 4px solid #0066cc; margin: 20px 0; }
    </style>
</head>
<body>
    <div class="container">
        <h1>🚀 Welcome to TechCorp!</h1>
        <p>Your web application is running successfully!</p>
        <div class="info">
            <strong>Server Information:</strong><br>
            Instance ID: $INSTANCE_ID<br>
            Availability Zone: $AVAILABILITY_ZONE<br>
            Status: ✅ Online
        </div>
        <p>Refresh to see load balancer distribute traffic!</p>
    </div>
</body>
</html>
HTMLEOF

sed -i 's/PasswordAuthentication no/PasswordAuthentication yes/' /etc/ssh/sshd_config
systemctl restart sshd
useradd -m webadmin
echo "webadmin:WebPassword123!" | chpasswd
usermod -aG wheel webadmin
systemctl start httpd
systemctl enable httpd
echo "Web server setup completed" > /tmp/setup_complete.txt
EOF
