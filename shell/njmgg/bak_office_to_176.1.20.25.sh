#!/bin/bash
# 统计备份修改了哪些文件，每个小时一次，发送邮件到邮箱

log_filename=$(date "+%Y-%m-%d-%H-%M")
cat >>/home/admin/.office_baklog/${log_filename}.log << EOF
------------------------------------------------------------
`date "+%Y-%m-%d  %H:%M:%S"`
------------------------------------------------------------
EOF
rsync -av --delete /home/admin/office/ root@176.1.20.25:/home/office_backup_176.1.20.20/  >>/home/admin/.office_baklog/${log_filename}.log

# send_mailto_makai@tedu.cn.sh
rsync_information=`cat /home/admin/.office_baklog/${log_filename}.log`
rows=`cat /home/admin/.office_baklog/${log_filename}.log | wc -l`

if [ $rows -gt 7 ]; then
  echo "$rsync_information" | mail -s "☯176.1.20.20--rsync_information" makai@tedu.cn
fi
