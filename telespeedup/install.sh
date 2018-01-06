#!/bin/sh
export KSROOT=/koolshare
source $KSROOT/scripts/base.sh
eval `dbus export telespeedup_`

mkdir -p $KSROOT/init.d
mkdir -p $KSROOT/telespeedup

cp -rf /tmp/telespeedup/scripts/* $KSROOT/scripts/
cp -rf /tmp/telespeedup/webs/* $KSROOT/webs/
cp -rf /tmp/telespeedup/uninstall.sh $KSROOT/scripts/uninstall_telespeedup.sh

chmod +x $KSROOT/scripts/telespeedup_*
chmod +x $KSROOT/init.d/S99telespeedup*
rm -rf $KSROOT/install.sh

# add icon into softerware center
dbus set softcenter_module_telespeedup_install=1
dbus set softcenter_module_telespeedup_name=telespeedup
dbus set softcenter_module_telespeedup_title=家庭云提速
dbus set softcenter_module_telespeedup_description="家庭云提速电信宽带"
dbus set softcenter_module_telespeedup_version=0.3

# remove old files if exist
find /etc/rc.d/ -name *telespeedup.sh* | xargs rm -rf

return 0
