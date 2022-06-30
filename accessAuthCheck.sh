#!/bin/bash -
#title          :accessAuthCheck
#description    :This script checks the security of CentOS server's authentication, authorization and access, based on CIS_CentOS_Linux_7_Benchmark_v2.2.0.pdf's chapter 5.
#author         :Anttu Suhonen
#date           :20180604
#version        :1.0
#usage          :./accessAuthCheck.sh
#notes          :
#bash_version   :3.2.57(1)-release
#============================================================================

exec > /services/data/shared_resources/temp/logs/"$(hostname)"_accessAuthCheck_"$(date)".log
exec 2>&1

# Functions ------------->

# Usage: checkAccess <target>
function checkAccess {
    cmd="$(stat "$1" | grep -m 1 Access:)"
    printf "\\n[OUTPUT]:\\n%s\\n\\n" "$cmd"
    printf "Verify Uid and Gid are both 0/root.\\n\\n"
    getPermissions "$1"
}

# Usage: getPermissions <target>
function getPermissions {
    groupPermsNum="$(stat --format=%a "$1" | awk '{ print substr($1,2,1) }')"
    groupPerms="$(stat --format=%A "$1" | awk '{ print substr($1,5,3) }')"
    otherPermsNum="$(stat --format=%a "$1" | awk '{ print substr($1,3,1) }')"
    otherPerms="$(stat --format=%A "$1" | awk '{ print substr($1,8,3) }')"
    if [[ "$groupPermsNum" != "0" ]]; then
        printf "The group has too much permissions: (%s), should have no permissions.\\n" "$groupPerms"
        results[index-1]="NOT OK"
    else
        printf "Group permissions - OK\\n"
        results[index-1]="OK"
    fi
    if [[ "$otherPermsNum" != "0" ]]; then
        printf "Other users have too much permissions: (%s), should have no permissions.\\n" "$otherPerms"
        results[index-1]="NOT OK"
    else
        printf "Other users' permissions - OK\\n"
        results[index-1]="OK"
    fi
}

# Usage: checkParameter <paramName> <wantedParam> <destinationPath>
function checkParameter {
    cmd="$(grep "^.*$1" "$3")"
    if [[ -z "$cmd" ]]; then
        printf "\\nMissing %s at sshd_config.\\nEnsure that there is a parameter '%s %s' in $3.\\n" "$1" "$1" "$2"
        results[index-1]="NOT OK"
    else
        printf "\\n[OUTPUT]:\\n%s\\n\\n" "$cmd"
        printf "Ensure the %s parameter is uncommented and as follows: '%s %s'\\n" "$1" "$1" "$2"
        results[index-1]="REQUIRES CHECKING"
    fi
}

function brLine {
    printf "\\n--------------------\\n"
}

function sha512 {
    if [[ -z "$1" ]]; then
        printf "\\nsha512 NOT FOUND in %s. Ensure it is there.\\n" "$2"
        results[index-1]="NOT OK"
    else
        printf "\\nsha512 FOUND in %s - OK\\n" "$2"
        results[index-1]="OK"
    fi
}

userCount="$(grep -E '^[^:]+:[^\!*]' /etc/shadow | cut -d: -f1 | awk 'END{print NR}')"

# Usage: passwordMinDays <targetField> <targetText> <colNum>
function passwordMinDays {
    dayValue="$(grep "^$targetField" /etc/login.defs | awk '{print $2}')"
    if [[ $dayValue -lt 7 ]]; then
        printf "$targetField is %s. Set it to $targetNum or more at /etc/login.defs." "$dayValue"
    else
        printf "$targetField is %s - OK" "$dayValue"
    fi

    printf "\\n\\n[CASE 2]:\\n\\n"
    for (( i = 1; i < userCount + 1; i++ )); do
        user="$(grep -E '^[^:]+:[^\!*]' /etc/shadow | cut -d: -f1 | awk 'NR=='$i'{print $1}')"
        userDays="$(chage --list "$(grep -E '^[^:]+:[^\!*]' /etc/shadow | cut -d: -f1 | awk 'NR=='$i'{print $1}')" | grep "$targetText" | awk '{print $'"$colNum"'}')"
        printf "User:\\n%s\\n%s:\\n%s\\n" "$user" "$targetText" "$userDays"
        if [[ "$userDays" -lt $targetNum ]]; then
            printf "! %s is too SHORT. Set it to $targetNum or more.\\n\\n" "$targetText"
            results[index-1]="NOT OK"
        else
            printf "OK\\n\\n"
            results[index-1]="OK"
        fi
    done
}

function passwordMaxDays {
    dayValue="$(grep "^$targetField" /etc/login.defs | awk '{print $2}')"
    if [[ $dayValue -lt 7 ]]; then
        printf "$targetField is %s. Set it to $targetNum or less at /etc/login.defs." "$dayValue"
        results[index-1]="NOT OK"
    else
        printf "$targetField is %s - OK" "$dayValue"
        results[index-1]="OK"
    fi

    printf "\\n\\n[CASE 2]:\\n\\n"
    for (( i = 1; i < userCount + 1; i++ )); do
        user="$(grep -E '^[^:]+:[^\!*]' /etc/shadow | cut -d: -f1 | awk 'NR=='$i'{print $1}')"
        userDays="$(chage --list "$(grep -E '^[^:]+:[^\!*]' /etc/shadow | cut -d: -f1 | awk 'NR=='$i'{print $1}')" | grep "$targetText" | awk '{print $'"$colNum"'}')"
        printf "User:\\n%s\\n%s:\\n%s\\n" "$user" "$targetText" "$userDays"
        if [[ "$userDays" -gt $targetNum ]]; then
            printf "! %s is too LONG. Set it to $targetNum or less.\\n\\n" "$targetText"
            results[index-1]="NOT OK"
        else
            printf "OK\\n\\n"
            results[index-1]="OK"
        fi
    done
}

function summary {
    printf "\\n\\n-------------------- [SUMMARY - accessAuthCheck] --------------------\\n\\n"
    for (( i = 0; i < ${#titles[@]}; i++ )); do
        printf "%-75s - %s\\n\\n" "${titles[$i]}" "${results[$i]}"
    done
}

# End of functions -------------|

printf "\\nThis script checks the security of CentOS server's authentication, authorization and access, based on CIS_CentOS_Linux_7_Benchmark_v2.2.0.pdf's chapter 5.\\n\\n----------\\n"

index=0

# 5.1.1 Ensure cron daemon is enabled (264)
title="[5.1.1 Ensure cron daemon is enabled (264)]"
titles[index++]="$title"
printf "%s\\n\\n" "$title"
cmd="$(systemctl is-enabled crond)"
if [[ "$cmd" == "enabled" ]]; then
    printf "The cron daemon is %s - OK\\n" "$cmd"
    results[index-1]="OK"
else
    printf "The cron daemon is %s - Set it to enabled.\\n" "$cmd"
    results[index-1]="NOT OK"
fi
brLine

# 5.1.2 Ensure permissions on /etc/crontab are configured (265)
title="[5.1.2 Ensure permissions on /etc/crontab are configured (265)]"
titles[index++]="$title"
printf "%s\\n" "$title"
checkAccess /etc/crontab
brLine

# 5.1.3 Ensure permissions on /etc/cron.hourly are configured (266)
title="[5.1.3  Ensure permissions on /etc/cron.hourly are configured (266)]"
titles[index++]="$title"
printf "%s\\n" "$title"
checkAccess /etc/cron.hourly
brLine

# 5.1.4 Ensure permissions on /etc/cron.daily are configured (268)
title="[5.1.4 Ensure permissions on /etc/cron.daily are configured (268)]"
titles[index++]="$title"
printf "%s\\n" "$title"
checkAccess /etc/cron.daily
brLine

# 5.1.5 Ensure permissions on /etc/cron.weekly are configured (270)
title="[5.1.5 Ensure permissions on /etc/cron.weekly are configured (270)]"
titles[index++]="$title"
printf "%s\\n" "$title"
checkAccess /etc/cron.weekly
brLine

# 5.1.6 Ensure permissions on /etc/cron.monthly are configured (272)
title="[5.1.6 Ensure permissions on /etc/cron.monthly are configured (272)]"
titles[index++]="$title"
printf "%s\\n" "$title"
checkAccess /etc/cron.monthly
brLine

# 5.1.7 Ensure permissions on /etc/cron.d are configured (274)
title="[5.1.7 Ensure permissions on /etc/cron.d are configured (274)]"
titles[index++]="$title"
printf "%s\\n" "$title"
checkAccess /etc/cron.d
brLine

# 5.1.8 Ensure at/cron is restricted to authorized users (276)
title="[5.1.8 Ensure at/cron is restricted to authorized users (276)]"
titles[index++]="$title"
printf "%s\\n\\n" "$title"
if [[ ! -f /etc/cron.deny ]]; then
    printf "/etc/cron.deny NOT FOUND - OK\\n"
    results[index-1]="OK"
else
    printf "/etc/cron.deny EXISTS, please remove it.\\n"
    results[index-1]="NOT OK"
fi
printf "\\n"
if [[ ! -f /etc/at.deny ]]; then
    printf "/etc/at.deny NOT FOUND - OK\\n"
    results[index-1]="OK"
else
    printf "/etc/at.deny EXISTS, please remove it.\\n"
    results[index-1]="NOT OK"
fi
printf "\\n"
if [[ ! -f /etc/cron.allow ]]; then
    printf "cron.allow NOT FOUND. Please create it.\\n"
    results[index-1]=" NOT OK"
else
    checkAccess /etc/cron.allow
fi
printf "\\n"
if [[ ! -f /etc/at.allow ]]; then
    printf "at.allow NOT FOUND. Please create it.\\n"
    results[index-1]="NOT OK"
else
    checkAccess /etc/at.allow
fi
brLine

# 5.2.1 Ensure permissions on /etc/ssh/sshd_config are configured (278)
title="[5.2.1 Ensure permissions on '/etc/ssh/sshd_config' are configured (278)]"
titles[index++]="$title"
printf "%s\\n" "$title"
checkAccess /etc/ssh/sshd_config
brLine

# 5.2.2 Ensure SSH Protocol is set to 2 (280)
title="[5.2.2 Ensure SSH Protocol is set to 2 (280)]"
titles[index++]="$title"
printf "%s\\n" "$title"
checkParameter "Protocol" "2" /etc/ssh/sshd_config
brLine

# 5.2.3 Ensure SSH LogLevel is set to INFO (281)
title="[5.2.3 Ensure SSH LogLevel is set to INFO (281)]"
titles[index++]="$title"
printf "%s\\n" "$title"
checkParameter "LogLevel" "INFO" /etc/ssh/sshd_config
brLine

# 5.2.4 Ensure SSH X11 forwarding is disabled (282)
title="[5.2.4 Ensure SSH X11 forwarding is disabled (282)]"
titles[index++]="$title"
printf "%s\\n" "$title"
checkParameter "X11Forwarding" "no" /etc/ssh/sshd_config
brLine

# 5.2.5 Ensure SSH MaxAuthTries is set to 4 or less (283)
title="[5.2.5 Ensure SSH MaxAuthTries is set to 4 or less (283)]"
titles[index++]="$title"
printf "%s\\n" "$title"
checkParameter "MaxAuthTries" "4" /etc/ssh/sshd_config
brLine

# 5.2.6 Ensure SSH IgnoreRhosts is enabled (284)
title="[5.2.6 Ensure SSH IgnoreRhosts is enabled (284)]"
titles[index++]="$title"
printf "%s\\n" "$title"
checkParameter "IgnoreRhosts" "yes" /etc/ssh/sshd_config
brLine

# 5.2.7 Ensure SSH HostbasedAuthentication is disabled (285)
title="[5.2.7 Ensure SSH HostbasedAuthentication is disabled (285)]"
titles[index++]="$title"
printf "%s\\n" "$title"
checkParameter "HostbasedAuthentication" "no" /etc/ssh/sshd_config
brLine

# 5.2.8 Ensure SSH root login is disabled (286)
title="[5.2.8 Ensure SSH root login is disabled (286)]"
titles[index++]="$title"
printf "%s\\n" "$title"
checkParameter "PermitRootLogin" "no" /etc/ssh/sshd_config
brLine

# 5.2.9 Ensure SSH PermitEmptyPasswords is disabled (287)
title="[5.2.9 Ensure SSH PermitEmptyPasswords is disabled (287)]"
titles[index++]="$title"
printf "%s\\n" "$title"
checkParameter "PermitEmptyPasswords" "no" /etc/ssh/sshd_config
brLine

# 5.2.10 Ensure SSH PermitUserEnvironment is disabled (288)
title="[5.2.10 Ensure SSH PermitUserEnvironment is disabled (288)]"
titles[index++]="$title"
printf "%s\\n" "$title"
checkParameter "PermitUserEnvironment" "no" /etc/ssh/sshd_config
brLine

# 5.2.11 Ensure only approved MAC algorithms are used (289)
title="[5.2.11 Ensure only approved MAC algorithms are used (289)]"
titles[index++]="$title"
printf "%s\\n" "$title"
checkParameter "MACs" /etc/ssh/sshd_config
printf "Verify that output does not contain any unlisted MAC algorithms. Set them in accordance with site policy.\\n"
brLine

# 5.2.12 Ensure SSH Idle Timeout Interval is configured (291)
title="[5.2.12 Ensure SSH Idle Timeout Interval is configured (291)]"
titles[index++]="$title"
printf "%s\\n" "$title"
checkParameter "ClientAliveInterval" "300" /etc/ssh/sshd_config
printf "Set the interval according to site policy.\\n"
checkParameter "ClientAliveCountMax" "0" /etc/ssh/sshd_config
brLine

# 5.2.13 Ensure SSH LoginGraceTime is set to one minute or less (293)
title="[5.2.13 Ensure SSH LoginGraceTime is set to one minute or less (293)]"
titles[index++]="$title"
printf "%s\\n" "$title"
checkParameter "LoginGraceTime" "60" /etc/ssh/sshd_config
printf "Set the interval according to site policy.\\n"
brLine

# 5.2.14 Ensure SSH access is limited (294)
title="[5.2.14 Ensure SSH access is limited (294)]"
titles[index++]="$title"
printf "%s\\n\\n" "$title"
checkParameter "AllowUsers" "<userlist>" /etc/ssh/sshd_config
printf "\\n"
checkParameter "AllowGroups" "<grouplist>" /etc/ssh/sshd_config
printf "\\n"
checkParameter "DenyUsers" "<userlist>" /etc/ssh/sshd_config
printf "\\n"
checkParameter "DenyGroups" "<grouplist>" /etc/ssh/sshd_config
printf "\\nNote: Verify that output matches for at least one.\\n"
brLine

# 5.2.15 Ensure SSH warning banner is configured (296)
title="[5.2.15 Ensure SSH warning banner is configured (296)]"
titles[index++]="$title"
printf "%s\\n" "$title"
checkParameter "Banner" "<banner site address>" /etc/ssh/sshd_config
brLine

# 5.3.1 Ensure password creation requirements are configured (297)
title="[5.3.1 Ensure password creation requirements are configured (297)]"
titles[index++]="$title"
printf "%s\\n" "$title"
printf "\\npam_pwquality.so options:\\n"
grep pam_pwquality.so /etc/pam.d/password-auth
grep pam_pwquality.so /etc/pam.d/system-auth
printf "Output should be like: password requisite pam_pwquality.so try_first_pass retry=3\\n"

printf "\\nPassword must be 14 characters or more:"
checkParameter "minlen" "= 14" "/etc/security/pwquality.conf"
printf "\\nProvide at least one digit:"
checkParameter "dcredit" "= -1" "/etc/security/pwquality.conf"
printf "\\nProvide at least one uppercase character:"
checkParameter "ucredit" "= -1" "/etc/security/pwquality.conf"
printf "\\nProvide at least one special character:"
checkParameter "ocredit" "= -1" "/etc/security/pwquality.conf"
printf "\\nProvide at least one lowercase character:"
checkParameter "lcredit" "= -1" "/etc/security/pwquality.conf"
brLine

# 5.3.2 Ensure lockout for failed password attempts is configured (300)
title="[5.3.2 Ensure lockout for failed password attempts is configured (300)]"
titles[index++]="$title"
printf "%s\\n" "$title"
printf "\\n[CASE 1]\\nSystem-auth:\\n\\n[OUTPUT]:\\n"
grep "^auth" /etc/pam.d/system-auth
printf "\\n[CASE 2]\\nPassword-auth:\\n\\n[OUTPUT]:\\n"
grep "^auth" /etc/pam.d/password-auth
printf "\\nVerify the outputs are as follows:\\n"
printf "auth required pam_faillock.so preauth audit silent deny=5 unlock_time=900
auth [success=1 default=bad] pam_unix.so
auth [default=die] pam_faillock.so authfail audit deny=5 unlock_time=900
auth sufficient pam_faillock.so authsucc audit deny=5 unlock_time=900\\n"
results[index-1]="REQUIRES CHECKING"
brLine

# 5.3.3 Ensure password reuse is limited (302)
title="[5.3.3 Ensure password reuse is limited (302)]"
titles[index++]="$title"
printf "%s\\n" "$title"
cmd1="$(grep -E '^password\s+sufficient\s+pam_unix.so' /etc/pam.d/password-auth | grep remember)"
if [[ -z "$cmd1" ]]; then
    printf "\\nRemember element NOT FOUND. Add it to the /etc/pam.d/password-auth and set it to 5.\\n"
    results[index-1]="NOT OK"
else
    printf "\\nResult: %s\\n" "$cmd1"
    printf "Set the remember element to 5 (remember=5).\\n"
    results[index-1]="REQUIRES CHECKING"
fi
cmd2="$(grep -E '^password\s+sufficient\s+pam_unix.so' /etc/pam.d/system-auth | grep remember)"
if [[ -z "$cmd2" ]]; then
    printf "\\nRemember element NOT FOUND. Add it to the /etc/pam.d/system-auth and set it to 5.\\n"
    results[index-1]="NOT OK"
else
    printf "\\nResult: %s\\n" "$cmd2"
    printf "Set the remember element to 5 (remember=5).\\n"
    results[index-1]="REQUIRES CHECKING"
fi
brLine

# 5.3.4 Ensure password hashing algorithm is SHA-512 (304)
title="[5.3.4 Ensure password hashing algorithm is SHA-512 (304)]"
titles[index++]="$title"
printf "%s\\n" "$title"
cmd1="$(grep -E '^password\s+sufficient\s+pam_unix.so' /etc/pam.d/password-auth | grep sha512)"
cmd2="$(grep -E '^password\s+sufficient\s+pam_unix.so' /etc/pam.d/system-auth | grep sha512)"
sha512 "$cmd1" /etc/pam.d/password-auth
sha512 "$cmd2" /etc/pam.d/system-auth
brLine

# 5.4.1.1 Ensure password expiration is 365 days or less (306)
title="[5.4.1.1 Ensure password expiration is 365 days or less (306)]"
titles[index++]="$title"
printf "%s" "$title"
printf "\\n\\n[CASE 1]:\\n\\n"
targetField="PASS_MAX_DAYS"
targetText="Maximum number of days between password change"
colNum=9
targetNum=365
passwordMaxDays
brLine

# 5.4.1.2 Ensure minimum days between password changes is 7 or more (308)
title="[5.4.1.2 Ensure minimum days between password changes is 7 or more (308)]"
titles[index++]="$title"
printf "%s" "$title"
printf "\\n\\n[CASE 1]:\\n\\n"
targetField="PASS_MIN_DAYS"
targetText="Minimum number of days between password change"
colNum=9
targetNum=7
passwordMinDays
brLine

# 5.4.1.3 Ensure password expiration warning days is 7 or more (310)
title="[5.4.1.3 Ensure password expiration warning days is 7 or more (310)]"
titles[index++]="$title"
printf "%s" "$title"
printf "\\n\\n[CASE 1]:\\n\\n"
targetField="PASS_WARN_AGE"
targetText="Number of days of warning before password expires"
colNum=10
targetNum=7
passwordMinDays
brLine

# 5.4.1.4 Ensure inactive password lock is 30 days or less (312)
title="[5.4.1.4 Ensure inactive password lock is 30 days or less (312)]"
titles[index++]="$title"
printf "%s" "$title"
printf "\\n\\n[CASE 1]:\\n\\n"
targetField="INACTIVE"
targetText="Password inactive"
colNum=4
targetNum=30
dayValue="$(useradd -D | grep -Po 'INACTIVE=\K.\d')"
if [[ $dayValue -lt 7 ]]; then
    printf "%s is %s. Set it to %s or less." "$targetField" "$dayValue" "$targetNum"
    results[index-1]="NOT OK"
else
    printf "%s is %s - OK" "$targetField" "$dayValue"
    results[index-1]="OK"
fi

printf "\\n\\n[CASE 2]:\\n\\n"
for (( i = 1; i < userCount + 1; i++ )); do
    user="$(grep -E '^[^:]+:[^\!*]' /etc/shadow | cut -d: -f1 | awk 'NR=='$i'{print $1}')"
    userDays="$(chage --list "$(grep -E '^[^:]+:[^\!*]' /etc/shadow | cut -d: -f1 | awk 'NR=='$i'{print $1}')" | grep "$targetText" | awk '{print $'$colNum'}')"
    printf "User:\\n%s\\n%s:\\n%s\\n" "$user" "$targetText" "$userDays"
    if [[ "$userDays" -gt $targetNum ]]; then
        printf "! %s is too LONG. Set it to $targetNum or less.\\n\\n" "$targetText"
    else
        if [[ "$userDays" == "never" ]]; then
            printf "! %s value is set to 'never'. Set it to %s or less.\\n\\n" "$targetText" "$targetNum"
            results[index-1]="NOT OK"
        else
            printf "OK\\n\\n"
            results[index-1]="OK"
        fi
    fi
done
brLine

# 5.4.1.5 Ensure all users last password change date is in the past (314)
title="[5.4.1.5 Ensure all users last password change date is in the past (314)]"
titles[index++]="$title"
printf "%s\\n" "$title"
userCount="$(cat < /etc/shadow | cut -d: -f1 | awk 'END{print NR}')"
targetText="Last password change"
for (( i = 1; i < userCount + 1; i++ )); do
    user="$(cat < /etc/shadow | cut -d: -f1 | awk 'NR=='$i'{print $1}')"
    pwChangeDay="$(chage --list "$(cat < /etc/shadow | cut -d: -f1 | awk 'NR=='$i'{print $1}')" | grep "$targetText" | awk '{print $5, $6, $7}')"
    printf "\\nUser:\\n%s\\nLast password change:\\n%s\\n" "$user" "$pwChangeDay"
done
results[index-1]="REQUIRES CHECKING"
brLine

# 5.4.2 Ensure system accounts are non-login (315)
title="[5.4.2 Ensure system accounts are non-login (315)]"
titles[index++]="$title"
printf "%s" "$title"
printf "\\n\\n[OUTPUT]:\\n"
cmd="$(grep -E -v "^\\+" /etc/passwd | awk -F: '($1!="root" && $1!="sync" && $1!="shutdown" && $1!="halt" && $3<1000 && $7!="/sbin/nologin" && $7!="/bin/false") {print}')"
if [[ -z "$cmd" ]]; then
    printf "[No results] - OK\\n"
    results[index-1]="OK"
else
    printf "%s\\nThere are accounts that are not being used, while being able to use commands.\\n" "$cmd"
    results[index-1]="NOT OK"
fi
brLine

# 5.4.3 Ensure default group for the root account is GID 0 (317)
title="[5.4.3 Ensure default group for the root account is GID 0 (317)]"
titles[index++]="$title"
printf "%s\\n" "$title"
cmd="$(grep "^root:" /etc/passwd | cut -f4 -d:)"
if [[ "$cmd" == 0 ]]; then
    printf "GID for root is %s - OK\\n" "$cmd"
    results[index-1]="OK"
else
    printf "GID for root is %s. Set it to 0.\\n" "$cmd"
    results[index-1]="NOT OK"
fi
brLine

# 5.4.4 Ensure default user umask is 027 or more restrictive (318)
title="[5.4.4 Ensure default user umask is 027 or more restrictive (318)]"
titles[index++]="$title"
printf "%s" "$title"
printf "\\n\\n[CASE 1 - /etc/bashrc]:\\n"
cmd1="$(grep "  umask" /etc/bashrc | awk '{print $1, $2}')"
resNum1="$(grep "  umask" /etc/bashrc | awk 'END{print NR}')"
for (( i = 1; i < resNum1 + 1; i++ )); do
    cmd1a="$(grep "  umask" /etc/bashrc | awk 'NR=='$i'{print $2}')"
    if [[ "$cmd1a" != 027 ]]; then
        printf "%s\\nEnsure the returned value is 027 or more restrictive.\\n" "$cmd1a"
        results[index-1]="NOT OK"
    else
        printf "%s\\nOK\\n" "$cmd1a"
        results[index-1]="OK"
    fi
done
cmd2="$(grep "  umask" /etc/profile /etc/profile.d/*.sh | awk '{print $2, $3}')"
resNum2="$(grep "  umask" /etc/profile /etc/profile.d/*.sh | awk 'END{print NR}')"
printf "\\n[CASE 2 - /etc/profile /etc/profile.d/*.sh]\\n"
for (( i = 1; i < resNum2 + 1; i++ )); do
    cmd2a="$(grep "  umask" /etc/profile /etc/profile.d/*.sh | awk 'NR=='$i'{print $3}')"
    if [[ "$cmd2a" != 027 ]]; then
        printf "%s\\nEnsure the returned value is 027 or more restrictive.\\n" "$cmd2a"
        results[index-1]="NOT OK"
    else
        printf "%s\\nOK\\n" "$cmd2a"
        results[index-1]="OK"
    fi
done
brLine

# 5.6 Ensure access to the su command is restricted (323)
title="[5.6 Ensure access to the su command is restricted (323)]"
titles[index++]="$title"
printf "%s" "$title"
printf "\\n\\n[CASE 1]:\\n"
cmd1="$(grep pam_wheel.so /etc/pam.d/su)"
printf "%s\\n\\nEnsure the output includes the following: auth required pam_wheel.so use_uid\\n" "$cmd1"

cmd2="$(grep wheel /etc/group | awk 'BEGIN{FS=":"} ; {print $4}')"
printf "Ensure the following users in wheel group match site policy:\\n\\n%s\\n" "$cmd2"

results[index-1]="REQUIRES CHECKING"
brLine


summary
