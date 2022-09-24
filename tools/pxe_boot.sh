#!/bin/bash

if [ $# -ne 1 ];then
   echo "请输入IPMI IP"
   echo ""
   echo "Example: $0 {IPMI IP}"
   exit
fi

ip=$1
IPMI_USER=ipmiadmin
IPMI_PASS=qwe123asd


ipmitool -I lanplus -H $ip -U $IPMI_USER -P $IPMI_PASS chassis bootdev pxe
ipmitool -I lanplus -H $ip -U ${IPMI_USER} -P ${IPMI_PASS} chassis power off

sleep 2
ipmitool -I lanplus -H $ip -U ${IPMI_USER} -P ${IPMI_PASS} chassis power on



