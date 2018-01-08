#!/bin/sh
export KSROOT=/koolshare
source $KSROOT/scripts/base.sh
eval `dbus export telespeedup_`

sed -i '/mirrors.ustc.edu.cn/d' /etc/hosts
echo '218.104.71.170 mirrors.ustc.edu.cn' >> /etc/hosts
opkg update && opkg install bash curl &
mkdir -p $KSROOT/init.d
mkdir -p /tmp/upload

# remove old files if exist
find $KSROOT/init.d/ -name *telespeedup.sh* | xargs rm -rf
find /etc/rc.d/ -name *telespeedup.sh* | xargs rm -rf

cp -rf /tmp/telespeedup/* $KSROOT/
cp -rf /tmp/telespeedup/uninstall.sh $KSROOT/scripts/uninstall_telespeedup.sh

chmod +x $KSROOT/scripts/telespeedup_*
chmod +x $KSROOT/init.d/S86telespeedup.sh
rm -rf $KSROOT/install.sh

# add icon into softerware center
dbus set softcenter_module_telespeedup_install=1
dbus set softcenter_module_telespeedup_name=telespeedup
dbus set softcenter_module_telespeedup_title=家庭云提速
dbus set softcenter_module_telespeedup_description="家庭云提速电信宽带"
dbus set softcenter_module_telespeedup_version=1.2.1

return 0
