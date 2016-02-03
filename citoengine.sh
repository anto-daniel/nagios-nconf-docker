#! /bin/bash

NCONF_DIR=/var/www/nconf
NAGIOS_DIR=/usr/local/nagios
NAGIOS_CONF=$NAGIOS_DIR/etc
CITO_FILE=$NCONF_DIR/ADD-ONS/appops_events.csv
SRVCFG=$NAGIOS_CONF/Default_collector/services.cfg
HOSTCFG=$NAGIOS_CONF/Default_collector/hosts.cfg

if [ ! -f ${CITO_FILE} ] ; then
echo "please generate new  $CITO_FILE File from Cito Engine and upload to the path $NCONF_DIR/ADD-ONS"
exit 0;
fi
cd $NCONF_DIR/ADD-ONS
/usr/bin/python ./cito_config_parser.py --type nagios -c ${SRVCFG} --events-file $CITO_FILE --generate --out $NAGIOS_CONF/Default_collector/new_services.cfg >>error.log
value=`echo $?`
if [ "$value" -eq 0 ] ; then


echo "created new services.cfg and hosts.cfg  files with CITOENGINE parameters"

## adding service event codes to services.cfg file
mv $NAGIOS_CONF/Default_collector/new_services.cfg $SRVCFG
sed -ie '$!N; /^\(.*\)\n\1$/!P; D' $SRVCFG
chown www-data:www-data $SRVCFG

## adding host event code to hosts.cfg file
sed -i '/host_name/a _CITOEVENTID 7' $HOSTCFG
sed -ie '$!N; /^\(.*\)\n\1$/!P; D' $HOSTCFG   # Removes Repeated CITOEVENTID's 
sed -ie "/contact_groups/ s/$/,noc-mon-alerts/" $HOSTCFG

# adding noc-mon contact in contacts.cfg
cmd=`grep noc-mon $NAGIOS_CONF/global/contacts.cfg`
st=`echo $?`
if [ $st -eq 1 ]
then
echo "noc-mon is NOT defined....  Adding noc-mon in contacts.cfg"
cat >> $NAGIOS_CONF/global/contacts.cfg << EOM
define contact {
                contact_name                          noc-mon
                alias                                 noc-mon
                host_notification_options             d
                service_notification_options          c
                email                                 noc-mon@inmobi.com
                host_notification_period              24x7
                service_notification_period           24x7
                host_notification_commands            notify-host-by-email
                service_notification_commands         notify-service-by-email
}
EOM
else
echo "Already noc-mon is defined"
echo
fi

cmd1=`grep noc-mon-alerts $NAGIOS_CONF/global/contactgroups.cfg`
st1=`echo $?`
if [ $st1 -eq 1 ]
then
echo "noc-mon-alerts is not defined. Adding noc-mon-alerts in contactgroups.cfg"
cat >> $NAGIOS_CONF/global/contactgroups.cfg << EOM
define contactgroup {
                contactgroup_name                     noc-mon-alerts
                alias                                 noc-mon-alerts
                members                               noc-mon,citoengine
}

EOM
else
echo
echo "Already noc-mon-alerts present in contactgroups.cfg"
fi


## adding citoengine in contactgroups
add_contactgrp_to_service_alert() {
	lns=$(grep -n -A8 CITOEVENTID $SRVCFG | grep contact_groups | grep -v noc-mon-alerts | awk -F- '{print $1}')
	for ln in $lns; do 
	  sed -ie "${ln}s/$/,noc-mon-alerts/" ${SRVCFG}
 	  sed -n "${ln} p" ${SRVCFG}
	done
}
add_contactgrp_to_host_alert() {
	lns=$(grep -n -A20 CITOEVENTID $HOSTCFG | grep contact_groups | grep -v noc-mon-alerts | awk -F- '{print $1}')
	for ln in $lns; do 
	  sed -ie "${ln}s/$/,noc-mon-alerts/" ${HOSTCFG}
 	  sed -n "${ln} p" ${HOSTCFG}
	done
}
add_contactgrp_to_service_alert
add_contactgrp_to_host_alert
chown nagios:nagios $HOSTCFG
/etc/init.d/nagios reload
else
rm $NAGIOS_CONF/Default_collector/new_services.cfg
echo "Please generate new ${CITO_FILE} File from Cito Engine and upload to the path $NCONF_DIR/ADD-ONS/"
fi
