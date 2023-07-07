#!/bin/bash
#PXE_SERVER 需要dhcp tftp ftp pxelinux.0 ks.cfg 系统光盘文件 initrd.img  splash.png  vesamenu.c32  vmlinuz (isolinux.cfg -->> default)
. ./public_functions

#----------------------------------------
logW "1.install DHCP software" && logY "yum -y install dhcp"
yum -y install dhcp
checkTF

logW "2.write in DHCP config_file /etc/dhcp/dhcp.conf" && logY "cat >/etc/dhcp/dhcpd.conf << EOF..."
cat >/etc/dhcp/dhcpd.conf << EOF
subnet 176.1.109.0 netmask 255.255.255.0 {
  range 176.1.109.100 176.1.109.200;
  option domain-name-servers 218.2.135.1;
  option routers 176.1.109.1;
  default-lease-time 600;
  max-lease-time 7200;
  next-server   176.1.109.51;
  filename  "pxelinux.0";
}
EOF
checkTF

logW "3.start DHCP service" && logY "systemctl enable --now  dhcpd"
systemctl enable --now  dhcpd
checkTF

logW "4.install tftp software" && logY "yum -y install tftp-server"
yum -y install tftp-server
checkTF

logW "5.start tftp service" && logY "systemctl enable --now tftp"
systemctl enable --now tftp
checkTF

logW "6.install vsftp software" && logY "yum -y install vsftpd"
yum -y install vsftpd
checkTF

logW "7.start vsftp service" && logY "systemctl enable --now vsftpd"
systemctl enable --now vsftpd
checkTF

create_Ks.cfg() {

cat >/var/ftp/ks.cfg << EOF
#platform=x86, AMD64, or Intel EM64T
#version=DEVEL
# Install OS instead of upgrade
install
# Keyboard layouts
keyboard 'us'
# Root password 123
rootpw --iscrypted \$1\$aO1Ww.Yo\$giO23b5GWFcXLF4K3XwNa/
# System language
lang en_US
# System authorization information
auth  --useshadow  --passalgo=sha512
# Use text mode install
text
# SELinux configuration
selinux --disabled
# Do not configure the X Window System
skipx

# Firewall configuration
firewall --disabled
# Network information
network  --bootproto=dhcp --device=eth0
# Reboot after installation
reboot
# System timezone
timezone Asia/Shanghai
# Use network installation
url --url="ftp://176.1.109.51/centos"
# System bootloader configuration
bootloader --append="net.ifnames=0 biosdevname=0" --location=mbr
# Clear the Master Boot Record
zerombr
# Partition clearing information
clearpart --all --initlabel
# Disk partitioning information
part / --fstype="xfs" --grow --size=1

%packages
@base

%end
EOF
}

if [ -f /var/ftp/ks.cfg ]; then
  logG "8. ks.cfg already exists"
else
  logW "8. crrate ks.cfg to /var/ftp/" && logY "cat >/var/ftp/ks.cfg << EOF..."
  create_Ks.cfg
  checkTF
fi

#----------------------------------------定义函数
download_Pxe_file.tar() {

  curl -o /var/lib/tftpboot/pxe_file.tar --create-dirs -# -c -O ftp://mybd.work/pxe_file.tar
}
#----------------------------------------

if [ -f /var/lib/tftpboot/pxe_file.tar ];then
  logG "9. pxe_file.tar already exists"
else
  logG "9. download... pxe_file.tar" && logY "curl -# -c -O ftp://mybd.work/pxe_file.tar"
  download_Pxe_file.tar
  checkTF
fi

logG "10. start tar pxe_file.tar" && logY "tar -xvf /var/lib/tftpboot/pxe_file.tar -C /var/lib/tftpboot/"
tar -xvf /var/lib/tftpboot/pxe_file.tar -C /var/lib/tftpboot/
checkTF

#----------------------------------------定义函数
download_CentOS-7-x86_64-DVD-2009.iso() {

  curl -o /var/lib/tftpboot/CentOS-7-x86_64-DVD-2009.iso --create-dirs -# -c -O ftp://mybd.work/CentOS-7-x86_64-DVD-2009.iso
}
#----------------------------------------

readonly centos_System7="CentOS-7-x86_64-DVD-2009.iso"

if [ -f /var/lib/tftpboot/$centos_System7 ]; then
  logG "11. $centos_System7 already exists"
else
  logG "11. Download... $centos_System7 system" && logY "curl -# -c -O ftp://mybd.work/CentOS-7-x86_64-DVD-2009.iso"
  download_CentOS-7-x86_64-DVD-2009.iso
  checkTF
fi

sed -i 's#^/var/lib/tftp.*##g' /etc/fstab
sed '$d' /etc/fstab
logG "12. start mount $centos_System7 to /var/ftp/centos/" && logY "mount /var/lib/tftpboot/$centos_System7 /var/ftp/centos/"
sed -i '$a/var/lib/tftpboot/CentOS-7-x86_64-DVD-2009.iso /var/ftp/centos/ iso9660 loop 0 0' /etc/fstab
mkdir -p /var/ftp/centos
mount -a
checkTF

systemctl disable --now firewalld
setenforce 0
