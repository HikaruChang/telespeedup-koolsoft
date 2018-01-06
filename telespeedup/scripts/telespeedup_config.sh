#!/bin/sh
ACTION=$1
scriptfilepath=$(cd "$(dirname "$0")"; pwd)/$(basename $0)
scriptpath=$(cd "$(dirname "$0")"; pwd)
scriptname=$(basename $0)
logfile="/tmp/upload/telespeedup_log.txt"

alias echo_date='echo $(date +%Y年%m月%d日\ %X)'
export KSROOT=/koolshare
source $KSROOT/scripts/base.sh
eval `dbus export telespeedup_`

[ -z $telespeedup_enable ] && telespeedup_enable=0
telespeedup_path="$KSROOT/bin/telespeedup"
if [ "$telespeedup_enable" != "0" ] ; then
	[ -z "$telespeedup_Info" ] && telespeedup_Info=1
	Info="$telespeedup_Info"
	[ -z "$Info" ] && Info=1
	STATUS="N"
	SN=""
	check_Qos="$(echo $telespeedup_check_Qos | base64_decode)"
	Start_Qos="$(echo $telespeedup_Start_Qos | base64_decode)"
	Heart_Qos="$(echo $telespeedup_Heart_Qos | base64_decode)"
fi



telespeedup_restart () {

telespeedup_renum=`dbus get telespeedup_renum`
relock="/var/lock/telespeedup_restart.lock"
if [ "$1" = "o" ] ; then
	dbus set telespeedup_renum="0"
	[ -f $relock ] && rm -f $relock
	return 0
fi
if [ "$1" = "x" ] ; then
	if [ -f $relock ] ; then
		echo_date "【家庭云提速】" "多次尝试启动失败，等待【"`cat $relock`"分钟】后自动尝试重新启动" >> $logfile
		exit 0
	fi
	telespeedup_renum=${telespeedup_renum:-"0"}
	telespeedup_renum=`expr $telespeedup_renum + 1`
	dbus set telespeedup_renum="$telespeedup_renum"
	if [ "$telespeedup_renum" -gt "2" ] ; then
		I=19
		echo $I > $relock
		echo_date "【家庭云提速】" "多次尝试启动失败，等待【"`cat $relock`"分钟】后自动尝试重新启动" >> $logfile
		while [ $I -gt 0 ]; do
			I=$(($I - 1))
			echo $I > $relock
			sleep 60
			[ "$(dbus get telespeedup_renum)" = "0" ] && exit 0
			[ $I -lt 0 ] && break
		done
		dbus set telespeedup_renum="0"
	fi
	[ -f $relock ] && rm -f $relock
fi
dbus set telespeedup_status=0
eval "$scriptfilepath &"
exit 0
}

telespeedup_get_status () {

A_restart=`dbus get telespeedup_status`
B_restart="$telespeedup_enable$telespeedup_Info$check_Qos$Start_Qos$Heart_Qos"
B_restart=`echo -n "$B_restart" | md5sum | sed s/[[:space:]]//g | sed s/-//g`
if [ "$A_restart" != "$B_restart" ] ; then
	dbus set telespeedup_status=$B_restart
	needed_restart=1
else
	needed_restart=0
fi
}

telespeedup_check () {

telespeedup_get_status
if [ "$telespeedup_enable" != "1" ] && [ "$needed_restart" = "1" ] ; then
	[ ! -z "$(ps -w | grep "$telespeedup_path" | grep -v grep )" ] && echo_date "【家庭云提速】" "停止 telespeedup" >> $logfile && telespeedup_close
	{ eval $(ps -w | grep "$scriptname" | grep -v grep | awk '{print "kill "$1";";}'); exit 0; }
fi
if [ "$telespeedup_enable" = "1" ] ; then
	if [ "$needed_restart" = "1" ] ; then
		telespeedup_close
		telespeedup_start
	else
		[ -z "$(ps -w | grep "$telespeedup_path" | grep -v grep )" ] && telespeedup_restart
	fi
fi
}

telespeedup_keep () {
echo_date "【家庭云提速】" "守护进程启动" >> $logfile
sleep 60
telespeedup_enable=`dbus get telespeedup_enable` #telespeedup_enable
i=1
while [ "$telespeedup_enable" = "1" ]; do
	NUM=`ps -w | grep "$telespeedup_path" | grep -v grep |wc -l`
	if [ "$NUM" -lt "1" ] || [ ! -s "$telespeedup_path" ] || [ "$i" -ge 369 ] ; then
		echo_date "【家庭云提速】" "重新启动$NUM" >> $logfile
		telespeedup_restart
	fi
sleep 69
i=$((i+1))
telespeedup_enable=`dbus get telespeedup_enable` #telespeedup_enable
done
}

telespeedup_close () {
killall telespeedup
killall -9 telespeedup
rm -rf $logfile
sed -i '/telespeedup/d' /etc/crontabs/root
eval $(ps -w | grep "telespeedup start_path" | grep -v grep | awk '{print "kill "$1";";}')
eval $(ps -w | grep "telespeedup_config.sh keep" | grep -v grep | awk '{print "kill "$1";";}')
eval $(ps -w | grep "$scriptname keep" | grep -v grep | awk '{print "kill "$1";";}')
}

telespeedup_start () {

[ -z "$check_Qos" ] && echo_date "【家庭云提速】" "错误！！！【Check代码】未填写" >> $logfile && sleep 10 && exit
[ -z "$Start_Qos" ] && echo_date "【家庭云提速】" "错误！！！【Start代码】未填写" >> $logfile && sleep 10 && exit

curltest=`which curl`
if [ -z "$curltest" ] || [ ! -s "`which curl`" ] ; then
	echo_date "【家庭云提速】" "找不到 curl ，正在尝试安装" >> $logfile
	opkg update && opkg install curl
	echo_date "【家庭云提速】" "10 秒后自动尝试重新启动" >> $logfile && sleep 10 && telespeedup_restart x
fi

telespeedup_vv=2018-01-06
telespeedup_v=$(grep 'telespeedup_vv=' /koolshare/scripts/telespeedup_config.sh | grep -v 'telespeedup_v=' | awk -F '=' '{print $2;}')
echo_date "【家庭云提速】" "运行 $telespeedup_path" >> $logfile
ln -sf /koolshare/scripts/telespeedup_config.sh /koolshare/bin/telespeedup
chmod 777 /koolshare/bin/telespeedup
eval "$telespeedup_path" start_path &
sleep 2
[ ! -z "$(ps -w | grep "/koolshare/bin/telespeedup" | grep -v grep )" ] && echo_date "【家庭云提速】" "启动成功 $telespeedup_v " >> $logfile && telespeedup_restart o
[ -z "$(ps -w | grep "/koolshare/bin/telespeedup" | grep -v grep )" ] && echo_date "【家庭云提速】" "启动失败, 注意检查端口是否有冲突,程序是否下载完整,10 秒后自动尝试重新启动" >> $logfile && sleep 10 && telespeedup_restart x

telespeedup_get_status
eval "$scriptfilepath keep &"

sed -i '/telespeedup/d' /etc/crontabs/root
echo "*/3 * * * * rm -rf $logfile" >> /etc/crontabs/root
}

telespeedup_start_path () {

# 主程序循环
re_STAT="$(eval "$check_Qos" | grep qosListResponse)"

# 获取提速包数量
qos_Info="$(echo "$re_STAT" | awk -F"/qosInfo" '{print NF-1}')"
[ -z "$qos_Info" ] && qos_Info=0
if [[ "$qos_Info"x == "1"x ]]; then
Info=1
fi
if [[ "$qos_Info" -ge 1 ]]; then
# 提速包1
qos_Info_1="$(echo "$re_STAT" | awk -F '/qosInfo' '{print $1}')"
qos_Info_x="$qos_Info_1"
get_info
echo_date "【家庭云提速】" "包【1】 提速状态【$re_STATUS】 提速包名称【$prod_Name】 提速包代码【$prod_Code】 提速包时间【$used_Minutes/$total_Minutes】" >> $logfile
fi
if [[ "$qos_Info" -ge 2 ]]; then
# 提速包2
qos_Info_2="$(echo "$re_STAT" | awk -F '/qosInfo' '{print $2}')"
qos_Info_x="$qos_Info_2"
get_info
echo_date "【家庭云提速】" "包【2】 提速状态【$re_STATUS】 提速包名称【$prod_Name】 提速包代码【$prod_Code】 提速包时间【$used_Minutes/$total_Minutes】" >> $logfile
fi
if [[ "$qos_Info" -ge 3 ]]; then
# 提速包3
qos_Info_3="$(echo "$re_STAT" | awk -F '/qosInfo' '{print $3}')"
qos_Info_x="$qos_Info_3"
get_info
echo_date "【家庭云提速】" "包【3】 提速状态【$re_STATUS】 提速包名称【$prod_Name】 提速包代码【$prod_Code】 提速包时间【$used_Minutes/$total_Minutes】" >> $logfile
fi
if [[ "$qos_Info" -ge 4 ]]; then
# 提速包4
qos_Info_4="$(echo "$re_STAT" | awk -F '/qosInfo' '{print $4}')"
qos_Info_x="$qos_Info_4"
get_info
echo_date "【家庭云提速】" "包【4】 提速状态【$re_STATUS】 提速包名称【$prod_Name】 提速包代码【$prod_Code】 提速包时间【$used_Minutes/$total_Minutes】" >> $logfile
fi
if [[ "$qos_Info" -ge 5 ]]; then
# 提速包5
qos_Info_5="$(echo "$re_STAT" | awk -F '/qosInfo' '{print $5}')"
qos_Info_x="$qos_Info_5"
get_info
echo_date "【家庭云提速】" "包【5】 提速状态【$re_STATUS】 提速包名称【$prod_Name】 提速包代码【$prod_Code】 提速包时间【$used_Minutes/$total_Minutes】" >> $logfile
fi


QOS_Status
echo_date "【家庭云提速】" "包【$Info】 提速状态【$re_STATUS】 重置时间【$remaining_Time】 提速包名称【$prod_Name】 提速包代码【$prod_Code】 提速包时间【$used_Minutes/$total_Minutes】" >> $logfile
#QOS_Start
[ -z "$SN" ] && SN=0
telespeedup_enable=`dbus get telespeedup_enable`
[ -z $telespeedup_enable ] && telespeedup_enable=0 && dbus set telespeedup_enable=0
while [[ "$telespeedup_enable" != 0 ]]
do
	if [[ "$STATUS"x != "Y"x ]]; then
		echo_date "【家庭云提速】" "状态 $STATUS , 来一发加速吧！" >> $logfile
		QOS_Start
		if [[ -z "$SN" ]]; then
			echo_date "【家庭云提速】" "启动错误！" >> $logfile
		else
			echo_date "【家庭云提速】" "启动家庭云提速, SN: $SN" >> $logfile
			[ ! -z "$Heart_Qos" ] && QOS_Heart
			sleep 57
			QOS_Status
			echo_date "【家庭云提速】" "包【$Info】 提速状态【$re_STATUS】 重置时间【$remaining_Time】 提速包名称【$prod_Name】 提速包代码【$prod_Code】 提速包时间【$used_Minutes/$total_Minutes】" >> $logfile
			if [[ "$STATUS"x == "Y"x ]]; then
				[ ! -z "$Heart_Qos" ] && QOS_Heart
				sleep 57
			fi
		fi
	fi
	QOS_Status
	#echo_date "【家庭云提速】" "包【$Info】 提速状态【$re_STATUS】 重置时间【$remaining_Time】 提速包名称【$prod_Name】 提速包代码【$prod_Code】 提速包时间【$used_Minutes/$total_Minutes】" >> $logfile
	if [[ "$STATUS"x == "Y"x ]]; then
		[ ! -z "$Heart_Qos" ] && QOS_Heart
		sleep 57
	fi
	telespeedup_enable=`dbus get telespeedup_enable`
	[ -z $telespeedup_enable ] && telespeedup_enable=0 && dbus set telespeedup_enable=0
done

}

get_info()
{
# 提速包名称
prod_Name="$(echo "$qos_Info_x" | awk -F"\<prodName\>|\<\/prodName\>" '{if($2!="") print $2}')"
# 提速包代码
prod_Code="$(echo "$qos_Info_x" | awk -F"\<prodCode\>|\<\/prodCode\>" '{if($2!="") print $2}')"
# 提速包总时间（分钟）
total_Minutes="$(echo "$qos_Info_x" | awk -F"\<totalMinutes\>|\<\/totalMinutes\>" '{if($2!="") print $2}')"
# 提速包使用时间（分钟）
used_Minutes="$(echo "$qos_Info_x" | awk -F"\<usedMinutes\>|\<\/usedMinutes\>" '{if($2!="") print $2}')"
# 提速状态
re_STATUS="$(echo "$qos_Info_x" | awk -F"\<istelespeedup\>|\<\/istelespeedup\>" '{if($2!="") print $2}')"
# 重置剩余时间
remaining_Time="$(echo "$qos_Info_x" | awk -F"\<remainingTime\>|\<\/remainingTime\>" '{if($2!="") print $2}')"

}

QOS_Status()
{

#Session_Key="$(echo "$check_Qos" | grep -Eo "SessionKey:[ A-Za-z0-9_-]+" | cut -d ':' -f2 | sed -e "s/ //g" )"
#Signa_ture="$(echo "$check_Qos" | grep -Eo "Signature:[ A-Za-z0-9_-]+" | cut -d ':' -f2 | sed -e "s/ //g" )"
#GMT_Date="$(echo "$check_Qos" | grep -Eo "Date:[ A-Za-z0-9_-]+,[ A-Za-z0-9_-]+:[0-9]+:[ A-Za-z0-9_-]+" | awk -F 'Date: ' '{print $2}')"
#family_Id="$(echo "$check_Qos" | grep -Eo "familyId=[0-9]+" | awk -F '=' '{print $2}')"

#check_Qos_x="curl -s -H 'SessionKey: ""$Session_Key""' -H 'Signature: ""$Signa_ture""' -H 'Date: ""$GMT_Date""' -H 'Content-Type: text/xml; charset=utf-8' -H 'Host: api.cloud.189.cn' -H 'User-Agent: Apache-HttpClient/UNAVAILABLE (java 1.4)' 'http://api.cloud.189.cn/family/qos/checkQosAbility.action?familyId=""$family_Id""'"

check_Qos_x="$(echo "$check_Qos"" -s ")"

re_STAT="$(eval "$check_Qos_x" | grep qosListResponse)"

# 获取状态
if [[ "$Info"x == "1"x ]]; then
	# 提速包1
	qos_Info_1="$(echo "$re_STAT" | awk -F '/qosInfo' '{print $1}')"
	qos_Info_x="$qos_Info_1"
fi
if [[ "$Info"x == "2"x ]]; then
	# 提速包2
	qos_Info_2="$(echo "$re_STAT" | awk -F '/qosInfo' '{print $2}')"
	qos_Info_x="$qos_Info_2"
fi
if [[ "$Info"x == "3"x ]]; then
	# 提速包3
	qos_Info_3="$(echo "$re_STAT" | awk -F '/qosInfo' '{print $3}')"
	qos_Info_x="$qos_Info_3"
fi
if [[ "$Info"x == "4"x ]]; then
	# 提速包4
	qos_Info_4="$(echo "$re_STAT" | awk -F '/qosInfo' '{print $4}')"
	qos_Info_x="$qos_Info_4"
fi
if [[ "$Info"x == "5"x ]]; then
	# 提速包5
	qos_Info_5="$(echo "$re_STAT" | awk -F '/qosInfo' '{print $5}')"
	qos_Info_x="$qos_Info_5"
fi

get_info

STATUS=$re_STATUS

sleep 3
}

QOS_Start()
{

#Session_Key="$(echo "$Start_Qos" | grep -Eo "SessionKey:[ A-Za-z0-9_-]+" | cut -d ':' -f2 | sed -e "s/ //g" )"
#Signa_ture="$(echo "$Start_Qos" | grep -Eo "Signature:[ A-Za-z0-9_-]+" | cut -d ':' -f2 | sed -e "s/ //g" )"
#GMT_Date="$(echo "$Start_Qos" | grep -Eo "Date:[ A-Za-z0-9_-]+,[ A-Za-z0-9_-]+:[0-9]+:[ A-Za-z0-9_-]+" | awk -F 'Date: ' '{print $2}')"

#start_Qos_x="curl -s -H 'SessionKey: ""$Session_Key""' -H 'Signature: ""$Signa_ture""' -H 'Date: ""$GMT_Date""' -H 'Content-Type: text/xml; charset=utf-8' -H 'Host: api.cloud.189.cn' -H 'User-Agent: Apache-HttpClient/UNAVAILABLE (java 1.4)' 'http://api.cloud.189.cn/family/qos/startQos.action?prodCode=""$prod_Code""'"

start_Qos_x="$(echo "$Start_Qos"" -s ")"

SN_STAT="$(eval "$start_Qos_x" | grep qosInfo)"

SN="$(echo "$SN_STAT" | awk -F"\<qosSn\>|\<\/qosSn\>" '{if($2!="") print $2}')"

echo `date "+%Y-%m-%d %H:%M:%S"` "Start telespeedup, SN: $SN"
sleep 3
}

QOS_Heart()
{

if [ "$SN"x != "x" ] && [ "$SN" != "0" ] ; then
	Heart_Qos_x="$(echo "$Heart_Qos" | sed -e "s|^\(.*qosSn.*\)=[^=]*$|\1=$SN|")"
	Heart_Qos_x="$(echo "$Heart_Qos_x""' -s ")"
	eval "$Heart_Qos_x"

fi

}



case $ACTION in
start)
	dbus set telespeedup_status=0
	telespeedup_close
	telespeedup_check
	echo XU6J03M6 >> $logfile
	http_response '设置已保存！切勿重复提交！页面将在1秒后刷新'
	;;
check)
	telespeedup_check
	http_response '设置已保存！切勿重复提交！页面将在1秒后刷新'
	;;
stop)
	http_response '设置已保存！切勿重复提交！页面将在1秒后刷新'
	telespeedup_close
	;;
keep)
	#telespeedup_check
	telespeedup_keep
	http_response '设置已保存！切勿重复提交！页面将在1秒后刷新'
	;;
start_path)
	telespeedup_start_path
	http_response '设置已保存！切勿重复提交！页面将在1秒后刷新'
	;;
*)
	http_response '设置已保存！切勿重复提交！页面将在1秒后刷新'
	telespeedup_check
	;;
esac
