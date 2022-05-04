#!/bin/bash
sudo yum -y update
sudo yum -y install httpd

privIP=`curl http://169.254.169.254/latest/meta-data/local-ipv4`

cat <<EOF > /var/www/html/index.html
<html>
<b>Private IP is $privIP</b>
<br>
<b>Version 2.0</b>
</body>
</html>
EOF

sudo systemctl start httpd
sudo systemctl enable httpd
