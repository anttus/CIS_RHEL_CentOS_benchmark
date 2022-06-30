#!/bin/bash -
#title          :2. Services
#description    :This script tests if some services are on/installed, based on CIS CentOS / RHEL 7 benchmark chapter 2
#author         :Anttu Suhonen
#date           :20180524
#version        :1.0
#usage          :./2-services.sh
#============================================================================

exec > ./results/"$(hostname)"_CIS_services_"$(date +%d-%m-%Y)".log
exec 2>&1

# Functions ------------->
checkIfEnabled () {
    cmd="$(systemctl is-enabled "$1")"
    if [[ "$cmd" == "enabled" ]]; then
        printf "package %s is ENABLED\\n" "$1"
        results[index-1]="NOT OK"
    elif [[ "$cmd" == "disabled" ]]; then
        printf "package %s is DISABLED - OK\\n" "$1"
        results[index-1]="OK"
    else
        printf "package %s is disabled or not installed\\n" "$1"
        results[index-1]="OK"
    fi
}

function brLine {
    printf "\\n--------------------\\n"
}

function summary {
    printf "\\n\\n-------------------- [SUMMARY - servicesCheck] --------------------\\n\\n"
    for (( i = 0; i < ${#titles[@]}; i++ )); do
        printf "%-75s - %s\\n" "${titles[$i]}" "${results[$i]}"
    done
}

function chkConfigResults {
    found=false
    resultLength="$(chkconfig --list 2>/dev/null | awk 'END{print NR}')"
    for (( i = 1; i < resultLength + 1; i++ )); do
        result="$(chkconfig --list 2>/dev/null | awk 'NR=='$i'{print $1}')"
        fullResult="$(chkconfig --list 2>/dev/null | awk 'NR=='$i'{print}')"
        if [[ $result =~ $1 ]]; then
            printf "%s FOUND. Verify that it is OFF:\\n%s\\n" "$1" "$fullResult"
            results[index-1]="REQUIRES CHECKING"
            found=true
            return
        else
            found=false
        fi
    done
    if [[ $found == false ]]; then
        printf "%s Not found - OK\\n" "$1"
        results[index-1]="OK"
    fi
}

function checkIfInstalled {
    if rpm -q "$1" > /dev/null 2>&1 ; then
        printf "Package %s is installed. Check if it can be removed.\\n" "$1"
        results[index-1]="NOT OK"
    else
        printf "Package %s is NOT installed - OK\\n" "$1"
        results[index-1]="OK"
    fi
}
# End of functions -------------|


printf "\\nThis script tests if some services are on/installed, \\nbased on CIS_CentOS_Linux_7_Benchmark_v2.2.0's chapter 2.\\n\\n"

index=0

# printf "Verify that the following are off or missing:\\n"
title="[2.1.1 Ensure chargen services are not enabled (103)]"
titles[index++]="$title"
printf "%s\\n\\n" "$title"
chkConfigResults "chargen"
brLine

title="[2.1.2 Ensure daytime services are not enabled (105)]"
titles[index++]="$title"
printf "%s\\n\\n" "$title"
chkConfigResults "daytime"
brLine

title="[2.1.3 Ensure discard services are not enabled (106)]"
titles[index++]="$title"
printf "%s\\n\\n" "$title"
chkConfigResults "discard"
brLine

title="[2.1.4 Ensure echo services are not enabled (107)]"
titles[index++]="$title"
printf "%s\\n\\n" "$title"
chkConfigResults "echo"
brLine

title="[2.1.5 Ensure time services are not enabled (108)]"
titles[index++]="$title"
printf "%s\\n\\n" "$title"
chkConfigResults "time"
brLine

title="[2.1.6 Ensure tftp server is not enabled (109)]"
titles[index++]="$title"
printf "%s\\n\\n" "$title"
chkConfigResults "tftp"
brLine

# 2.1.7 Ensure xinetd is not enabled
title"[2.1.7 Ensure xinetd is not enabled (110)]"
titles[index++]="$title"
printf "%s\\n\\n" "$title"
checkIfEnabled "xinetd"
brLine

# 2.2.1.1 Ensure time synchronization is in use (Not scored, will do)
title="[2.2.1.1 Ensure time synchronization is in use (Not scored, will do) (111)]"
titles[index++]="$title"
printf "%s\\n\\n" "$title"
printf "Verify either ntp or chrony is installed:\\n\\n[OUTPUT]:\\n"
rpm -q ntp
rpm -q chrony
results[index-1]="REQUIRES CHECKING"
brLine

# 2.2.1.2 Ensure ntp is configured (Scored)
title="[2.2.1.2 Ensure ntp is configured (113)]"
titles[index++]="$title"
printf "%s\\n\\n" "$title"
printf "[CASE 1]\\nVerify output matches:\\n'restrict -4 default kod nomodify notrap nopeer noquery\\n restrict -6 default kod nomodify notrap nopeer noquery'\\n\\n[OUTPUT]:\\n"
grep "^restrict" /etc/ntp.conf

printf "\\n[CASE 2]\\nVerify remote server is configured properly. Output should be something like:\\nserver <remote-server>\\n"
ntpVar="$(grep "^(server|pool)" /etc/ntp.conf)"
printf "\\n[OUTPUT]: "
if [[ -z "$ntpVar" ]]; then
    printf "\\n[empty - not configured]\\n\\n"
else
    grep "^(server|pool)" /etc/ntp.conf
fi

printf "\\n[CASE 3]\\nVerify that ' -u ntp:ntp ' is included in OPTIONS or ExecStart like:\\nOPTIONS=\"-u ntp:ntp\"\\nExecStart=/usr/sbin/ntpd -u ntp:ntp \\u0024OPTIONS\\n\\n[OUTPUT]:\\n"
grep "^OPTIONS" /etc/sysconfig/ntpd
grep "^ExecStart" /usr/lib/systemd/system/ntpd.service
results[index-1]="REQUIRES CHECKING"
brLine

# 2.2.1.3 Ensure chrony is configured (if chrony is in use)
title="[2.2.1.3 Ensure chrony is configured (if chrony is in use) (115)]"
titles[index++]="$title"
printf "%s\\n\\n" "$title"
printf "[CASE 1]\\nVerify remote server is configured properly. Output should be something like:\\nserver <remote-server>\\n\\n"
chronyVar="$(grep "^(server|pool)" /etc/chrony.conf)"
printf "\\n[OUTPUT]:"
if [[ -z "$chronyVar" ]]; then
    printf "\\n[empty - not configured]\\n"
else
    grep "^(server|pool)" /etc/chrony.conf
fi

printf "\\n[CASE 2]\\nVerify OPTIONS includes '-u chrony' like:\\nOPTIONS=\"-u chrony\"\\n"
printf "\\n[OUTPUT]: \\n"
grep ^OPTIONS /etc/sysconfig/chronyd
results[index-1]="REQUIRES CHECKING"
brLine

# 2.2.2 Ensure X Window System is not installed
title="[2.2.2 Ensure X Window System is not installed (117)]"
titles[index++]="$title"
printf "%s\\n\\n" "$title"
printf "Verify no output is returned:\\n"
xorgVar="$(rpm -qa xorg-x11*)"
if [ -z "$xorgVar" ]; then
    echo "[empty]"
    results[index-1]="OK"
else
    rpm -qa xorg-x11*
    results[index-1]="NOT OK"
fi
brLine

# 2.2.3 Ensure Avahi Server is not enabled
title="[2.2.3 Ensure Avahi Server is not enabled (118)]"
titles[index++]="$title"
printf "%s\\n\\n" "$title"
checkIfEnabled "avahi-daemon"
brLine

# 2.2.4 Ensure CUPS is not enabled
title="[2.2.4 Ensure CUPS is not enabled (119)]"
titles[index++]="$title"
printf "%s\\n\\n" "$title"
checkIfEnabled "cups"
brLine

# 2.2.5 Ensure DHCP Server is not enabled
title="[2.2.5 Ensure DHCP Server is not enabled (121)]"
titles[index++]="$title"
printf "%s\\n\\n" "$title"
checkIfEnabled "dhcpd"
brLine

# 2.2.6 Ensure LDAP server is not enabled
title="[2.2.6 Ensure LDAP server is not enabled (122)]"
titles[index++]="$title"
printf "%s\\n\\n" "$title"
checkIfEnabled "slapd"
brLine

# 2.2.7 Ensure NFS and RPC are not enabled
title="[2.2.7 Ensure NFS and RPC are not enabled (123)]"
titles[index++]="$title - [CASE 1]"
printf "%s\\n\\n" "$title - [CASE 1]"
checkIfEnabled "nfs"
printf "\\n"
titles[index++]="$title - [CASE 2]"
printf "%s\\n\\n" "$title - [CASE 2]"
checkIfEnabled "nfs-server"
printf "\\n"
titles[index++]="$title - [CASE 3]"
printf "%s\\n\\n" "$title - [CASE 3]"
checkIfEnabled "rpcbind"
brLine

# 2.2.8 Ensure DNS Server is not enabled
title="[2.2.8 Ensure DNS Server is not enabled (125)]"
titles[index++]="$title"
printf "%s\\n\\n" "$title"
checkIfEnabled "named"
brLine

# 2.2.9 Ensure FTP Server is not enabled
title="[2.2.9 Ensure FTP Server is not enabled (126)]"
titles[index++]="$title"
printf "%s\\n\\n" "$title"
checkIfEnabled "vsftpd"
brLine

# 2.2.10 Ensure HTTP server is not enabled
title="[2.2.10 Ensure HTTP server is not enabled (127)]"
titles[index++]="$title"
printf "%s\\n\\n" "$title"
checkIfEnabled "httpd"
brLine

# 2.2.11 Ensure IMAP and POP3 server is not enabled
title="[2.2.11 Ensure IMAP and POP3 server is not enabled (128)]"
titles[index++]="$title"
printf "%s\\n\\n" "$title"
checkIfEnabled "dovecot"
brLine

# 2.2.12 Ensure Samba is not enabled
title="[2.2.12 Ensure Samba is not enabled (129)]"
titles[index++]="$title"
printf "%s\\n\\n" "$title"
checkIfEnabled "smb"
brLine

# 2.2.13 Ensure HTTP Proxy Server is not enabled
title="[2.2.13 Ensure HTTP Proxy Server is not enabled (130)]"
titles[index++]="$title"
printf "%s\\n\\n" "$title"
checkIfEnabled "squid"
brLine

# 2.2.14 Ensure SNMP Server is not enabled
title="[2.2.14 Ensure SNMP Server is not enabled (131)]"
titles[index++]="$title"
printf "%s\\n\\n" "$title"
checkIfEnabled "snmpd"
brLine

# 2.2.15 Ensure mail transfer agent is configured for local-only mode
title="[2.2.15 Ensure mail transfer agent is configured for local-only mode (133)]"
titles[index++]="$title"
printf "%s\\n\\n" "$title"
printf "Verify that the MTA is not listening on any non-loopback address ( 127.0.0.1 or ::1 ):\\n\\n[OUTPUT]:\\n"
netstat -an | grep LIST | grep ":25[[:space:]]"
results[index-1]="REQUIRES CHECKING"
brLine

# 2.2.16 Ensure NIS Server is not enabled
title="[2.2.16 Ensure NIS Server is not enabled (135)]"
titles[index++]="$title"
printf "%s\\n\\n" "$title"
checkIfEnabled "ypserv"
brLine

# 2.2.17 Ensure rsh server is not enabledv
title="[2.2.17 Ensure rsh server is not enabled (136)"
titles[index++]="$title - [CASE 1]"
printf "%s\\n\\n" "$title - [CASE 1]"
checkIfEnabled "rsh.socket"
titles[index++]="$title - [CASE 2]"
printf "%s\\n\\n" "$title - [CASE 2]"
checkIfEnabled "rlogin.socket"
titles[index++]="$title - [CASE 3]"
printf "%s\\n\\n" "$title - [CASE 3]"
checkIfEnabled "rexec.socket"
brLine

# 2.2.18 Ensure telnet server is not enabled
title="[2.2.18 Ensure telnet server is not enabled (138)]"
titles[index++]="$title"
printf "%s\\n\\n" "$title"
checkIfEnabled "telnet.socket"
brLine

# 2.2.19 Ensure tftp server is not enabled
title="[2.2.19 Ensure tftp server is not enabled (139)]"
titles[index++]="$title"
printf "%s\\n\\n" "$title"
checkIfEnabled "tftp.socket"
brLine

# 2.2.20 Ensure rsync service is not enabled
title="[2.2.20 Ensure rsync service is not enabled (140)]"
titles[index++]="$title"
printf "%s\\n\\n" "$title"
checkIfEnabled "rsyncd"
brLine

# 2.2.21 Ensure talk server is not enabled
title="[2.2.21 Ensure talk server is not enabled (141)]"
titles[index++]="$title"
printf "%s\\n\\n" "$title"
checkIfEnabled "ntalk"
brLine

# 2.3.1 Ensure NIS Client is not installed
title="[2.3.1 Ensure NIS Client is not installed (142)]"
titles[index++]="$title"
printf "%s\\n\\n" "$title"
checkIfInstalled ypbind
brLine

# 2.3.2 Ensure rsh client is not installed
title="[2.3.2 Ensure rsh client is not installed (144)]"
titles[index++]="$title"
printf "%s\\n\\n" "$title"
checkIfInstalled rsh
brLine

# 2.3.3 Ensure talk client is not installed
title="[2.3.3 Ensure talk client is not installed (146)]"
titles[index++]="$title"
printf "%s\\n\\n" "$title"
checkIfInstalled talk
brLine

# 2.3.4 Ensure telnet client is not installed
title="[2.3.4 Ensure telnet client is not installed (147)]"
titles[index++]="$title"
printf "%s\\n\\n" "$title"
checkIfInstalled telnet
brLine

# 2.3.5 Ensure LDAP client is not installed
title="[2.3.5 Ensure LDAP client is not installed (149)]"
titles[index++]="$title"
printf "%s\\n\\n" "$title"
checkIfInstalled openldap-clients
brLine

summary
