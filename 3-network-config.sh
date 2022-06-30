#!/bin/bash -
#title          :3. Networking configuration
#description    :This script does checks on different networking configurations, based on CIS CentOS / RHEL 7 benchmark chapter 3
#author         :Anttu Suhonen
#date           :20180524
#version        :1.0
#usage          :./3-network-config.sh
#============================================================================

exec > ./results/"$(hostname)"_CIS_networking_"$(date +%d-%m-%Y)".log
exec 2>&1

# Functions ------------->

# Usage: verifyMatches <wantedResult>
function verifyMatches {
    if [[ "$output" == "$1" ]]; then
        printf "%s - OK\\n" "$output"
        results[index-1]="OK"
    else
        printf "Wanted output: %s\\nResult output: %s\\n" "$1" "$output"
        results[index-1]="NOT OK"
    fi
}

function brLine {
    printf "\\n--------------------\\n\\n"
}

function summary {
    printf "\\n\\n-------------------- [SUMMARY - networkingConfigCheck] --------------------\\n\\n"
    for (( i = 0; i < ${#titles[@]}; i++ )); do
        printf "%-75s - %s\\n" "${titles[$i]}" "${results[$i]}"
    done
}

# Usage: getPermissions <targetPath> <targetPermission>
function checkPermissions {
    perms="$( stat --format=%a "$1")"
    if [[ "$perms" == "$2" ]]; then
        printf "Permissions for %s - OK\\n" "$1"
        results[index-1]="OK"
    else
        printf "%s's permissions need checking.\\n" "$1"
        results[index-1]="NOT OK"
    fi
}
# End of functions -------------|

printf "This script does checks on different networking configurations, based on CIS_CentOS_Linux_7_Benchmark_v2.2.0's chapter 3.\\n\\n"

index=0

# 3.1.1 Ensure IP forwarding is disabled (151)
title="[3.1.1 Ensure IP forwarding is disabled (151)] [CASE 1]:"
titles[index++]="$title"
printf "%s\\n\\n" "$title"
output="$(sysctl net.ipv4.ip_forward)"
verifyMatches "net.ipv4.ip_forward = 0"

title="[3.1.1 Ensure IP forwarding is disabled (151)] [CASE 2]:"
titles[index++]="$title"
printf "%s\\n\\n" "$title"
output="$(grep \"net.ipv4.ip_forward\" /etc/sysctl.conf /etc/sysctl.d/*)"
verifyMatches "net.ipv4.ip_forward = 0"
brLine

# 3.1.2 Ensure packet redirect sending is disabled (153)
title="[3.1.2 Ensure packet redirect sending is disabled (153)] [CASE 1]:"
titles[index++]="$title"
printf "%s\\n\\n" "$title"
output="$(sysctl net.ipv4.conf.all.send_redirects)"
verifyMatches "net.ipv4.conf.all.send_redirects = 0"

title="[3.1.2 Ensure packet redirect sending is disabled (153)] [CASE 2]:"
titles[index++]="$title"
printf "\\n%s\\n\\n" "$title"
output="$(sysctl net.ipv4.conf.default.send_redirects)"
verifyMatches "net.ipv4.conf.default.send_redirects = 0"

title="[3.1.2 Ensure packet redirect sending is disabled (153)] [CASE 3]:"
titles[index++]="$title"
printf "\\n%s\\n\\n" "$title"
output="$(grep \"net.ipv4.conf.all.send_redirects\" /etc/sysctl.conf /etc/sysctl.d/*)"
verifyMatches "net.ipv4.conf.all.send_redirects = 0"

title="[3.1.2 Ensure packet redirect sending is disabled (153)] [CASE 4]:"
titles[index++]="$title"
printf "\\n%s\\n\\n" "$title"
output="grep \"net.ipv4.conf.default.send_redirects\" /etc/sysctl.conf /etc/sysctl.d/*"
verifyMatches "net.ipv4.conf.default.send_redirects= 0"
brLine

# 3.2.1 Ensure source routed packets are not accepted (155)
title="[3.2.1 Ensure source routed packets are not accepted (155)] [CASE 1]"
titles[index++]="$title"
printf "%s\\n\\n" "$title"
output="$(sysctl net.ipv4.conf.all.accept_source_route)"
verifyMatches "net.ipv4.conf.all.accept_source_route = 0"

title="[3.2.1 Ensure source routed packets are not accepted (155)] [CASE 2]"
titles[index++]="$title"
printf "\\n%s\\n\\n" "$title"
output="$(sysctl net.ipv4.conf.default.accept_source_route)"
verifyMatches net.ipv4.conf.default.accept_source_route = 0

title="[3.2.1 Ensure source routed packets are not accepted (155)] [CASE 3]"
titles[index++]="$title"
printf "\\n%s\\n\\n" "$title"
output="grep \"net.ipv4.conf.all.accept_source_route\" /etc/sysctl.conf /etc/sysctl.d/*"
verifyMatches "net.ipv4.conf.all.accept_source_route= 0"

title="[3.2.1 Ensure source routed packets are not accepted (155)] [CASE 4]"
titles[index++]="$title"
printf "\\n%s\\n\\n" "$title"
output="$(grep \"net.ipv4.conf.default.accept_source_route\" /etc/sysctl.conf /etc/sysctl.d/*)"
verifyMatches "net.ipv4.conf.default.accept_source_route= 0"
brLine

# 3.2.2 Ensure ICMP redirects are not accepted (157)
title="[3.2.2 Ensure ICMP redirects are not accepted (157)] [CASE 1]:"
titles[index++]="$title"
printf "%s\\n\\n" "$title"
output="$(sysctl net.ipv4.conf.all.accept_redirects)"
verifyMatches "net.ipv4.conf.all.accept_redirects = 0"

title="[3.2.2 Ensure ICMP redirects are not accepted (157)] [CASE 2]:"
titles[index++]="$title"
printf "\\n%s\\n\\n" "$title"
output="$(sysctl net.ipv4.conf.default.accept_redirects)"
verifyMatches "net.ipv4.conf.default.accept_redirects = 0"

title="[3.2.2 Ensure ICMP redirects are not accepted (157)] [CASE 3]:"
titles[index++]="$title"
printf "\\n%s\\n\\n" "$title"
output="$(grep \"net.ipv4.conf.all.accept_redirects\" /etc/sysctl.conf /etc/sysctl.d/*)"
verifyMatches "net.ipv4.conf.all.accept_redirects= 0"

title="[3.2.2 Ensure ICMP redirects are not accepted (157)] [CASE 4]:"
titles[index++]="$title"
printf "\\n%s\\n\\n" "$title"
output="$(grep \"net.ipv4.conf.default.accept_redirects\" /etc/sysctl.conf /etc/sysctl.d/*)"
verifyMatches "net.ipv4.conf.default.accept_redirects = 0"
brLine

# 3.2.3 Ensure secure ICMP redirects are not accepted (159)
title="[3.2.3 Ensure secure ICMP redirects are not accepted (159)] [CASE 1]"
titles[index++]="$title"
printf "%s\\n\\n" "$title"
output="$(sysctl net.ipv4.conf.all.secure_redirects)"
verifyMatches "net.ipv4.conf.all.secure_redirects = 0"

title="[3.2.3 Ensure secure ICMP redirects are not accepted (159)] [CASE 2]"
titles[index++]="$title"
printf "\\n%s\\n\\n" "$title"
output="$(sysctl net.ipv4.conf.default.secure_redirects)"
verifyMatches "net.ipv4.conf.default.secure_redirects = 0"

title="[3.2.3 Ensure secure ICMP redirects are not accepted (159)] [CASE 3]"
titles[index++]="$title"
printf "\\n%s\\n\\n" "$title"
output="$(grep \"net.ipv4.conf.all.secure_redirects\" /etc/sysctl.conf /etc/sysctl.d/*)"
verifyMatches "net.ipv4.conf.all.secure_redirects= 0"

title="[3.2.3 Ensure secure ICMP redirects are not accepted (159)] [CASE 3]"
titles[index++]="$title"
printf "\\n%s\\n\\n" "$title"
output="$(grep \"net.ipv4.con.default.secure_redirects\" /etc/sysctl.conf /etc/sysctl.d/*)"
verifyMatches "net.ipv4.conf.default.secure_redirects= 0"
brLine

# 3.2.4 Ensure suspicious packets are logged (161)
title="[3.2.4 Ensure suspicious packets are logged (161)] [CASE 1]"
titles[index++]="$title"
printf "%s\\n\\n" "$title"
output="$(sysctl net.ipv4.conf.all.log_martians)"
verifyMatches "net.ipv4.conf.all.log_martians = 1"

title="[3.2.4 Ensure suspicious packets are logged (161)] [CASE 2]"
titles[index++]="$title"
printf "\\n%s\\n\\n" "$title"
output="$(sysctl net.ipv4.conf.default.log_martians)"
verifyMatches "net.ipv4.conf.default.log_martians = 1"

title="[3.2.4 Ensure suspicious packets are logged (161)] [CASE 3]"
titles[index++]="$title"
printf "\\n%s\\n\\n" "$title"
output="$(grep \"net.ipv4.conf.all.log_martians\" /etc/sysctl.conf /etc/sysctl.d/*)"
verifyMatches "net.ipv4.conf.all.log_martians = 1"

title="[3.2.4 Ensure suspicious packets are logged (161)] [CASE 4]"
titles[index++]="$title"
printf "\\n%s\\n\\n" "$title"
output="$(grep \"net.ipv4.conf.default.log_martians\" /etc/sysctl.conf /etc/sysctl.d/*)"
verifyMatches "net.ipv4.conf.default.log_martians = 1"
brLine

# 3.2.5 Ensure broadcast ICMP requests are ignored (163)
title="[3.2.5 Ensure broadcast ICMP requests are ignored (163) ] [CASE 1]"
titles[index++]="$title"
printf "%s\\n\\n" "$title"
output="$(sysctl net.ipv4.icmp_echo_ignore_broadcasts)"
verifyMatches "net.ipv4.icmp_echo_ignore_broadcasts = 1"

title="[3.2.5 Ensure broadcast ICMP requests are ignored (163) ] [CASE 2]"
titles[index++]="$title"
printf "\\n%s\\n\\n" "$title"
output="$(grep \"net.ipv4.icmp_echo_ignore_broadcasts\" /etc/sysctl.conf /etc/sysctl.d/*)"
verifyMatches "net.ipv4.icmp_echo_ignore_broadcasts = 1"
brLine

# 3.2.6 Ensure bogus ICMP responses are ignored (165)
printf "[3.2.6 Ensure bogus ICMP responses are ignored (165)] [CASE 1]"
titles[index++]="$title"
printf "%s\\n\\n" "$title"
output="$(sysctl net.ipv4.icmp_ignore_bogus_error_responses)"
verifyMatches "net.ipv4.icmp_ignore_bogus_error_responses = 1"

printf "[3.2.6 Ensure bogus ICMP responses are ignored (165)] [CASE 2]"
titles[index++]="$title"
printf "\\n%s\\n\\n" "$title"
output="$(grep \"net.ipv4.icmp_ignore_bogus_error_responses\" /etc/sysctl.conf /etc/sysctl.d/*)"
verifyMatches "net.ipv4.icmp_ignore_bogus_error_responses = 1"
brLine

# 3.2.7 Ensure Reverse Path Filtering is enabled (167)
printf "[3.2.7 Ensure Reverse Path Filtering is enabled (167)] [CASE 1]"
titles[index++]="$title"
printf "%s\\n\\n" "$title"
output="$(sysctl net.ipv4.conf.all.rp_filter)"
verifyMatches "net.ipv4.conf.all.rp_filter = 1"

printf "[3.2.7 Ensure Reverse Path Filtering is enabled (167)] [CASE 2]:"
titles[index++]="$title"
printf "\\n%s\\n\\n" "$title"
output="$(sysctl net.ipv4.conf.default.rp_filter)"
verifyMatches "net.ipv4.conf.default.rp_filter = 1"

printf "[3.2.7 Ensure Reverse Path Filtering is enabled (167)] [CASE 3]:"
titles[index++]="$title"
printf "\\n%s\\n\\n" "$title"
output="$(grep \"net.ipv4.conf.all.rp_filter\" /etc/sysctl.conf /etc/sysctl.d/*)"
verifyMatches "net.ipv4.conf.all.rp_filter = 1"

printf "[3.2.7 Ensure Reverse Path Filtering is enabled (167)] [CASE 4]"
titles[index++]="$title"
printf "\\n%s\\n\\n" "$title"
output="$(grep \"net.ipv4.conf.default.rp_filter\" /etc/sysctl.conf /etc/sysctl.d/*)"
verifyMatches "net.ipv4.conf.default.rp_filter = 1"
brLine

# 3.2.8 Ensure TCP SYN Cookies is enabled (169)
printf "[3.2.8 Ensure TCP SYN Cookies is enabled (169)] [CASE 1]"
titles[index++]="$title"
printf "%s\\n\\n" "$title"
output="$(sysctl net.ipv4.tcp_syncookies)"
verifyMatches "net.ipv4.tcp_syncookies = 1"

printf "[3.2.8 Ensure TCP SYN Cookies is enabled (169)] [CASE 2]"
titles[index++]="$title"
printf "\\n%s\\n\\n" "$title"
output="$(grep \"net.ipv4.tcp_syncookies\" /etc/sysctl.conf /etc/sysctl.d/*)"
verifyMatches "net.ipv4.tcp_syncookies = 1"
brLine

# 3.4.1 Ensure TCP Wrappers is installed (177)
title="[3.4.1 Ensure TCP Wrappers is installed (177)] [CASE 1]"
titles[index++]="$title"
printf "%s\\n\\n" "$title"
if rpm -qa tcp_wrappers 2>&1 ; then
    printf "tcp_wrappers is installed - OK\\n"
    results[index-1]="OK"
else
    printf "tcp_wrappers is NOT installed\\n"
    results[index-1]="NOT OK"
fi

title="[3.4.1 Ensure libwrap.so is installed (177)] [CASE 2]"
titles[index++]="$title"
printf "\\n%s\\n\\n" "$title"
if rpm -qa tcp_wrappers-libs 2>&1 ; then
    printf "libwrap.so is installed - OK\\n"
    results[index-1]="OK"
else
    printf "libwrap.so is NOT installed\\n"
    results[index-1]="NOT OK"
fi
brLine

# 3.4.2 Ensure /etc/hosts.allow is configured (179)
title="[3.4.2 Ensure /etc/hosts.allow is configured (179)]"
titles[index++]="$title"
printf "%s\\n\\n" "$title"
printf "Verify the contents of the /etc/hosts.allow file:\\n\\n[OUTPUT]:\\n"
cat /etc/hosts.allow
results[index-1]="REQUIRES CHECKING"
brLine

# 3.4.3 Ensure /etc/hosts.deny is configured (180)
title="[3.4.3 Ensure /etc/hosts.deny is configured (180)]"
titles[index++]="$title"
printf "%s\\n\\n" "$title"
printf "Verify the contents of the /etc/hosts.deny file:\\n\\n[OUTPUT]:\\n"
cat /etc/hosts.deny
results[index-1]="REQUIRES CHECKING"
brLine

# 3.4.4 Ensure permissions on /etc/hosts.allow are configured (181)
title="[3.4.4 Ensure permissions on /etc/hosts.allow are configured (181)]"
titles[index++]="$title"
printf "%s\\n\\n" "$title"
printf "Verify Uid and Gid are both 0/root and Access is 644:\\n\\n[OUTPUT]:\\n"
checkPermissions /etc/hosts.allow 644
brLine

# 3.4.5 Ensure permissions on /etc/hosts.deny are configured (182)
title="[3.4.5 Ensure permissions on /etc/hosts.deny are configured (182)]"
titles[index++]="$title"
printf "%s\\n\\n" "$title"
printf "Verify Uid and Gid are both 0/root and Access is 644:\\n\\n[OUTPUT]:\\n"
checkPermissions /etc/hosts.allow 644
brLine

# 3.6.1 Ensure iptables is installed (188)
title="[3.6.1 Ensure iptables is installed (188)]"
titles[index++]="$title"
printf "%s\\n\\n" "$title"
if rpm -qa iptables 2>&1 ; then
    printf "iptables is installed - OK\\n"
    results[index-1]="OK"
else
    printf "iptables is NOT installed\\n"
    results[index-1]="NOT OK"
fi
brLine

# 3.6.2 Ensure default deny firewall policy (190)
title="[3.6.2 Ensure default deny firewall policy (190)]"
titles[index++]="$title"
printf "%s\\n\\n" "$title"
printf "Verify that the policy for the INPUT, OUTPUT, and FORWARD chains is DROP or REJECT:\\n\\n[RESULTS]:\\n\\n"
iptables -L
results[index-1]="REQUIRES CHECKING"
brLine

# 3.6.3 Ensure loopback traffic is configured (192)
title="[3.6.3 Ensure loopback traffic is configured (192)]"
titles[index++]="$title"
printf "%s\\n\\n" "$title"
printf "Verify output includes the listed rules in order (packet and byte counts may differ):\\n\\n[EXAMPLE IN]:\\n"
printf "Chain INPUT (policy DROP 0 packets, 0 bytes)\\n"
printf "pkts\\tbytes\\ttarget\\tprot\\topt\\tin\\tout\\tsource\\t\\tdestination\\n"
printf "0\\t0\\tACCEPT\\tall\\t--\\tlo\\t*\\t0.0.0.0/0\\t0.0.0.0/0\\n"
printf "0\\t0\\tDROP\\tall\\t--\\t*\\t*\\t127.0.0.0/8\\t0.0.0.0/0\\n"
printf "\\n[OUTPUT]:\\n"
iptables -L INPUT -v -n
printf "\\n[EXAMPLE OUT]:"
printf "\\nChain OUTPUT (policy DROP 0 packets, 0 bytes)\\n"
printf "pkts\\tbytes\\ttarget\\tprot\\topt\\tin\\tout\\tsource\\t\\tdestination\\n"
printf "0\\t0\\tACCEPT\\tall\\t--\\t*\\tlo\\t0.0.0.0/0\\t0.0.0.0/0\\n"
printf "\\n[OUTPUT]:\\n"
iptables -L OUTPUT -v -n
results[index-1]="REQUIRES CHECKING"
brLine

# 3.6.5 Ensure firewall rules exist for all open ports (196)
title="[3.6.5 Ensure firewall rules exist for all open ports (196)]"
titles[index++]="$title"
printf "%s\\n\\n" "$title"
printf "Determine open ports:\\n\\n[OUTPUT]:\\n"
netstat -ln
printf "\\nDetermine firewall rules:\\n\\n[OUTPUT]:\\n"
iptables -L INPUT -v -n
printf "\\nVerify all open ports listening on non-localhost addresses have at least one firewall rule."
results[index-1]="REQUIRES CHECKING"
brLine


summary
