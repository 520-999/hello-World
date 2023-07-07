#!/bin/bash
#判断网站能否访问

get_webscode() {

  # 获取系统时间
    error_time=$(date "+%Y-%m-%d %H:%M")
  # 网址列表
  weburl="www.njmgg.com \
          http://jspq008.f3322.net:8888/reservationSystem/loginAction"
  
  for i in $weburl; do
    # 获取状态码
      scode=$(curl -o /dev/null -sw "%{http_code}" $i | xargs)
      if [[ ${scode} != "200" ]]; then
        echo "$error_time : It's down    $i">>/root/web_error.log
        echo -e "$error_time  \n It's down    $i" | mail -s "✕✕ web is error" makai@tedu.cn
      fi
  done
}


