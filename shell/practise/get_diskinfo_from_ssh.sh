#!/bin/bash
#获取磁盘信息

logR() { echo -e "\e[31m $1 \e[0m"; }  #红色
logG() { echo -e "\e[32m $1 \e[0m"; }  #绿色
logY() { echo -e "\e[33m $1 \e[0m"; }  #黄色

#检查命令执行是否成功
checkTF() {
  if [[ $? -eq 0 ]]; then
    logG "success ↑↑↑      -->> return $?" && echo
  else
    logR "fail ↑↑↑      -->> return $?" && exit 0
  fi
}

#生成管理机公钥
create_id_rsa() {
  if [ -f ~/.ssh/id_rsa ];then
    logY "~/.ssh/id_rsa.pub 公钥已存在\n\n"
  else
    ssh-keygen -f ~/.ssh/id_rsa -P '' -q  &&  LogG "公钥创建成功"
  fi
}

#向被控主机传输公钥
copy_Hosts_id_rsa() {
  create_id_rsa
  logG "根据hosts文件向主机IP传输公钥"
  logY "ssh-copy-id -f -i ~/.ssh/id_rsa.pub -o StrictHostKeyChecking=no \$i"
  for i in `grep -Eo '[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}' /etc/hosts | grep -v '^127'`;do
    ssh-copy-id -f -i ~/.ssh/id_rsa.pub -o StrictHostKeyChecking=no $i
    checkTF
  done
}
copy_Hosts_id_rsa

write_awkfile() {
  for i in node1 node2; do
    ssh $i 'cat >/tmp/check_disk.awk <<-EOF
      BEGIN { printf "%-5s%-5s%-5s%-5s%-5s\n","挂载点","容量","已用","可用","使用百分比" }
      /\/$/{ printf "%-8s%-7s%-7s%-10s%-5s\n",\$6,\$2,\$3,\$4,\$5 }
EOF'
  done
}
write_awkfile

get_diskinfo() {
  for i in node1 node2; do
      logY "$i主机(磁盘信息):"
      ssh $i 'df -h | awk -f /tmp/check_disk.awk'
      echo ""
  done
}
while true; do clear && get_diskinfo && sleep 20; done
