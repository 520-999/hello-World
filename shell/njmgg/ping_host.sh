#!/bin/bash
# 统计运行中的机器并发邮件到邮箱makai@tedu.cn

# 获取当前时间
statistics_time=$(date "+%Y-%m-%d %H:%M")

# 写入文本前两行内容
echo -e "☯ 1 (统计时间：${statistics_time})" >/tmp/up_list.host
echo -e "☯ 运行中主机列表如下↓↓ \n\n" >>/tmp/up_list.host

# 获取运行中的主机数据
for subnet in {101..111} {21..24};do

   for ip in {2..254};do

       (ping -c 4 -i 0.4 -w 2 176.1.${subnet}.${ip}

       if [ $? -eq 0 ];then
           echo -e "176.1.${subnet}.${ip}" >>/tmp/up_list.host
       fi) &
   done

wait
cat >>/tmp/up_list.host << EOF
--------------------------
${subnet}网段有 `cat /tmp/up_list.host  | grep "176.1.${subnet}." | wc -l` 台机器运行中


EOF
done

# 统计运行中机器总数
runing_machines_counts=$(cat /tmp/up_list.host | grep "176.1." | wc -l)
# 替换文本文件/tmp/up_list.host第一行开头内容 "1"
sed -i "1s/1/共有 ${runing_machines_counts} 台机器运行中/" /tmp/up_list.host

runing_machines_list=$(cat /tmp/up_list.host)
if [[ $runing_machines_list ]]; then
#  echo "$runing_machines_list" | mail -s "☯明故宫未关机器列表" yuesl@tedu.cn
  echo "$runing_machines_list" | mail -s "☯明故宫未关机器列表" makai@tedu.cn
fi

# 打印脚本执行时间
echo -E "########## $SECONDS ##########"
