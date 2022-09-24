#!/bin/bash

NFS_SERVER=172.16.0.2
NFS_PATH='/nfs/'
CONFIG_SAVE_PATH='/mnt/nfs/'"`date +%Y-%m-%d`"
exitStatus=0

function log(){

	logger -t 'init' $1
}
log 'Start run init.sh script'


function installPackage(){
	apt-get -y install $1 >> /tmp/insta.log
}

function mountNFS(){

	if [ ! -d  /mnt/nfs ];then
		mkdir /mnt/nfs
	fi

	mountpoint /mnt/nfs > /dev/null
	if [ $? -ne 0 ];then

		mount -t nfs $NFS_SERVER:$NFS_PATH /mnt/nfs
		if [ $? -ne 0 ];then
			echo "mount nfs failed."
			exit 1
		fi
	fi

	if [ ! -d $CONFIG_SAVE_PATH ];then

		mkdir $CONFIG_SAVE_PATH -p
	fi
}

function umountNFS(){
	mountpoint /mnt/nfs > /dev/null
	if [ $? -eq 0 ];then
		umount /mnt/nfs
	fi
}



function setHostname(){

	hostname=`ipmitool lan print  |grep 'IP Address' |grep -v 'Source' |awk -F": " '{print $2}' | sed 's/\./-/g'`
	if [ $? -ne 0 ];then
		log "run ipmitool failed"
	fi
	hostnamectl set-hostname $hostname
	if [ $? -ne 0 ];then
		log "set hostname failed"
	fi

	 systemctl restart lldpd
}

function checkSSDStatus(){

	which want_to_find > /dev/null 2>&1
	if [ $? -ne 0 ]; then
		installPackage smartmontools
	fi

	for disk in `lsblk -d -o name |egrep -v 'NAME|loop|sr'`
	do
		ssdStatus=`smartctl -l devstat /dev/${disk} |grep Percent  |awk '{print $4}'`

		if [ "$ssdStatus" -gt 5 ];then
			log "[ $disk ] hdd disk health=${ssdStatus},check failed."

			echo "硬盘[ $disk ] 寿命=${ssdStatus}%,检查异常：使用寿命大于5%"
			exitStatus=1
		else
			log "[ $disk ] hdd disk health=${ssdStatus}%"
		fi
	done


}

function getlshw(){



	productName=`dmidecode -t system |grep 'Product Name' |awk -F': ' '{print $2}'`
	sn=`dmidecode -t system |grep 'Serial Number' |awk -F': ' '{print $2}'`
	hostname=`hostname`

	lshw -json >"${CONFIG_SAVE_PATH}/${productName}.${sn}.${hostname}.json"
}

function main(){


	#mount nfs
	mountNFS

	setHostname
	checkSSDStatus
	getlshw

	#umount
	umountNFS

    if [ $exitStatus -eq 0 ];then
    	 log "init completed."
    else
    	log "初始化异常，请检查输出日志."
    fi
}
main
