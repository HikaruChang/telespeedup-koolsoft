#! /bin/sh

export KSROOT=/koolshare
source $KSROOT/scripts/base.sh
eval `dbus export telespeedup_`

# remove dbus data in softcenter
confs=`dbus list telespeedup_|cut -d "=" -f1`
for conf in $confs
do
	dbus remove $conf
done


# remove files
rm -rf $KSROOT/bin/telespeedup*
rm -rf $KSROOT/scripts/uninstall_telespeedup*
rm -rf $KSROOT/init.d/S86telespeedup.sh
rm -rf /etc/rc.d/S99telespeedup.sh >/dev/null 2>&1
rm -rf $KSROOT/webs/Module_telespeedup.asp
rm -rf $KSROOT/webs/res/icon-telespeedup.png
rm -rf $KSROOT/webs/res/icon-telespeedup-bg.png

# remove skipd data of qiandao
dbus remove softcenter_module_telespeedup_home_url
dbus remove softcenter_module_telespeedup_install
dbus remove softcenter_module_telespeedup_md5
dbus remove softcenter_module_telespeedup_version
dbus remove softcenter_module_telespeedup_name
dbus remove softcenter_module_telespeedup_title
dbus remove softcenter_module_telespeedup_description
