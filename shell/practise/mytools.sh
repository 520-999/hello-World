#!/bin/bash

#提醒用户输入前的提醒语，echo不换行
tips() {
  echo -e -n "\033[1;35m $1 \033[0m"
}

execTips() {
  tips "$1 [y/n]":

  read input

  case $input in

    [yY][eE][sS] | [yY])
      return 1
      ;;
    *)
      exit 0
      ;;
  esac
}

#日志输出
logG() {
  echo -e "\033[1;32m $1 \033[0m" && sleep 3	#绿色
}
logY() {
  echo -e "\033[1;33m $1 \033[0m" && sleep 3	#黄色
}
logR() {
  echo -e "\033[1;31m $1 \033[0m" && sleep 3	#红色
}

changMinimal() {
  logG "增添命令补全功能"
  yum -y install bash-completion
}

#--------------------------------------------------------------------------------检查判断的函数
#检查命令执行是否成功
checkTF() {
  if [ $? -eq 0 ]; then
    logG "↑成功" && echo "" && echo ""
  else
    logR "↑失败" && exit 0
  fi
}

#查询MySQL状态 开启返回1 关闭返回0
getMySQLStatus() {
  status=$(systemctl status mysqld)
  result=$(echo "$status" | grep "active (running)")

  if [[ "$result" != "" ]]; then
    return 1
  else
    return 0
  fi
}

#查询防火墙状态 开启返回1 关闭返回0
getFirewalldStatus() {
  firewall-cmd --state &> /dev/null

  if [[ $? -eq 0 ]]; then
    return 1
  else
    return 0
  fi
}

#传入一个软件名称，检测该软件是否安装，已安装时返回1，未安装时安装成功返回1，安装失败时结束脚本
checkSoft() {
  if [ "$(yum list installed | grep ^$1)" == "" ]; then
    logR "检测到系统缺少执行所需的$1命令，自动开始安装..."
    sleep 2
    yum -y install $1
    if test $? -eq 0; then
      logG "$1环境安装完成!"
      return 1
    else
      logR "$1环境安装失败!请手动安装$1或重试！"
      exit 0
    fi
  else
    return 1
  fi
}

#--------------------------------------------------------------------------------
#更换yum源为阿里源
switchYumRepoToAliYun() {
  logG "开始拉取阿里源仓库..."
  logY "--> curl -o /etc/yum.repos.d/CentOS-Base.repo https://mirrors.aliyun.com/repo/Centos-7.repo"
  curl -o /etc/yum.repos.d/CentOS-Base.repo https://mirrors.aliyun.com/repo/Centos-7.repo &> /dev/null
  checkTF && yum clean all > /dev/null && yum -y install postfix > /dev/null && yum repolist
}

#更换yum源为网易源
switchYumRepoToWangyi() {
  logG "开始拉取网易源仓库..."
  logY "--> curl -o /etc/yum.repos.d/CentOS-Base.repo http://mirrors.163.com/.help/CentOS7-Base-163.repo"
  curl -o /etc/yum.repos.d/CentOS-Base.repo http://mirrors.163.com/.help/CentOS7-Base-163.repo &> /dev/null
  checkTF && yum clean all > /dev/null && yum repolist
}

#开启或关闭防火墙
enableOrDisEnableFirewalld() {
  getFirewalldStatus
  if [ $? -eq 1 ]; then
    tips "检测到防火墙开启状态，是否关闭? 输入Y关闭,输入N取消 [y/n]:"
    read -r isClose

    case $isClose in
      [yY][eE][sS] | [yY])
        systemctl disable --now firewalld
        if [ $? -eq 0 ]; then
          logG "防火墙关闭成功！"
        else
          logR "防火墙关闭失败！"
        fi
        ;;
      *)
        exit 0
        ;;
    esac

  else
    tips "检测到防火墙关闭状态，是否开启? 输入Y开启,输入N取消 [y/n]:"
    read -r isOpen

    case $isOpen in
      [yY][eE][sS] | [yY])
        systemctl enable --now firewalld
        if [ $? -eq 0 ]; then
          logG "防火墙开启成功！"
        else
          logR "防火墙开启失败！"
        fi
        ;;
      *)
        exit 0
        ;;
    esac

  fi
}

#查看全部开放的端口
getOpenedFirewallPorts() {
  openedPorts=$(firewall-cmd --list-port)

  for portStr in $openedPorts; do
    echo "$portStr"
  done
}

#查询指定端口是否开放 开放返回1 未开放返回0
selectPortStatus() {
  getFirewalldStatus

  if [ $? == 1 ]; then
    status=$(firewall-cmd --query-port=$1/$2)

    if [ $? == 0 ]; then
      if [ $status == "yes" ]; then
        return 1
      else
        return 0
      fi
    fi
  else
    return 0
  fi
}

#开启/关闭指定端口，参数1：0关闭 1开启 参数2：端口号 参数三：协议名称，如tcp.udp等
openOrCloseFirewallPort() {

  selectPortStatus "$2" "$3"

  isOpen=$?

  if [ "$1" == 0 ]; then
    #关闭指定端口
    if [ $isOpen == 0 ]; then
      logR "${2}端口处于未放行状态，请勿重复关闭"
      exit 0
    fi
    logG "正在关闭$2端口..."
    firewall-cmd --zone=public --remove-port="${2}"/"${3}" --permanent
    if [ $? == 0 ]; then
      firewall-cmd --reload
      logG "$2/$3端口关闭成功"
    else
      logR "$2/$3端口关闭失败"
    fi
  fi

  if [ $1 == 1 ]; then

    if [ $isOpen == 1 ]; then
      logR "${2}端口处于已放行状态，请勿重复放行！"
      exit 0
    fi
    #开启指定端口
    logG "正在开启${2}/${3}端口..."
    firewall-cmd --zone=public --add-port="$2"/"$3" --permanent
    if [ $? == 0 ]; then
      firewall-cmd --reload
      logG "$2/$3端口开启成功"
    else
      logR "$2/$3端口开启失败"
    fi
  fi

}

#4
fun4() {
  #开启关闭指定端口
  tips "请输入要操作的端口："
  read port

  if [[ $port -gt 65535 ]] || [[ $port -le 0 ]]; then
    logR "端口输入有误，范围1~65535"
    exit 0
  fi

  tips "请输入要操作的端口协议(默认为tcp，直接敲回车使用默认协议)："
  read inputChell

  if test -z $inputChell; then
    inputChell="tcp"
  fi

  tips "请输入操作类型(0关闭,1开启):"
  read doType

  case $doType in
    [0] | [1])
      openOrCloseFirewallPort $doType $port $inputChell
      ;;
    *)
      logR "操作类型输入有误，0关闭，1开启"
      exit 0
      ;;
  esac

}

#5
fun5() {
  tips "请输入要查询的端口："
  read port

  if [[ $port -gt 65535 ]] || [[ $port -le 0 ]]; then
    logR "端口输入有误，范围1~65535"
    exit 0
  fi

  checkSoft "lsof"

  lsof -i:$port
}

#6
fun6() {
  tips "请输入要杀死的端口："
  read port

  if [[ $port -gt 65535 ]] || [[ $port -le 0 ]]; then
    logR "端口输入有误，范围1~65535"
    exit 0
  fi

  processID=$( (netstat -nlp | grep :$port | awk '{print $7}' | awk -F"/" '{ print $1 }'))

  if test -z "$processID"; then
    logR "未找到$port,请确认该端口是否已经启动并运行后再试！"
  else
    kill -9 $processID
    if [ $? == 0 ]; then
      logG "操作成功！${port}端口已杀死！"
    else
      logR "操作失败！${port}端口杀死失败,请重试！"
    fi
  fi
}

#下载进度处理
progressfilt() {
  local flag=false c count cr=$'r' nl=$'n'
  while IFS='' read -d '' -rn 1 c; do
    if $flag; then
      printf '%s' "$c"
    else
      if [[ $c != $cr && $c != $nl ]]; then
        count=0
      else
        ((count++))
        if ((count > 1)); then
          flag=true
        fi
      fi
    fi
  done
}


#--------------------------------------------------------------------------------数据库模块开始
readonly MYSQL_CONFIG_FILEPATH="/etc/my.cnf"	#MySQL配置文件地址
readonly ENABLE_GM_LINE=0			#是否开启GM线路 0关闭 1开启
readonly dbPassword="betavip"			#由外部修改的变量 数据库密码
readonly dbPort="3306"
readonly asktaoSQLPATH=$basePath/asktao.sql	#由外部修改的变量 SQL脚本路径

installMySQL5.7() {                             #安装数据库函数模块

  yum install -y postfix > /dev/null
  logG "下载MySQL5.7 repo源..."
  logY "--> wget http://repo.mysql.com//mysql57-community-release-el7-7.noarch.rpm"
  wget http://repo.mysql.com//mysql57-community-release-el7-7.noarch.rpm && checkTF

	logG "安装MySQL5.7 repo源..."
	logY "--> yum reinstall -y mysql57-community-release-el7-7.noarch.rpm"
	yum localinstall -y mysql57-community-release-el7-7.noarch.rpm && checkTF && yum clean all && yum repolist
	rm -f mysql57-community-release-el7-7.noarch.rpm
	
  logG "开始安装MySQL5.7 社区版服务器..."
  logY "-->yum -y install mysql-community-server"
  yum -y install mysql-community-server && checkTF
}

setMySQL5.7() {
  logG "开始修改mysql配置文件..."
  sed -i '$a\federated' /etc/my.cnf
  sed -i '$a\max_connections = 20000' /etc/my.cnf
  sed -i '$a\max_allowed_packet = 64M' /etc/my.cnf

  sed -i '$a\skip-grant-tables=1' /etc/my.cnf
  sed -i '$a\character_set_server=latin1' /etc/my.cnf
  sed -i '$a\collation-server=latin1_swedish_ci' /etc/my.cnf
  sed -i '$a\sql_mode=NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION' /etc/my.cnf
  sed -i '$a\log_timestamps=SYSTEM' /etc/my.cnf

  sed -i '$a\[client]' /etc/my.cnf
  sed -i '$a\default-character-set=latin1' /etc/my.cnf
  sed -i '$a\[mysql]' /etc/my.cnf
  sed -i '$a\default-character-set=latin1' /etc/my.cnf

  sed -i "/\[mysqld\]/a\\port=$dbPort" /etc/my.cnf
  sed -i "/\[client\]/a\\port=$dbPort" /etc/my.cnf

  /usr/sbin/setenforce 0
  systemctl enable --now mysqld
  if [ $? -eq 0 ];then
    logG "mysql启动成功"
  else
    logR "mysql启动失败"
  fi

  #查询默认密码
  defaulrpsw="$(grep "password is generated" /var/log/mysqld.log | awk '{print $NF}')"
  logG "开始设置用户名密码..."

  mysql --connect-expired-password -uroot -p$defaulrpsw >/dev/null 2>&1 <<EOF
    set global validate_password_policy=0;set global validate_password_mixed_case_count=0;set global validate_password_number_count=3;set global validate_password_special_char_count=0;set global validate_password_length=3;set password=password("$dbPassword");flush privileges;
EOF

  mysql --connect-expired-password -uroot -p$dbPassword >/dev/null 2>&1 <<EOF
    select user,host from mysql.user;update mysql.user set host='%' where user='root' and host='localhost';flush privileges;
EOF

  #logG "写入数据..."
  #mysql -uroot -P${dbPort} -p${dbPassword} <$asktaoSQLPATH >/dev/null 2>&1

  logG "开始分配资源..."
  sed -i '$a\* hard nofile 65535' /etc/security/limits.conf
  sed -i '$a\* soft nofile 65535' /etc/security/limits.conf
  sed -i '$a\ulimit -SHn 65535' /etc/profile
  source /etc/profile
  sed -i '$a\LimitNOFILE=65535' /usr/lib/systemd/system/mysqld.service
  sed -i '$a\LimitNPROC=65535' /usr/lib/systemd/system/mysqld.service
  systemctl daemon-reload

  logG "重启mysql..."
  sed -i "s/skip-grant-tables=1//g" /etc/my.cnf
  systemctl restart mysqld
  if [ $? -eq 0 ]; then
    logG "mysql重启成功"
  else
    logR "mysql重启失败"
    exit 0
  fi

  getFirewalldStatus
  if [ $? == 0 ]; then
    logG "防火墙关闭状态，跳过端口放行步骤..."
  else
    logG "检测并开放端口..."
    selectPortStatus "$dbPort" tcp

    if [ $? == 0 ]; then
      openOrCloseFirewallPort 1 "$dbPort" tcp
      logG "端口$dbPort已放行"
    else
      logG "端口开启中..."
    fi

  fi

  #echo "logRnable=0" >/var/log/asktao.cnf

  #rm -rf $asktaoSQLPATH

  deleteKXMySQLUser
  printInstallMysqlLog
}

printInstallMysqlLog() {
  logY "
===================请记录数据库资料===================
端口：$dbPort \n用户名：root \n密码：$dbPassword \n配置文件路径：$MYSQL_CONFIG_FILEPATH \n
===================请记录数据库资料===================
"
}

deleteKXMySQLUser() {
  mysql -uroot -P$dbPort -p$dbPassword -e "use mysql; DROP USER ''@'kuaixun-5kyuy'; DROP USER 'root'@'kuaixun-5kyuy';flush privileges;" > /etc/null 2>&1
}

#卸载mysql
unInstallMysql() {
  getMySQLStatus

  if [ $? == 1 ]; then
    logG "停止MySQL..."
    systemctl stop mysqld
  fi

  sed -i '/* hard nofile 65535/d' /etc/security/limits.conf
  sed -i '/* soft nofile 65535/d' /etc/security/limits.conf

  sed -i '/ulimit -SHn 65535/d' /etc/profile

  sed -i '/LimitNOFILE=65535/d' /usr/lib/systemd/system/mysqld.service
  sed -i '/LimitNPROC=65535/d' /usr/lib/systemd/system/mysqld.service

  logG "查找MySQL所有目录..."
  nL="$(rpm -qa | grep -i mysql)"

  for soft in ${nL[@]}; do
    rpm -ev $soft --nodeps
    logG "移除:${soft}"
  done

  nM="$(rpm -qa | grep -i mariadb)"

  for sm in ${nM[@]}; do
    rpm -ev $sm --nodeps
    logG "移除:${sm}"
  done

  fL=$(find / -name mysql)

  for fs in ${fL[@]}; do
    rm -rf $fs
    logG "移除:${fs}"
  done

  logG "移除配置文件!"
  rm -rf /etc/my.cnf
  rm -rf /var/log/mysqld.log
  logG "删除成功!"
}

#编辑mysql配置文件
editMySQLConfig() {
  execTips "是否打开配置文件/etc/my.cnf?"
  vi /etc/my.cnf
}

#重跑指定线路
reRunOnlyPort() {

  for index in $(seq 1 ${#killGameLinePort[@]}); do

    if [ $ENABLE_GM_LINE == 1 ] && [ $index == ${#killGameLinePort[@]} ]; then
      logY "$index) GM线 - ${killGameLinePort[index - 1]}"
    else
      logG "$index) $index线 - ${killGameLinePort[index - 1]}"
    fi

  done

  logG "\n"
  tips "请输入操作的线路编号(eg:1)："
  read inputIndex

  if [ -z "$inputIndex" ]; then
    logR "输入错误！"
    exit 0
  fi

  if [ $inputIndex -le 0 ]; then
    logR "输入错误！"
    exit 0
  fi

  if [ $inputIndex -gt ${#killGameLinePort[@]} ]; then
    logR "输入线路超出可用线路，请重新输入!"
    exit 0
  fi

  for index in $(seq 1 ${#killGameLinePort[@]}); do
    if [ $inputIndex == $index ]; then

      if [ $ENABLE_GM_LINE == 1 ] && [ $index == ${#killGameLinePort[@]} ]; then

        logG "关闭GM线..."
        processID=$( (netstat -nlp | grep :${killGameLinePort[index - 1]} | awk '{print $7}' | awk -F"/" '{ print $1 }'))
        if ! test -z "$processID"; then
          kill -9 $processID &
        fi

        sleep 1

        logG "..."

        logG "启动GM线..."

        cd $basePath/gm/ && echo i | ./rungm >$basePath/log/line_gm.log 2 >&1 &

        logG "线路正在后台加载，请开启脚本后使用'c5'查询线路实时状态..."

      else
        logG "关闭$index线..."
        processID=$( (netstat -nlp | grep :${killGameLinePort[index - 1]} | awk '{print $7}' | awk -F"/" '{ print $1 }'))
        if ! test -z "$processID"; then
          kill -9 $processID &
        fi

        sleep 1

        logG "..."

        logG "启动$index线..."

        cd $basePath/gs/ && echo i | ./$index >$basePath/log/line_$index.log 2 >&1 &

        logG "线路正在后台加载，请开启脚本后使用'c5'查询线路实时状态..."
      fi

    fi

  done

}

#重新跑线
reRunLine() {

  for port in ${killGameLinePort[@]}; do
    processID=$( (netstat -nlp | grep :$port | awk '{print $7}' | awk -F"/" '{ print $1 }'))
    if ! test -z "$processID"; then
      kill -9 $processID &
    fi
  done

  startGameLine
}
:
runCheckLine() {

  logG "开始为您后台不间断查询线路实时状态，启动成功的线路将输出，如需结束请按下Ctrl+C键！"

  startedLineArr=()

  while [ true ]; do
    for index in $(seq 1 ${#killGameLinePort[@]}); do
      processID=$( (netstat -nlp | grep :${killGameLinePort[index - 1]} | awk '{print $7}' | awk -F"/" '{ print $1 }'))
      if ! test -z "$processID"; then

        isAbout=0
        for linePort in ${startedLineArr[@]}; do
          if [ "$linePort" == "${killGameLinePort[index - 1]}" ]; then
            isAbout=1
            break
          else
            isAbout=0
          fi
        done

        if [ $isAbout == 0 ]; then
          startedLineArr[$index]="${killGameLinePort[index - 1]}"

          if [ $ENABLE_GM_LINE == 1 ] && [ $index == ${#killGameLinePort[@]} ]; then
            logG "GM线启动成功！"
          else
            logG "${index}线启动成功！"
          fi

        fi

      fi
    done

    if [ ${#startedLineArr[@]} == ${#killGameLinePort[@]} ]; then
      logG "线路已全部启动成功！后台任务自动结束！"
      exit 0
    fi
  done
}

#启动线路
startGameLine() {

  for index in $(seq 1 ${#killGameLinePort[@]}); do

    if [ $ENABLE_GM_LINE == 1 ] && [ $index == ${#killGameLinePort[@]} ]; then
      logG "后台启动GM线(${killGameLinePort[index - 1]})..."
      cd $basePath/gm/ && echo i | ./rungm >$basePath/log/line_gm.log 2 >&1 &
      logY "..."
      sleep 1
    else
      logY "后台启动$index线(${killGameLinePort[index - 1]})..."
      cd $basePath/gs/ && echo i | ./$index >$basePath/log/line_$index.log 2 >&1 &
      #cd /asktao/gm/ && echo i | ./gm >/asktao/log/line_gm.log 2 >&1 &
      logY "..."
      sleep 1
      logY "..."
      sleep 1
      logY "..."
      sleep 1
    fi
  done

  logG "线路正在后台启动，随时可使用脚本键入'C5'查询线路实时状态..."

  execTips "是否开启自动查线？"

  runCheckLine

}

#启动游戏服务器 内部调用
startGameService() {
  logG "服务超时时间为60秒，超时后请至日志目录查看日志。启动AAA服务需要在关闭游戏服务后等待大约20秒，否则无法启动！"
  sleep 1
  logG "加载驱动..."

  isEnableLog

  logRnable=$?

  if [ $logRnable == 0 ]; then
    #关闭状态
    cd /asktao/1/ && echo i | ./1 >/asktao/log/drive.log 2 >&1 &
  else
    cd /asktao/1/ && echo i | ./1 &
  fi

  sleep 1
  logG "驱动已加载，开始启动游戏服务器..."
  sleep 1

  for index in $(seq 1 ${#killPorts[@]}); do

    if test $index -eq 1; then
      logG "启动AAA服务..."

      if [ $logRnable == 0 ]; then
        #关闭状态
        cd $basePath/aaa/ && echo i | ./runaaa >$basePath/log/aaa.log 2 >&1 &
      else
        cd $basePath/aaa/ && echo i | ./runaaa &
      fi

    fi

    if test $index -eq 2; then
      logG "启动DBA服务..."

      if [ $logRnable == 0 ]; then
        #关闭状态
        cd $basePath/dba/ && echo i | ./rundba >$basePath/log/dba.log 2 >&1 &
      else
        cd $basePath/dba/ && echo i | ./rundba &
      fi

    fi

    if test $index -eq 3; then
      logG "启动CCS服务..."

      if [ $logRnable == 0 ]; then
        #关闭状态
        cd $basePath/ccs/ && echo i | ./runccs >$basePath/log/ccs.log 2 >&1 &
      else
        cd $basePath/ccs/ && echo i | ./runccs &
      fi

    fi

    if test $index -eq 4; then
      logG "启动CSA服务..."

      if [ $logRnable == 0 ]; then
        #关闭状态
        cd $basePath/csa/ && echo i | ./runcsa >$basePath/log/csa.log 2 >&1 &
      else
        cd $basePath/csa/ && echo i | ./runcsa &
      fi

    fi

    processID=
    for loop in {1..60}; do
      processID=$( (netstat -nlp | grep :${killPorts[$index - 1]} | awk '{print $7}' | awk -F"/" '{ print $1 }'))
      if test -z "$processID"; then
        #端口没起来。继续等待，改为去扫对应的日志文件，如果发现

        if test $index -eq 1; then
          #AAA还没起来
          if [ $logRnable == 0 ]; then
            #关闭状态
            aaaStatus=$(sed -n "/AAA failed to listen on port: ${killPorts[$index - 1]}/p" $basePath/log/aaa.log)

            if [ -n "$aaaStatus" ]; then
              logR "AAA启动失败，端口占用!正在后台杀死中，请等待大约20秒左右再试。Tips小技巧：加入游戏开机自启动(C6)后重启系统(A8)可能只需要10秒就OK啦~并且开机后自动重跑服务器和线路~"
              echo "" >$basePath/log/aaa.log
              exit 0
            fi
          fi

        fi

        logG "..."
        sleep 1
      else
        break
      fi
    done

    #循环结束后如果对应的端口没起来，表示启动失败，杀死全部端口

    if test -z "$processID"; then
      if test $index -eq 1; then

        if [ $logRnable == 0 ]; then
          #关闭状态
          logR "AAA服务启动失败!对应端口${killPorts[$index - 1]}"
        else
          logR "AAA服务启动失败!对应端口${killPorts[$index - 1]},日志文件路径：$basePath/log/aaa.log，请打开日志文件并查看日志最后位置输出的错误内容！"
        fi

        #因为AAA为第一个端口，启动失败时无需杀死端口
      fi

      if test $index -eq 2; then

        if [ $logRnable == 0 ]; then
          #关闭状态
          logR "DBA服务启动失败!对应端口${killPorts[$index - 1]}"
        else
          logR "DBA服务启动失败!对应端口${killPorts[$index - 1]},日志：$basePath/log/dba.log，请打开日志文件并查看日志最后位置输出的错误内容！"
        fi

        echo "${killPorts[0]}" | fun6

      fi

      if test $index -eq 3; then

        if [ $logRnable == 0 ]; then
          #关闭状态
          logR "CCS服务启动失败!对应端口${killPorts[$index - 1]}"
        else
          logR "CCS服务启动失败!对应端口${killPorts[$index - 1]},日志：$basePath/log/ccs.log，请打开日志文件并查看日志最后位置输出的错误内容！"
        fi
        echo "${killPorts[0]}" | fun6
        echo "${killPorts[1]}" | fun6

      fi

      if test $index -eq 4; then
        if [ $logRnable == 0 ]; then
          #关闭状态
          logR "CSA服务启动失败!对应端口${killPorts[$index - 1]}"
        else
          logR "CSA服务启动失败!对应端口${killPorts[$index - 1]},日志：$basePath/log/csa.log，请打开日志文件并查看日志最后位置输出的错误内容！"
        fi

        echo "${killPorts[0]}" | fun6
        echo "${killPorts[1]}" | fun6
        echo "${killPorts[2]}" | fun6

      fi

      exit 0
    fi

    #如果没有进入上个分支，代表端口不是空的启动成功了
    if test $index -eq 1; then
      logG "AAA服务(${killPorts[$index - 1]})启动成功！"
    fi

    if test $index -eq 2; then
      logG "DBA服务(${killPorts[$index - 1]})启动成功！"
    fi

    if test $index -eq 3; then
      logG "CCS服务(${killPorts[$index - 1]})启动成功！"
    fi

    if test $index -eq 4; then
      logG "CSA服务(${killPorts[$index - 1]})启动成功！"
    fi

    sleep 1
  done

  startGameLine
}

killGameServer() {

  processID=
  for port in ${killPorts[@]}; do
    processID=$( (netstat -nlp | grep :$port | awk '{print $7}' | awk -F"/" '{ print $1 }'))
    if ! test -z "$processID"; then
      kill -9 $processID &
    fi
  done

  logG "游戏服务已关闭！"

  for port in ${killGameLinePort[@]}; do
    processID=$( (netstat -nlp | grep :$port | awk '{print $7}' | awk -F"/" '{ print $1 }'))
    if ! test -z "$processID"; then
      kill -9 $processID &
    fi
  done

  logG "所有线路已关闭！正在后台关闭游戏服务器，需要等待20秒左右即可再次启动游戏服务器！如果有异常日志出现时敲回车即可！"

}

#启动问道服务器
startAskTaoServer() {
  if [ ! -f $basePath/$zipFileNmae ]; then
    startGameService
  else
    #开放端口
    for port in ${killPorts[@]}; do
      selectPortStatus $port tcp

      if [ $? == 0 ]; then
        openOrCloseFirewallPort 1 "$port" tcp
      fi

    done

    for port in ${killGameLinePort[@]}; do

      selectPortStatus $port tcp

      if [ $? == 0 ]; then
        openOrCloseFirewallPort 1 "$port" tcp
      fi
    done

    logG "检测压缩软件"
    checkSoft unzip

    if [ $? == 1 ]; then
      unzip -o $basePath/$zipFileNmae -d $basePath/
      chmod -R 777 $basePath/

      checkSoft "xulrunner.i686"

      if [ $? == 1 ]; then

        rm -rf $basePath/$zipFileNmae
        #创建日志文件夹

        if [ ! -d "$basePath/log" ]; then
          mkdir $basePath/log
        fi

        startGameService
      fi
    fi

  fi
}

#服务器状态
asktaoStatus() {
  #服务器状态查询
  for index in $(seq 1 ${#killPorts[@]}); do
    port=${killPorts[index - 1]}
    processID=$( (netstat -nlp | grep :$port | awk '{print $7}' | awk -F"/" '{ print $1 }'))
    if test -z "$processID"; then
      case $index in
        1)
          logR "AAA服务异常($port),玩家可能卡登录验证！请查阅日志$basePath/log/aaa.log"
          ;;
        2)
          logR "DBA服务异常($port),请查阅日志$basePath/log/dba.log"
          ;;
        3)
          logR "CCS服务异常($port),请查阅日志$basePath/log/ccs.log"
          ;;
        4)
          logR "CSA服务异常($port),请查阅日志$basePath/log/csa.log"
          ;;
      esac
    else
      case $index in
        1)
          logG "AAA服务正常($port)"
          ;;
        2)
          logG "DBA服务正常($port)"
          ;;
        3)
          logG "CCS服务正常($port)"
          ;;
        4)
          logG "CSA服务正常($port)"
          ;;
      esac
    fi

  done

  #线路状态查询
  for index in $(seq 1 ${#killGameLinePort[@]}); do
    processID=$( (netstat -nlp | grep :${killGameLinePort[index - 1]} | awk '{print $7}' | awk -F"/" '{ print $1 }'))
    if test -z "$processID"; then

      if [ $ENABLE_GM_LINE == 1 ] && [ $index == ${#killGameLinePort[@]} ]; then
        logR "${killGameLinePort[index - 1]}端口异常,GM线还未成功启动！"
      else
        logR "${killGameLinePort[index - 1]}端口异常,${index}线玩家可能无法正常登录游戏！如果刚跑完线无需关心，稍等片刻即可恢复启动完成！"
      fi

    else

      if [ $ENABLE_GM_LINE == 1 ] && [ $index == ${#killGameLinePort[@]} ]; then
        logG "GM线正常(${killGameLinePort[index - 1]})，所有玩家可正常进出游戏！"
      else
        logG "${index}线正常(${killGameLinePort[index - 1]})，所有玩家可正常进出游戏！"
      fi

    fi

  done

}

#--------------------------------------------------------------------------------系统信息收集
logGsys() {
 echo -e "\033[1;32m $1 \033[0m"    #绿色
}

systemInfo() {
  productName=$(dmidecode | grep Product | sed 's/^[ \t]*//g')
  logGsys "[服务器型号]" && echo "$productName"

  logGsys "[系统版本]" && echo -e "$(cat /etc/redhat-release)"

  coreVersion=$(uname -r)
  logGsys "[内核版本]" && echo -e "$coreVersion"
  logicalNum=$(cat /proc/cpuinfo | grep "processor" | wc -l)
  pysicalNum=$(cat /proc/cpuinfo | grep "physical id" | sort | uniq | wc -l)
  pysicalCoreNum=$(cat /proc/cpuinfo | grep "cpu cores" | uniq | awk '{print $4}')
  otherInfo=$(cat /proc/cpuinfo | grep name | cut -f2 -d: | uniq -c | awk '{print $2,$3,$7}')
  firstCache=$(cat /sys/devices/system/cpu/cpu0/cache/index0/size)

  let coreTotal=pysicalNum*pysicalCoreNum
  logGsys "[cpu信息]"
  echo -e "$(getconf LONG_BIT)位，物理$coreTotal核($pysicalNum X $pysicalCoreNum)，逻辑$logicalNum核，$otherInfo，一级缓存$firstCache"

  memInfo=$(free -h)
  logGsys "[内存信息]" && echo -e "$memInfo"

  diskInfo=$(lsblk)
  logGsys "[硬盘信息]" && echo -e "$diskInfo"
  
  logGsys "[网卡信息]"
  for i in $(ifconfig | egrep -E "eth[0-9]" | grep -v Interrupt | awk '{print $1}'); do
    echo -e  "$i $(ifconfig | grep inet | grep -v inet6 | grep -v 127)"
  done

  logGsys "[服务器运行时常长]"
  cat /proc/uptime | awk -F. '{run_days=$1 / 86400;run_hour=($1 % 86400)/3600;run_minute=($1 % 3600)/60;run_second=$1 % 60;printf("系统已运行：%d天%d时%d分%d秒",run_days,run_hour,run_minute,run_second)}'
  logGsys ""
}

resetBockName() {
  execTips "请关闭游戏服务后再试，防止出错，是否继续？"

  logG "查询原区组信息..."
  #查询原区组名称
  oldBockNamesStr="$(mysql -uroot -P${dbPort} -p${dbPassword} --default-character-set=latin1 -e "select dist from dl_adb_all.server")" >/dev/null 2>&1

  array=(${oldBockNamesStr//"\n"/ })

  oldBlockName=${array[1]}

  if [ -z $oldBlockName ]; then
    logR "原区组信息查询失败，请重试！"
    exit 0
  fi

  echo -n "请输入新的区组名称："
  read newBlockName

  if [ -z $newBlockName ]; then
    logR "新区组名称不能为空，请重试！"
    exit 0
  fi

  execTips "是否将原区组'${oldBlockName}'修改为：'$newBlockName'?"

  getMySQLStatus
  if [ $? -eq 1 ]; then
    #导出全部数据库到sql
    logG "导出sql到临时文件..."
    mysqldump --opt --default-character-set=latin1 --databases dl_adb_all dl_ddb_1 dl_dmdb_1 dl_ldb_1 dl_ldb_all dl_mdb_1 dl_mdb_all dl_tdb_1 wdsf >/all_db.sql
    if [ $? -ne 0 ]; then
      logR "数据库导出失败!"
      exit 0
    fi

    logG "导出完成，开始修改..."

    sed -i "s/${oldBlockName}/$newBlockName/g" /all_db.sql

    logG "修改成功，正在导入MySQL..."

    mysql </all_db.sql >/dev/null

    if [ $? -ne 0 ]; then
      logR "导入失败，请重试！"
      exit 0
    fi

    logG "清理临时文件..."

    rm -rf /all_db.sql

    logG "导入成功，请重启游戏服务！"
  else
    logR "数据库未启动，请启动后再试！"
  fi
}

addAutoStartContent() {
  echo "#!/bin/bash +x
  echo '将在5秒后启动游戏服务器...'
  echo '...'
  sleep 1
  echo '...'
  sleep 1
  echo '...'
  sleep 1
  echo '...'
  sleep 1
  echo '...'
  echo '11111'>>/aaa
 echo c1 | sh /usr/bin/wd
" >/usr/bin/autoStartAsktao

  echo 'sh /usr/bin/autoStartAsktao' >>/etc/rc.local

  chmod 0777 /usr/bin/autoStartAsktao
  logG "添加成功，将在系统重启后自动为您启动游戏服务器！"
}

addGameStartedBySystemRestart() {

  isAdd="$(grep "sh /usr/bin/autoStartAsktao" /etc/rc.local)"

  if test -z "$isAdd"; then
    execTips "是否加入开机自启动？"
    addAutoStartContent
  else
    execTips "是否取消开机启动？"
    a="sh /usr/bin/autoStartAsktao"
    sed -ie '/a/d' /etc/rc.local
  fi

}

#输出提示语
printStartLog() {

  echo -e "
——————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————
\033[1;31m                        欢迎使用架设Linux工具箱 系统版本：$systemVersionName                                                  \033[0m
——————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————
      系统相关                                                                                                                
—————————————————————
\033[1;31m
             A1) Minimal系统初始化        A2) 开启关闭防火墙    A3) 查看防火墙开放端口列表   A4) 开放/关闭指定端口
             A5) 查询端口是否在用         A6) 杀死指定端口      A7) 设置yum用阿里源          A8) 设置yum用网易源
             A9) 查询服务器配置                                                                                                         \033[0m
——————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————
      MySQL相关                                                                                                              
—————————————————————
\033[1;31m
             B1) 安装MySQL5.7             B2) 配置MYSQL5.7      B3) 卸载MySQL5.7             B4) 实时链接数查看
             B5) 查询MySQL状态            B6) 启动MySQL服务     B7) 停止MySQL服务            B8) 重启MySQL服务
             B9) 修复老版架设繁忙问题    B10) 修改区组名称      B11) 修改配置文件                                                       \033[0m
——————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————
      问道相关                                                                                                               
—————————————————————
\033[1;31m
             C1) 启动游戏服务             C2) 关闭游戏服务      C3) 重跑所有线路             C4) 重启指定线路
             C5) 查询运行状态             C6) 游戏开机自启动    C7) 实时线路状态             C8) 日志开启关闭                           \033[0m
——————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————————
"

}

#脚本执行入口
shellOnStart() {

  printStartLog

  tips "请输入有效的操作编号(A1~C5):"
  read doType

  case $doType in

    A1 | a1)
      #初始化Minimal系统
      execTips "是否初始化MinimalMinimal系统?"
      changMinimal
      ;;

    A2 | a2)
      #开启或关闭防火墙
      enableOrDisEnableFirewalld
      ;;

    A3 | a3)
      #查看防火墙开放端口列表
      getOpenedFirewallPorts
      ;;

    A4 | a4)
      #开放/关闭指定端口
      fun4
      ;;

    A5 | a5)
      #查询端口是否在用
      fun5
      ;;

    A6 | a6)
      #杀死指定端口
      fun6
      ;;

    A7 | a7)
      #切换yum源为阿里源
      execTips "是否切换yum使用阿里源?"
      switchYumRepoToAliYun
      ;;

    A8 | a8)
      #切换yum源为网易源
      execTips "是否切换yum使用网易源"
      switchYumRepoToWangyi
      ;;
    A9 | a9)
      #查询系统配置
      systemInfo
      ;;

    B1 | b1)
      #安装MySQL5.7
      execTips "是否开始安装MySQL 5.7?"
      installMySQL5.7
      ;;

    B2 | b2)
      #配置MySQL5.7
      execTips "是否开始配置MySQL 5.7?"
      setMySQL5.7
      ;;

    B3 | b3)
      #删除MySQL5.7
      execTips "是否开始删除mysql 5.7?"
      unInstallMysql
      ;;

    B4 | b4)
      mysql -uroot -pbetavip -e "show status like 'Threads%'; " --connect-expired-password 2>/dev/null
      ;;
    B5 | b5)
      #查询MYSQL状态
      getMySQLStatus
      if [ $? -eq 1 ]; then
        logG "数据库运行中!"
      else
        logR "数据库未运行！"
      fi
      ;;
    B6 | b6)
      #启动MySQL
      systemctl start mysqld
      if [ $? -eq 0 ]; then
        logG "数据库启动成功"
      else
        logR "数据库启动失败"
      fi
      ;;
    B7 | b7)
      systemctl stop mysqld
      if [ $? -eq 0 ]; then
        logG "数据库关闭成功"
      else
        logR "数据库关闭失败！"
      fi
      ;;
    B8 | b8)
      systemctl restart mysqld
      if [ $? -eq 0 ]; then
        logG "数据库重启成功"
      else
        logR "数据库重启失败！"
      fi
      ;;

    B9 | b9)
      #修复操作频繁异常
      execTips "是否修复服务器繁忙的错误，如果没有该错误请勿继续，否则可能出现异常，是否继续？"
      getMySQLStatus
      if [ $? -eq 1 ]; then
        logG "正在停止MySQL..."
        systemctl stop mysqld
        logG "停止成功，开始修复..."
        sed -i '/sql_mode=/c sql_mode=NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION' $MYSQL_CONFIG_FILEPATH
        sed -i '/sql-mode=/c sql-mode=NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION' $MYSQL_CONFIG_FILEPATH
        logG "修复成功，正在启动MySQL..."
        systemctl start mysqld
        logG "MySQL启动成功！"
      else
        logG '正在启动MySQL...'
        systemctl start mysqld
        logG "MySQL启动成功！"
      fi
      ;;

    B10 | b10)
      #修改区组名称
      resetBockName
      ;;

    B11 | b11)
      #编辑配置文件
      editMySQLConfig
      ;;

    C1 | c1)
      #启动游戏服务器
      startAskTaoServer
      ;;

    C2 | c2)
      #停止游戏服务器
      execTips "是否停止游戏服务器?"
      killGameServer
      ;;

    C3 | c3)
      #重跑线路
      execTips "是否重跑所有线路?"
      reRunLine
      ;;

    C4 | c4)
      #重跑指定线路
      reRunOnlyPort
      ;;

    C5 | c5)
      #查询服务器状态
      asktaoStatus
      ;;

    C6 | c6)
      #游戏服务自启动
      addGameStartedBySystemRestart
      ;;

    C7 | c7)
      #线路实时状态
      runCheckLine
      ;;

    C8 | c8)

      #开启关闭日志

      isEnableLog

      if [ $? == 0 ]; then
        execTips "是否开启日志打印？"
        echo "logRnable=1" >/var/log/asktao.cnf
      else
        execTips "是否关闭日志打印？"
        echo "logRnable=0" >/var/log/asktao.cnf
      fi

      ;;

    *)
      logR "操作编号输入错误！"
      ;;
  esac
}

isEnableLog() {
  status=$(sed -n '/logRnable=1/p' /var/log/asktao.cnf)
  if [ -z $status ]; then
    return 0
  else
    return 1
  fi
}

#系统信息存储的文件目录
readonly systemVersionName=$(cat /etc/redhat-release)
readonlu systemVersionCode=`rpm -q centos-release | cut -d- -f3`

checkVersion() {
  if [ $systemVersionCode -ne 7 ]; then
    logR "Sorry~ 本脚本仅支持CentOS7.x的系统使用"
    exit 0
  fi
}


readonly basePath="/asktao"

readonly zipFileNmae="asktaoServer1.60.zip"

readonly killPorts=(8101 8120 8110 6101)

readonly killGameLinePort=(8160 8161 8162 )

checkVersion

clear

shellOnStart
