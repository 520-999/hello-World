#!/bin/bash

catalog_details_tarena=`find /home/admin/tarena/ -type d -name "mgg*" | xargs du -hd 0`
total_catalog_size_tarena=`find /home/admin/tarena/ -type d -name "mgg*" | xargs du -hcd 0 | xargs -n2 | grep total | cut -d " " -f 1`
echo $catalog_details_tarena | xargs -n2 | awk -F"/" 'BEGIN {print "☯服务器IP是：176.1.20.20\n☯tarena目录大小: 800G  已使用: "'"$total_catalog_size_tarena"'"G\n☯目录使用明细如下:\n"} {printf "%-10s%-10s\n",$5,$1; print "-------------------"}' | mail -s "☯空间使用明细" yuesl@tedu.cn


echo $catalog_details_tarena | xargs -n2 | awk -F"/" 'BEGIN {print "☯服务器IP是：176.1.20.20\n☯tarena目录大小: 800G  已使用: "'"$total_catalog_size_tarena"'"G\n☯目录使用明细如下:\n"} {printf "%-10s%-10s\n",$5,$1; print "------------------"}' > /tmp/tarena.txt
catalog_details_office=$(find /home/admin/office/ -maxdepth 1 -type d | xargs du -hd 1)
echo $catalog_details_office | xargs -n2 | awk -F"/" 'BEGIN {print "☯office目录大小: 100G \n☯目录使用明细如下:\n"} {printf "%-20s%-15s\n",$5,$1; print "------------------"}' >> /tmp/tarena.txt
cat /tmp/tarena.txt | mail -s "☯空间使用明细" makai@tedu.cn
