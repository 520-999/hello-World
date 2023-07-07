#!/bin/bash
# 创建随机密码

clear

symbol=abcdefghijklmn@.+opqrstuvwxyzABCDEFGHIJKLMN@.+OPQRSTUVWXYZ0123456789

for y in {1..16}
do
  number3=""
  for i in {1..16}
    do
      number1=$[RANDOM%68]
      number2=${symbol:number1:1}
      number3=${number3}${number2}
    done
    echo $number3
done

echo ""
