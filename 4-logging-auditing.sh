#!/bin/bash -
#title          :4. Logging and auditig
#description    :This script checks the security of CentOS server's logging and auditing, based on CIS CentOS / RHEL 7 benchmark chapter 4
#author         :Anttu Suhonen
#date           :20180612
#version        :1.0
#usage          :./4-logging-auditing.sh
#============================================================================

exec > ./results/"$(hostname)"_CIS_logging-auditing_"$(date +%d-%m-%Y)".log
exec 2>&1

# Functions ------------->

function summary {
    printf "\\n\\n-------------------- [SUMMARY - loggingAuditing] --------------------\\n\\n"
    for (( i = 0; i < ${#titles[@]}; i++ )); do
        printf "%-93s - %s\\n\\n" "${titles[$i]}" "${results[$i]}"
    done
}

function brLine {
    printf "\\n--------------------\\n"
}

checkIfEnabled () {
  cmd="$(systemctl is-enabled "$1")"
  if [[ "$cmd" == "enabled" ]]; then
      printf "package %s is ENABLED - OK\\n" "$1"
      results[index-1]="OK"
  else
      printf "package %s is disabled or not installed\\n" "$1"
      results[index-1]="NOT OK"
  fi
}

# End of functions -------------|

printf "This script checks the security of CentOS server's logging and auditing, based on CIS_CentOS_Linux_7_Benchmark_v2.2.0.pdf's chapter 4.\\n\\n"

index=0

# 4.2.1.1 Ensure rsyslog Service is enabled (240)
title="[4.2.1.1 Ensure rsyslog Service is enabled (240)]"
titles[index++]="$title"
printf "%s\\n\\n" "$title"
checkIfEnabled "rsyslog"
brLine

# 4.2.1.3 Ensure rsyslog default file permissions configured (244)
title="[4.2.1.3 Ensure rsyslog default file permissions configured (244)]"
titles[index++]="$title"
printf "%s\\n\\n" "$title"
cmd="$(grep ^\$FileCreateMode /etc/rsyslog.conf /etc/rsyslog.d/*.conf)"
cmd2="$(grep ^\$FileCreateMode /etc/rsyslog.conf /etc/rsyslog.d/*.conf | awk '{print $2}')"
if [[ -z "$cmd" ]]; then
    printf "FileCreateMode does NOT exist in /etc/rsyslog.conf or /etc/rsyslog.d/*.conf.\\nSet it as: \$FileCreateMode 0640.\\n"
    results[index-1]="REQUIRES CHECKING"
else
    if [[ "$cmd2" == "640" ]]; then
        printf "FileCreateMode is set as 0640 - OK\\n"
        results[index-1]="OK"
    else
        printf "Set FileCreateMode as 0640\\n"
        results[index-1]="REQUIRES CHECKING"
    fi
fi
brLine

# 4.2.3 Ensure rsyslog or syslog-ng is installed (259)
title="[4.2.3 Ensure rsyslog or syslog-ng is installed (259)]"
titles[index++]="$title"
printf "%s\\n\\n" "$title"
if rpm -qa | grep rsyslog > /dev/null 2>&1 ; then
    printf "rsyslog is installed - OK\\n"
    results[index-1]="OK"
else
    printf "rsyslog is NOT installed\\n"
    results[index-1]="NOT OK"
fi
if rpm -qa | grep syslog-ng > /dev/null 2>&1 ; then
    printf "syslog-ng is installed - OK\\n"
else
    printf "syslog-ng is NOT installed\\n"
fi
brLine

# 4.2.4 Ensure permissions on all logfiles are configured (261)
title="[4.2.4 Ensure permissions on all logfiles are configured (261)] [CASE 1 - Group permissions]"
titles[index++]="$title"
printf "%s\\n\\n" "$title"

group=false
other=false
groupPermsNum="$(stat --format=%a $(find /var/log -type f) | awk '{ print substr($1,2,1) }')"
otherPermsNum="$(stat --format=%a $(find /var/log -type f) | awk '{ print substr($1,3,1) }')"
if [[ "$groupPermsNum" != "6" && "$groupPermsNum" != "7" ]]; then
    printf "! Group should have only read permissions.\\nView them with find /var/log -type f -ls\\n"
    results[index-1]="REQUIRES CHECKING"
    group=true
else
    group=false
fi
if [[ $group == false ]]; then
    printf "Group permissions - OK\\n"
    results[index-1]="OK"
fi

title="[4.2.4 Ensure permissions on all logfiles are configured (261)] [CASE 2 - Other permissions]"
titles[index++]="$title"
printf "\\n%s\\n\\n" "$title"
if [[ "$otherPermsNum" != "0" ]]; then
    printf "! Other users should have no permissions.\\nView them with find /var/log -type f -ls\\n"
    results[index-1]="REQUIRES CHECKING"
    other=true
else
    other=false
fi
if [[ $other == false ]]; then
    printf "Other users permissions - OK\\n"
    results[index-1]="OK"
fi

brLine


summary
