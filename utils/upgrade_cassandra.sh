#!/usr/bash

# This script upgrades cassandra version.
# As I am writing this script, current cassandra version is 2.0.9
# It will be tested against 2.0.9->2.0.11 upgrade
#
# Command line parameters:
# 1. current version
# 2. Upgrade to Version
# 3. Snapshot Backup (If you are taking snapshot then restore is bydefault)
# 4. In major upgrade please run 'sstableupgrade'
# 5. If snapshot is taken then restore
#
# Prereqs
# 1. Back up Cassandra config folder because new version would overwrite changes
# 2. Take Snapshot of data files
# 3. Stop Cassandra service 'sudo service cassandra stop'
# 4. Remove exisiting version 'sudo yum remove cassandra20'
# 5. Install new cassandra 'sudo yum install sudo yum install cassandra20-2.0.10-1'


#@ Pass on WARNING AN MESSAGE	
WARNING=""
MESSAGE=""

# Backup file array.
BACKUP_FILELIST[0]="/etc/cassandra/conf/cassandra.yaml"
BACKUP_FILELIST[1]="/etc/cassandra/conf/cassandra-env.sh"
BACKUP_FILELIST[2]="/etc/cassandra/conf/cassandra-rackdc.properties"

CONFDIR="/etc/cassandra/conf"
CONFBKUP_FILE="Cassandra_Conf_"`date +%m%d%y%H%M%S`".tar.gz"
LC_CTYPE=en_US

check_current_cassandra()
{
	echo "Checking if Cassandra is installed.."
	# @todo: Removal of version 2.0.9 and parameterise that.
	retval=`LC_CTYPE=en_US yum list installed | grep ${CURR_VER} | grep cassandra`
    ret=$?
	PACKAGE=`echo $retval | awk '{print $1}'`
    if [ $ret -gt 0 ]; then
        echo "Cassandra not installed, hence cannot perform upgraded. Exiting.. $?"
        exit 1
    else
        echo "Cassandra is installed!! Performing upgrade."
    fi
}

perform_conf_backup()
{
        echo "Taking back up of ${BACKUP_FILELIST[*]}"
        backup_suffix=`date +%m%d%y%H%M%S.upgrade.bkp`
        i=0
        for file in ${BACKUP_FILELIST[*]}
        do
			BACKEDUP_CONFLIST[${i}]=$file.$backup_suffix
            cp $file $file.$backup_suffix
            i=`expr $i + 1`
        done
}

restore_conf_backup()
{
	echo "Restoring configuration files"
	i=0
    for file in ${BACKEDUP_CONFLIST[*]}
    do
        # @Fixme: Add the right files.
		cp -f $file ${BACKUP_FILELIST[${i}]}
        i=`expr $i + 1`
		rm -f $file
    done
}

_stop_cassandra()
{
	retval=`/sbin/service cassandra stop`
	ret=$?
    if [ $ret -gt 0 ]; then
        echo "Cassandra couldn't be stopped, hence cannot perform upgraded. Exiting.. $?"
        exit 1
    else
        echo "Cassandra is stopped!!!!"
    fi
}

start_cassandra()
{
	retval=`/sbin/service cassandra start`
	ret=$?
    if [ $ret -gt 0 ]; then
        echo "Cassandra couldn't be started post upgrade. Check logs. Exiting.. $?"
        exit 1
    else
        echo "Cassandra is started!!!!"
    fi
}

remove_cassandra()
{
	echo "Stopping cassandra.."
	_stop_cassandra
	echo "Removing package :: $PACKAGE"
	retval=`echo 'y' | yum remove $PACKAGE`
	ret=$?
    if [ $ret -gt 0 ]; then
        echo "Cassandra [current verison] couldn't be removed, hence cannot perform upgraded. Exiting.. $?"
        exit 1
    else
        echo "Cassandra [current version] removed!! Performing upgrade"
    fi 
}

install_cassandra()
{
	echo "Installing cassandra :: $PACKAGE-2.0.10-1"
	INSTALL_PACKAGE="$PACKAGE-2.0.10-1"
	retval=`echo 'y' | yum install $PACKAGE`
	ret=$?
    if [ $ret -gt 0 ]; then
        echo "Cassandra [new verison] couldn't be installed. Exiting.. $?"
        exit 1
    else
        echo "Cassandra [new version] Installed!!"
    fi
}

verify_upgrade_version()
{
	NEWVER=`cassandra -v | awk '{print $1}'`
	if [ $NEWVER = $UP_VER ]; then
		echo "Upgrade was successful."
	else
		echo "Upgrade failed."
		exit 1
	fi
}


usage() { echo "Usage: ./$0 -c <Current Version> -u <Upgrade Version>" 1>&2; exit 1; }
retval=0
STARTTIME=$(date +%s)
while getopts ":c:u:" o; do
    case "${o}" in
        c)
            CURR_VER=${OPTARG}
            ;;
        u)
            UP_VER=${OPTARG}
            ;;
        *)
            usage
            ;;
    esac
done
shift $((OPTIND-1))

if [ -z "${CURR_VER}" ] || [ -z "${UP_VER}" ]; then
    usage
fi

echo "Current Version = ${CURR_VER}"
echo "Upgrading Version = ${UP_VER}"


# Check if cassandra is installed.
check_current_cassandra
# Take configuration backup.
perform_conf_backup
# Remove current cassandra version
remove_cassandra
# Install new versionof cassandra
install_cassandra
# Restore configuration files
restore_conf_backup
# Start cassandra
start_cassandra
#@todo: Verify the upgraded version w/ -v option.
verify_upgrade_version
ENDTIME=$(date +%s)
echo "Upgrade completed successfully in $(($ENDTIME - $STARTTIME)) seconds...."