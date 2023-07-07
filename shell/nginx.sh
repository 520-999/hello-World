#! /bin/bash
# install nginx
. ./public_functions

readonly nginx_Version="nginx-1.20.2.tar.gz"	# nginx压缩包名称
readonly nginx_Catalog="nginx-1.20.2"		# 压缩包解压后的目录名称
readonly nginx_Module="--prefix=/usr/local/nginx \
  --user=nginx \
  --with-http_ssl_module --with-select_module"  # nginx即将安装的模块

logW "1. 开始安装依赖包"
logY "yum -y install gcc prce-devel openssl-devel"
yum -y install gcc prce-devel openssl-devel
checkTF

logW "2. 开始下载 $nginx_Version"
logY "curl -o /tmp/$nginx_Version -# -c -O  https://nginx.org/download/$nginx_Version"
curl -o /tmp/$nginx_Version -# -c -O ftp://mybd.work/$nginx_Version
checkTF

logW "3. 开始解压 $nginx_Version"
logY "tar -xf /tmp/$nginx_Version"
tar -xvf /tmp/$nginx_Version -C /tmp
checkTF

logW "4. 进入 /tmp/$nginx_Catalog"
logY "cd /tmp/$nginx_Catalog"
cd /tmp/$nginx_Catalog
checkTF

logW "5. 开始编译并安装 $nginx_Version"
logY "./configure $nginx_Module && make && make install"
./configure $nginx_Module && make && make install
checkTF

logW "6. 添加用户 nginx"
logY "useradd -M -s /sbin/nologin nginx"
useradd -M -s /sbin/nologin nginx
if [[ $? -eq 0 || $? -eq 9 ]]; then
    logG "success ↑↑↑"
    echo " "
  else
    logR "fail ↑↑↑       -->> return $?"
    exit 0
  fi

logW "7. 创建用于nginx启动的systemd文件"
logY "cat >/usr/lib/systemd/system/nginx.service <<-EOF..."
cat >/usr/lib/systemd/system/nginx.service <<-EOF
[Unit]
Description=The Nginx HTTP Server
After=network.target remote-fs.target nss-lookup.target

[Service]
Type=forking
PIDFile=/run/nginx.pid
ExecStartPre=/usr/bin/rm -f /run/nginx.pid
ExecStartPre=/usr/local/nginx/sbin/nginx -t -q
ExecStart=/usr/local/nginx/sbin/nginx -g "pid /run/nginx.pid;"
ExecReload=/usr/local/nginx/sbin/nginx -t -q
ExecReload=/usr/local/nginx/sbin/nginx -s reload -g "pid /run/nginx.pid;"

ExecStop=/bin/kill -s HUP \${MAINPID}
KillSignal=SIGQUIT
TimeoutStopSec=5
KillMode=process
PrivateTmp=ture

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
checkTF

logW "8. 启动nginx..."
logY "systemctl enable --now  nginx"
systemctl enable --now  nginx
checkTF

logW "9. 显示nginx信息和监听端口"
logY "/usr/local/nginx/sbin/nginx -V  && netstat -tupln | grep Proto && netstat -tupln | grep nginx"
/usr/local/nginx/sbin/nginx -V
echo "##-----------------------------------------------------------------------------------"
netstat -tupln | grep Proto && netstat -tupln | grep nginx
checkTF

logW "10. 放行80端口"
getFirewalldStatus
if [[ $? -eq 0 ]]; then
  logY "firewall-cmd --zone=public --add-port="80"/"tcp" --permanent"
  firewall-cmd --zone=public --add-port="80"/"tcp" --permanent 2>/dev/null
  firewall-cmd --reload &>/dev/null
  echo ""
else
  logR "防火墙未开启"
  echo ""
fi

rm -rf /tmp/$nginx_Version /tmp/$nginx_Catalog

wordpress_Download() {
cat >/usr/local/nginx/html/wordpress_download.sh <<-EOF
#!/bin/bash
# download wordpress
clear

echo "1. 切换目录至 /usr/local/nginx/html/"
echo "cd /usr/local/nginx/html/"
cd /usr/local/nginx/html/ && echo "success change dir"
echo "" && sleep 5

echo "2. 开始下载wordpress"
echo "curl -# -O https://cn.wordpress.org/latest-zh_CN.zip"
curl -# -O https://cn.wordpress.org/latest-zh_CN.zip && echo "success download wordpress"
echo "" && sleep 5

echo "3. 开始解压wordpress"
echo "unzip latest-zh_CN.zip"
unzip latest-zh_CN.zip && echo "success upzip wordpress"
echo "" && sleep 5

echo "4. 删除wordpressi压缩包"
echo "rm -f latest-zh_CN.zip"
rm -f latest-zh_CN.zip && echo "success rm wordpress"
echo "" && sleep 5

EOF
}

nginx_Config() {
    server {
        listen       80 default;
        server_name  www.njmgg.com njmgg.com;
        expires      12h;

        location / {
            root   /usr/share/nginx/html/njmgg_html;
            index  index.html;
        }

        rewrite ^/tmooc/$ /tmooc/index.html;
        rewrite ^/document$ /note/document.txt;
        rewrite ^/samba$ /note/samba.pdf;
        rewrite ^/nginx$ /note/nginx.pdf;
        rewrite ^/ansible$ /note/ansible.pdf;
        rewrite ^/facts$ /note/facts.pdf;
        rewrite ^/rhce$ /note/RHCE_MAKAI.pdf;
}


    server {
        listen       80;
        server_name  www.zhoujiao.top zhoujiao.top;
        expires      12h;

        location / {
            root   /usr/share/nginx/html/zj_html;
            index  index.html;
        }
}

}
