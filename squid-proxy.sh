#!/bin/bash

# 更新软件包列表
sudo apt update

# 安装squid
echo "install squid..."
sudo apt install -y squid

# 安装squid-openssl
echo "install squid-openssl..."
sudo apt install -y squid-openssl

# 安装certbot
echo "install certbot..."
sudo apt install -y certbot

# 安装apache2-utils
echo "install apache2-utils..."
sudo apt install -y apache2-utils

echo "all package set."

# 提示用户输入域名
read -p "give a domain: " d

# 提示用户输入用户名
read -p "set a username: " u

# 提示用户输入密码
read -s -p "set a password: " p
echo # 输出一个新行

# 提示用户输入端口号
read -p "set a port number: " pt

# 打印输入的值（可选）
echo "Domain: $d"
echo "Username: $u"
echo "Password: $pt"

# 使用 certbot 来为给定的域名生成证书
echo "Request cert..."
sudo certbot certonly --standalone -d "$d"

# 使用 htpasswd 创建密码文件
echo "Create password file..."
sudo htpasswd -c -b /etc/squid/passwords "$u" "$p"

# 创建Squid配置
echo "Configure Squid..."
config="https_port $pt cert=/etc/letsencrypt/live/$d/fullchain.pem key=/etc/letsencrypt/live/$d/privkey.pem
auth_param basic program /usr/lib/squid/basic_ncsa_auth /etc/squid/passwords
auth_param basic realm proxy
acl authenticated proxy_auth REQUIRED
http_access allow authenticated
forwarded_for off"

# 将配置插入到/etc/squid/squid.conf文件的顶部
echo "$config" | sudo tee -a /etc/squid/squid.conf.temp
sudo cat /etc/squid/squid.conf >> /etc/squid/squid.conf.temp
sudo mv /etc/squid/squid.conf.temp /etc/squid/squid.conf

# 重新启动Squid以应用新配置
echo "Rebooting Squid..."
sudo systemctl restart squid

echo "Done."
