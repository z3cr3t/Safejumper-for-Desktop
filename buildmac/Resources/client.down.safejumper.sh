#!/bin/bash -e
# Note: must be bash; uses bash-specific tricks
#
# ******************************************************************************************************************
# This Safejumper script does everything! It handles TUN and TAP interfaces, 
# pushed configurations and DHCP leases. :)
# 
# This is the "Down" version of the script, executed after the connection is 
# closed.
#
#
# ******************************************************************************************************************
echo "BEGINNING OF DOWN SCRIPT"
# @param String message - The message to log
logMessage()
{
echo "$(date '+%a %b %e %T %Y') *Safejumper $LOG_MESSAGE_COMMAND: "${@} >> "${SCRIPT_LOG_FILE}"
}

trim()
{
echo ${@}
}

##########################################################################################
flushDNSCache()
{
    if ${ARG_FLUSH_DNS_CACHE} ; then
        set +e # "grep" will return error status (1) if no matches are found, so don't fail on individual errors
        readonly OSVER="$(sw_vers | grep 'ProductVersion:' | grep -o '10\.[0-9]*')"
set -e # We instruct bash that it CAN again fail on errors
        case "${OSVER}" in
            10.4 )
                if [ -f /usr/sbin/lookupd ] ; then
                    /usr/sbin/lookupd -flushcache
                    logMessage "Flushed the DNS Cache"
                else
                    logMessage "/usr/sbin/lookupd not present. Not flushing the DNS cache"
                fi
                ;;
            10.5 | 10.6 )
                if [ -f /usr/bin/dscacheutil ] ; then
                    /usr/bin/dscacheutil -flushcache
                    logMessage "Flushed the DNS Cache"
                else
                    logMessage "/usr/bin/dscacheutil not present. Not flushing the DNS cache"
                fi
                ;;
            * )
				set +e # "grep" will return error status (1) if no matches are found, so don't fail on individual errors
				hands_off_ps="$( ps -ax | grep HandsOffDaemon | grep -v grep.HandsOffDaemon )"
				set -e # We instruct bash that it CAN again fail on errors
				if [ "${hands_off_ps}" = "" ] ; then
					if [ -f /usr/bin/killall ] ; then
						/usr/bin/killall -HUP mDNSResponder
						logMessage "Flushed the DNS Cache"
					else
						logMessage "/usr/bin/killall not present. Not flushing the DNS cache"
					fi
				else
					logMessage "Hands Off is running. Not flushing the DNS cache"
				fi
                ;;
        esac
    fi
}

##########################################################################################
trap "" TSTP
trap "" HUP
trap "" INT
export PATH="/bin:/sbin:/usr/sbin:/usr/bin"

readonly LOG_MESSAGE_COMMAND=$(basename "${0}")

# Quick check - is the configuration there?
if ! scutil -w State:/Network/OpenVPN &>/dev/null -t 1 ; then
	# Configuration isn't there, so we forget it
	echo "$(date '+%a %b %e %T %Y') *Safejumper $LOG_MESSAGE_COMMAND: WARNING: No existing OpenVPN DNS configuration found; not tearing down anything; exiting."
	exit 0
fi

# NOTE: This script does not use any arguments passed to it by OpenVPN, so it doesn't shift Safejumper options out of the argument list

# Get info saved by the up script
SAFEJUMPER_CONFIG="$( scutil <<-EOF
	open
	show State:/Network/OpenVPN
	quit
EOF
)"

ARG_MONITOR_NETWORK_CONFIGURATION="$(echo "${SAFEJUMPER_CONFIG}" | grep -i '^[[:space:]]*MonitorNetwork :' | sed -e 's/^.*: //g')"
LEASEWATCHER_PLIST_PATH="$(echo "${SAFEJUMPER_CONFIG}" | grep -i '^[[:space:]]*LeaseWatcherPlistPath :' | sed -e 's/^.*: //g')"
PSID="$(echo "${SAFEJUMPER_CONFIG}" | grep -i '^[[:space:]]*Service :' | sed -e 's/^.*: //g')"
#SCRIPT_LOG_FILE="$(echo "${SAFEJUMPER_CONFIG}" | grep -i '^[[:space:]]*ScriptLogFile :' | sed -e 's/^.*: //g')"
SCRIPT_LOG_FILE="/tmp/safejumper-down-script.log"
# Don't need: ARG_RESTORE_ON_DNS_RESET="$(echo "${SAFEJUMPER_CONFIG}" | grep -i '^[[:space:]]*RestoreOnDNSReset :' | sed -e 's/^.*: //g')"
# Don't need: ARG_RESTORE_ON_WINS_RESET="$(echo "${SAFEJUMPER_CONFIG}" | grep -i '^[[:space:]]*RestoreOnWINSReset :' | sed -e 's/^.*: //g')"
# Don't need: PROCESS="$(echo "${SAFEJUMPER_CONFIG}" | grep -i '^[[:space:]]*PID :' | sed -e 's/^.*: //g')"
# Don't need: ARG_IGNORE_OPTION_FLAGS="$(echo "${SAFEJUMPER_CONFIG}" | grep -i '^[[:space:]]*IgnoreOptionFlags :' | sed -e 's/^.*: //g')"
ARG_TAP="$(echo "${SAFEJUMPER_CONFIG}" | grep -i '^[[:space:]]*IsTapInterface :' | sed -e 's/^.*: //g')"
ARG_FLUSH_DNS_CACHE="$(echo "${SAFEJUMPER_CONFIG}" | grep -i '^[[:space:]]*FlushDNSCache :' | sed -e 's/^.*: //g')"
ARG_RESET_PRIMARY_INTERFACE_ON_DISCONNECT="$(echo "${SAFEJUMPER_CONFIG}" | grep -i '^[[:space:]]*ResetPrimaryInterface :' | sed -e 's/^.*: //g')"
bRouteGatewayIsDhcp="$(echo "${SAFEJUMPER_CONFIG}" | grep -i '^[[:space:]]*RouteGatewayIsDhcp :' | sed -e 's/^.*: //g')"
bTapDeviceHasBeenSetNone="$(echo "${SAFEJUMPER_CONFIG}" | grep -i '^[[:space:]]*TapDeviceHasBeenSetNone :' | sed -e 's/^.*: //g')"
bAlsoUsingSetupKeys="$(echo "${SAFEJUMPER_CONFIG}" | grep -i '^[[:space:]]*bAlsoUsingSetupKeys :' | sed -e 's/^.*: //g')"

# clear script log
echo "" > "${SCRIPT_LOG_FILE}"

if ${ARG_TAP} ; then
	if [ "$bRouteGatewayIsDhcp" == "true" ]; then
        if [ "$bTapDeviceHasBeenSetNone" == "false" ]; then
            if [ -z "$dev" ]; then
                logMessage "Cannot configure TAP interface for DHCP without \$dev being defined. Device may not have disconnected properly."
            else
                set +e
                ipconfig set "$dev" NONE 2>/dev/null
                set -e
            fi
        fi
    fi
fi

####################################
echo "HACK: exiting!"
exit 0
####################################
# Issue warning if the primary service ID has changed
set +e # "grep" will return error status (1) if no matches are found, so don't fail if not found
PSID_CURRENT="$( scutil <<-EOF |
	open
	show State:/Network/OpenVPN
	quit
EOF
grep Service | sed -e 's/.*Service : //'
)"
set -e # resume abort on error
if [ "${PSID}" != "${PSID_CURRENT}" ] ; then
	logMessage "Ignoring change of Network Primary Service from ${PSID} to ${PSID_CURRENT}"
fi

# Remove leasewatcher
if ${ARG_MONITOR_NETWORK_CONFIGURATION} ; then
	launchctl unload "${LEASEWATCHER_PLIST_PATH}"
    rm -f "${LEASEWATCHER_PLIST_PATH}"
	logMessage "Cancelled monitoring of system configuration changes"
fi

# Restore configurations
DNS_OLD="$( scutil <<-EOF
	open
	show State:/Network/OpenVPN/OldDNS
	quit
EOF
)"
SMB_OLD="$( scutil <<-EOF
	open
	show State:/Network/OpenVPN/OldSMB
	quit
EOF
)"
DNS_OLD_SETUP="$( scutil <<-EOF
	open
	show State:/Network/OpenVPN/OldDNSSetup
	quit
EOF
)"
SJ_NO_SUCH_KEY="<dictionary> {
  SafejumperNoSuchKey : true
}"

if [ "${DNS_OLD}" = "${SJ_NO_SUCH_KEY}" ] ; then
	scutil <<-EOF
		open
		remove State:/Network/Service/${PSID}/DNS
		quit
EOF
else
	scutil <<-EOF
		open
		get State:/Network/OpenVPN/OldDNS
		set State:/Network/Service/${PSID}/DNS
		quit
EOF
fi

if [ "${DNS_OLD_SETUP}" = "${SJ_NO_SUCH_KEY}" ] ; then
	if ${bAlsoUsingSetupKeys} ; then
		logMessage "DEBUG: Removing 'Setup:' DNS key"
		scutil <<-EOF
			open
			remove Setup:/Network/Service/${PSID}/DNS
			quit
EOF
	else
		logMessage "DEBUG: Not removing 'Setup:' DNS key"
	fi
else
	if ${bAlsoUsingSetupKeys} ; then
		logMessage "DEBUG: Restoring 'Setup:' DNS key"
		scutil <<-EOF
			open
			get State:/Network/OpenVPN/OldDNSSetup
			set Setup:/Network/Service/${PSID}/DNS
			quit
EOF
	else
		logMessage "DEBUG: Not restoring 'Setup:' DNS key"
	fi
fi

if [ "${SMB_OLD}" = "${SJ_NO_SUCH_KEY}" ] ; then
	scutil <<-EOF
		open
		remove State:/Network/Service/${PSID}/SMB
		quit
EOF
else
	scutil <<-EOF
		open
		get State:/Network/OpenVPN/OldSMB
		set State:/Network/Service/${PSID}/SMB
		quit
EOF
fi

logMessage "Restored the DNS and SMB configurations"

set +e # "grep" will return error status (1) if no matches are found, so don't fail if not found
new_resolver_contents="`cat /etc/resolv.conf | grep -v '#'`"
set -e # resume abort on error
logMessage "DEBUG:"
logMessage "DEBUG: /etc/resolve = ${new_resolver_contents}"

scutil_dns="$( scutil --dns)"
logMessage "DEBUG:"
logMessage "DEBUG: scutil --dns = ${scutil_dns}"
logMessage "DEBUG:"

flushDNSCache

# Remove our system configuration data
scutil <<-EOF
	open
	remove State:/Network/OpenVPN/OldDNS
	remove State:/Network/OpenVPN/OldSMB
	remove State:/Network/OpenVPN/OldDNSSetup
	remove State:/Network/OpenVPN/DNS
	remove State:/Network/OpenVPN/SMB
	remove State:/Network/OpenVPN
	quit
EOF

if ${ARG_RESET_PRIMARY_INTERFACE_ON_DISCONNECT} ; then

    set +e # "grep" will return error status (1) if no matches are found, so don't fail if not found
    PINTERFACE="$( scutil <<-EOF |
    open
    show State:/Network/Global/IPv4
    quit
EOF
    grep PrimaryInterface | sed -e 's/.*PrimaryInterface : //'
)"
    set -e # resume abort on error

    if [ "${PINTERFACE}" != "" ] ; then
        logMessage "Resetting primary interface '${PINTERFACE}'..."
        /sbin/ifconfig "${PINTERFACE}" down
        sleep 2
        /sbin/ifconfig "${PINTERFACE}" up
    else
        logMessage "Not resetting primary interface because it cannot be found."
    fi

fi
echo "THE END OF DOWN SCRIPT"
exit 0
