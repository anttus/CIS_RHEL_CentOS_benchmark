#!/bin/bash -
#title          :MySQL
#description    :This script checks the hardening standards of MySql server, based on CIS_Oracle_MySQL_Community_Server_5.7_Benchmark_v1.0.0.pdf
#author         :Anttu Suhonen
#date           :20180529
#version        :1.0
#usage          :./mysql.sh
#============================================================================

exec > ./results/"$(hostname)"_CIS_mysql_"$(date +%d-%m-%Y)".log
exec 2>&1

# Functions ------------->

function loopThroughResults {
    mysqlCom=$(mysql -NBe "$1")
    printf "%-16s %s\\n" "User:" "Host:"
    if [[ -z $mysqlCom ]]; then
        printf "[Empty result]\\n"
    else
        mysql -NBe "$1" | while read -a row;
        do
            user="${row[0]}"
            host="${row[1]}"
            printf "%-16s %s\\n" "$user" "$host"
        done;
    fi
    brLine
    results[index-1]="REQUIRES CHECKING"
}

function brLine {
    printf "\\n--------------------\\n"
}

function printAdmin {
    printf "\\nEnsure all users returned are administrative users.\\n"
}

function summary {
    printf "\\n\\n-------------------- [SUMMARY - mysqlCheck] --------------------\\n\\n"
    for (( i = 0; i < ${#titles[@]}; i++ )); do
        printf "%-90s - %s\\n\\n" "${titles[$i]}" "${results[$i]}"
    done
}

# End of functions -------------|

printf "\\nThis script checks the hardening standards of MySql server, based on CIS_Oracle_MySQL_Community_Server_5.7_Benchmark_v1.0.0.pdf.\\n\\n"

pathDataDir="$(mysql -NBe "show variables where variable_name = 'datadir';" | awk '{print $2}')"
pathBinBasename="$(mysql -NBe "show variables like 'log_bin_basename';" | awk '{print $2}')"
pathErrorLog="$(mysql -NBe "show global variables like 'log_error';" | awk '{print $2}')"
pathQueryLog="$(mysql -NBe "show variables like 'slow_query_log_file';" | awk '{print $2}')"
pathGeneralLog="$(mysql -NBe "show variables like 'general_log_file';" | awk '{print $2}')"
pathPlugin="$(mysql -NBe "show variables where variable_name = 'plugin_dir';" | awk '{print $2}')"
pathMyConf="/var/lib/mysql/my.cnf"
pathSecureFile="$(mysql -NBe "SHOW GLOBAL VARIABLES WHERE Variable_name = 'secure_file_priv' AND Value<>'';" | awk '{print $2}')"

index=0

# 1.1 Place Databases on Non-System Partitions (12)
title="1.1 Place Databases on Non-System Partitions (12)]"
titles[index++]="$title"
printf "%s\\n\\n" "$title"
df -h $pathDataDir
printf "\\nThe output should not include root ('/'), \"/var\", or \"/usr\".\\n"
results[index-1]="REQUIRES CHECKING"
brLine

# 1.2 Use Dedicated Least Privileged Account for MySQL Daemon/Service (13)
title="1.2 Use Dedicated Least Privileged Account for MySQL Daemon/Service (13)]"
titles[index++]="$title"
printf "%s\\n\\n" "$title"
var="$(ps -ef | grep -E "^mysql.*$")"
if [[ -z "$var" ]]; then
    printf "This is a finding.\\n"
    results[index-1]="NOT OK"
else
    printf "[No results] - OK\\n"
    results[index-1]="OK"
fi
printf "\\nIf no lines are returned, then this is a finding.\\n"
brLine

# 1.4 Verify That the MYSQL_PWD Environment Variables Is Not In Use (15)
title="1.4 Verify That the MYSQL_PWD Environment Variables Is Not In Use (15)]"
titles[index++]="$title"
printf "%s\\n\\n" "$title"
printf "use the /proc filesystem to determine if MYSQL_PWD is currently set for any process\\n\\n[OUTPUT]:\\n"
var="$(grep MYSQL_PWD /proc/*/environ)"
if [[ -z "$var" ]]; then
    printf "[No output] - OK"
    results[index-1]="OK"
else
    grep MYSQL_PWD /proc/*/environ
    results[index-1]="NOT OK"
fi
printf "\\nThis may return one entry for the process which is executing the grep command.\\n"
brLine

# 1.6 Verify That 'MYSQL_PWD' Is Not Set In Users' Profiles (17)
title="1.6 Verify That 'MYSQL_PWD' Is Not Set In Users' Profiles (17)]"
titles[index++]="$title"
printf "%s\\n\\n" "$title"
printf "Check if MYSQL_PWD is set in login scripts.\\n\\n[OUTPUT]:\\n"
var="$(grep MYSQL_PWD /home/*/.{bashrc,bash_profile})"
if [[ -z "$var" ]]; then
    printf "[No output] - OK\\n"
    results[index-1]="OK"
else
    grep MYSQL_PWD /home/*/.{bashrc,bash_profile}
    results[index-1]="NOT OK"
fi
brLine

# 3.1 Ensure 'datadir' Has Appropriate Permissions (28)
title="3.1 Ensure 'datadir' Has Appropriate Permissions (28)]"
titles[index++]="$title"
printf "%s\\n\\n" "$title"
var="$(ls -la $pathDataDir.. | egrep "^d[r|w|x]{3}------\s*.\s*mysql\s*mysql\s*\d*.*mysql")"
if [[ -z "$var" ]]; then
    printf "[No results] - NOT OK\\n"
    results[index-1]="NOT OK"
else
    printf "%s\\n" "$var"
    results[index-1]="OK"
fi
printf "\\nVerify the permissions of %s are 700 and owner mysql:mysql\\n" "$pathDataDir"
brLine

# 3.2 Ensure 'log_bin_basename' Files Have Appropriate Permissions (29)
title="3.2 Ensure 'log_bin_basename' Files Have Appropriate Permissions (29)]"
titles[index++]="$title"
printf "%s\\n\\n" "$title"
ls -la $pathBinBasename
results[index-1]="REQUIRES CHECKING"
printf "\\nVerify the permissions of the files in %s are 660 and owner mysql:mysql\\n" "$pathBinBasename"
brLine

# 3.3 Ensure 'log_error' Has Appropriate Permissions (30)
title="3.3 Ensure 'log_error' Has Appropriate Permissions (30)]"
titles[index++]="$title"
printf "%s\\n\\n" "$title"
ls -la $pathErrorLog
results[index-1]="REQUIRES CHECKING"
printf "Verify the permissions of %s are 660 and owner mysql:mysql\\n" "$pathErrorLog"
brLine

# 3.4 Ensure 'slow_query_log' Has Appropriate Permissions (31)
title="3.4 Ensure 'slow_query_log' Has Appropriate Permissions (31)]"
titles[index++]="$title"
printf "%s\\n\\n" "$title"
ls -la $pathQueryLog
results[index-1]="REQUIRES CHECKING"
printf "\\nVerify the permissions of %s are 660 and owner mysql:mysql\\n" "$pathQueryLog"
brLine

# 3.5 Ensure 'relay_log_basename' Files Have Appropriate Permissions (32)
title="3.5 Ensure 'relay_log_basename' Files Have Appropriate Permissions (32)]"
titles[index++]="$title"
printf "%s\\n\\n" "$title"
query="SHOW variables LIKE 'relay_log_basename';"
cmd="$(mysql -NBe "$query" | awk '{print $2}')"
if [[ -z "$cmd" ]]; then
    printf "[Path not found]\\n"
    results[index-1]="NOT OK"
else
    ls -la "$cmd"
    printf "Verify permissions are 660 for mysql:mysql for each file of the form <relay_log_basename>\\n"
    results[index-1]="REQUIRES CHECKING"
fi
brLine

# 3.6 Ensure 'general_log_file' Has Appropriate Permissions (33)
title="3.6 Ensure 'general_log_file' Has Appropriate Permissions (33)]"
titles[index++]="$title"
printf "%s\\n\\n" "$title"
if [[ ! -f "$pathGeneralLog" ]]; then
    printf "Log file not found at %s\\n" "$pathGeneralLog"
    results[index-1]="NOT OK"
else
    ls -la $pathGeneralLog
    printf "Verify permissions are 660 for mysql:mysql for the indicated general_log_file.\\n"
    results[index-1]="REQUIRES CHECKING"
fi
brLine

# 3.7 Ensure SSL Key Files Have Appropriate Permissions (34)
title="3.7 Ensure SSL Key Files Have Appropriate Permissions (34)]"
titles[index++]="$title"
printf "%s\\n\\n" "$title"
query="SHOW variables WHERE variable_name = 'ssl_key';"
cmd="$(mysql -NBe "$query" | awk '{print $2}')"
if [[ -z "$cmd" ]]; then
    printf "[Path not found]\\n"
    results[index-1]="NOT OK"
else
    cmd2="$(ls -l "$cmd" | egrep "^-r--------[ \t]*.[ \t]*mysql[ \t]*mysql.*$")"
    if [[ -z "$cmd2" ]]; then
        printf "[No results]\\n"
        results[index-1]="NOT OK"
    else
        printf "Results:\\n%s" "$cmd2"
        printf "Set the permissions of the files to 400 and owner as mysql:mysql\\n"
        results[index-1]="REQUIRES CHECKING"
    fi
fi
brLine

# 3.8 Ensure Plugin Directory Has Appropriate Permissions (35)
title="3.8 Ensure Plugin Directory Has Appropriate Permissions (35)]"
titles[index++]="$title"
printf "%s\\n\\n" "$title"
var="$(ls -l $pathPlugin/.. | egrep "^drwxr[-w]xr[-w]x[ \t]*[0-9][ \t]*mysql[ \t]*mysql.*plugin.*$")"
if [[ -z "$var" ]]; then
    printf "Permissions are intended to be either 775 or 755 and the owner should be mysql:mysql.\\n"
    ls -la $pathPlugin
    results[index-1]="NOT OK"
else
    printf "Permissions in %s - OK\\n" "$pathPlugin"
    results[index-1]="OK"
fi
brLine

# 4.2 Ensure the 'test' Database Is Not Installed (37)
title="4.2 Ensure the 'test' Database Is Not Installed (37)]"
titles[index++]="$title"
printf "%s\\n\\n" "$title"
var="$(mysql -e "SHOW DATABASES LIKE 'test';")"
if [[ -z "$var" ]]; then
    printf "The test database does not exist - OK\\n"
    results[index-1]="OK"
else
    printf "Drop the test database.\\n"
    results[index-1]="NOT OK"
fi
brLine

# 4.4 Ensure 'local_infile' Is Disabled (39)
title="4.4 Ensure 'local_infile' Is Disabled (39)]"
titles[index++]="$title"
printf "%s\\n\\n" "$title"
var="$(mysql -ss -e "SHOW VARIABLES WHERE Variable_name = 'local_infile';" | sed 's/^[local_infile]*//;s/[local_infile]*$//')"
var=$(echo "$var")
printf "%s\\n\\n" "$var"
if [[ -z $var ]]; then
    printf "Variable local_infile not found.\\n"
else
    if [[ "$var" = "ON" ]]; then
        printf "Set the value of the field to OFF\\n"
        results[index-1]="NOT OK"
    elif [[ "$var" == "OFF" ]]; then
        printf "The field value is %s - OK" "$var"
        results[index-1]="OK"
    else
        printf "Check that the value of the field local_infile is OFF\\n"
        results[index-1]="REQUIRES CHECKING"
    fi
fi
brLine

# 4.5 Ensure 'mysqld' Is Not Started with '--skip-grant-tables' (40)
title="4.5 Ensure 'mysqld' Is Not Started with '--skip-grant-tables' (40)]"
titles[index++]="$title"
printf "%s\\n\\n" "$title"
var="$(grep skip-grant-tables $pathMyConf)"
if [[ -z "$var" ]]; then
    printf "skip-grant-tables not found in %s.\\nEnsure it is set to FALSE.\\n" "$pathMyConf"
    results[index-1]="REQUIRES CHECKING"
else
    cmd="$(grep skip-grant-tables $pathMyConf | awk '{print $3}')"
    if [[ "$cmd" == "FALSE" ]]; then
        printf "skip-grant-tables is %s - OK" "$cmd"
        results[index-1]="OK"
    else
        printf "skip-grant-tables is %s. Set it to FALSE.\\n" "$cmd"
        results[index-1]="NOT OK"
    fi
fi
brLine

# 4.6 Ensure '--skip-symbolic-links' Is Enabled (41)
title="4.6 Ensure '--skip-symbolic-links' Is Enabled (41)]"
titles[index++]="$title"
printf "%s\\n\\n" "$title"
var="$(mysql -ss -e "SHOW variables LIKE 'have_symlink';" | sed 's/^[have_symlink]*//;s/[have_symlink]*$//')"
var=$(echo "$var")
printf "%s\\n\\n" "$var"
if [[ -z $var ]]; then
    printf "Variable have_symlink not found.\\n"
else
    if [[ "$var" = "YES" ]]; then
        printf "Set the value of the field to DISABLED\\n"
        results[index-1]="NOT OK"
    elif [[ "$var" == "DISABLED" ]]; then
        printf "The value is %s - OK" "$var"
        results[index-1]="OK"
    else
        printf "Check that the value of the field local_infile is DISABLED\\n"
        results[index-1]="REQUIRES CHECKING"
    fi
fi
brLine

# 4.7 Ensure the 'daemon_memcached' Plugin Is Disabled (42)
title="4.7 Ensure the 'daemon_memcached' Plugin Is Disabled (42)]"
titles[index++]="$title"
printf "%s\\n\\n" "$title"
var="$(mysql -ss -e "SELECT * FROM information_schema.plugins WHERE PLUGIN_NAME='daemon_memcached';")"
if [[ -z "$var" ]]; then
    printf "[No output] - OK\\n"
    results[index-1]="OK"
else
    printf "Uninstall the daemon_memcached plugin\\n"
    results[index-1]="NOT OK"
fi
brLine

# 4.8 Ensure 'secure_file_priv' Is Not Empty (43)
title="4.8 Ensure 'secure_file_priv' Is Not Empty (43)]"
titles[index++]="$title"
printf "%s\\n\\n" "$title"
var="$(grep secure_file_priv /etc/mysql/my.cnf)"
if [[ -z "$var" ]]; then
    printf "Add secure_file_priv=%s to the [mysqld] section of /etc/mysql/my.cnf\\n" "$pathSecureFile"
    results[index-1]="NOT OK"
else
    printf "Ensure that there is secure_file_priv=%s line in [mysqld] section of /etc/mysql/my.cnf\\n" "$pathSecureFile"
    results[index-1]="REQUIRES CHECKING"
fi
brLine

# 5.1 Ensure Only Administrative Users Have Full Database Access (45)
title="5.1 Ensure Only Administrative Users Have Full Database Access (45)]"
titles[index++]="$title"
printf "%s\\n\\n" "$title"
printf "Results from mysql.user:\\n\\n"
query="SELECT user, host FROM mysql.user WHERE (Select_priv = 'Y') OR (Insert_priv = 'Y')  OR (Update_priv = 'Y')  OR (Delete_priv = 'Y')  OR (Create_priv = 'Y')  OR (Drop_priv = 'Y');"
loopThroughResults "$query"
printAdmin

printf "Results from mysql.db:\\n\\n"
query="SELECT user, host FROM mysql.db WHERE db = 'mysql' AND ((Select_priv = 'Y')  OR (Insert_priv = 'Y') OR (Update_priv = 'Y') OR (Delete_priv = 'Y')OR (Create_priv = 'Y') OR (Drop_priv = 'Y'));"
loopThroughResults "$query"
printAdmin

# 5.2 Ensure 'file_priv' Is Not Set to 'Y' for Non-Administrative Users (46)
title="5.2 Ensure 'file_priv' Is Not Set to 'Y' for Non-Administrative Users (46)]"
titles[index++]="$title"
printf "%s\\n\\n" "$title"
query="SELECT user, host FROM mysql.user WHERE File_priv = 'Y';"
loopThroughResults "$query"
printAdmin

# 5.4 Ensure 'super_priv' Is Not Set to 'Y' for Non-Administrative Users (48)
title="5.4 Ensure 'super_priv' Is Not Set to 'Y' for Non-Administrative Users (48)]"
titles[index++]="$title"
printf "%s\\n\\n" "$title"
query="SELECT user, host FROM mysql.user WHERE Super_priv = 'Y';"
loopThroughResults "$query"
printAdmin

# 5.5 Ensure 'shutdown_priv' Is Not Set to 'Y' for Non-Administrative Users (49)
title="5.5 Ensure 'shutdown_priv' Is Not Set to 'Y' for Non-Administrative Users (49)]"
titles[index++]="$title"
printf "%s\\n\\n" "$title"
query="SELECT user, host FROM mysql.user WHERE Shutdown_priv = 'Y';"
loopThroughResults "$query"
printAdmin

# 5.6 Ensure 'create_user_priv' Is Not Set to 'Y' for Non-Administrative Users (50)
title="5.6 Ensure 'create_user_priv' Is Not Set to 'Y' for Non-Administrative Users (50)]"
titles[index++]="$title"
printf "%s\\n\\n" "$title"
query="SELECT user, host FROM mysql.user WHERE Create_user_priv = 'Y';"
loopThroughResults "$query"
printAdmin

# 5.7 Ensure 'grant_priv' Is Not Set to 'Y' for Non-Administrative Users (51)
title="5.7 Ensure 'grant_priv' Is Not Set to 'Y' for Non-Administrative Users (51)]"
titles[index++]="$title"
printf "%s\\n\\n" "$title"
printf "Results from mysql.user:\\n\\n"
query="SELECT user, host FROM mysql.user WHERE Grant_priv = 'Y';"
loopThroughResults "$query"
printAdmin

printf "Results from mysql.db:\\n\\n"
query="SELECT user, host FROM mysql.db WHERE Grant_priv = 'Y';"
loopThroughResults "$query"
printAdmin

# 5.8 Ensure 'repl_slave_priv' Is Not Set to 'Y' for Non-Slave Users (52)
title="5.8 Ensure 'repl_slave_priv' Is Not Set to 'Y' for Non-Slave Users (52)]"
titles[index++]="$title"
printf "%s\\n\\n" "$title"
query="SELECT user, host FROM mysql.user WHERE Repl_slave_priv = 'Y';"
loopThroughResults "$query"
printf "\\nEnsure only accounts designated for slave users are granted this privilege.\\n"
brLine

# 5.9 Ensure DML/DDL Grants Are Limited to Specific Databases and Users (53)
title="5.9 Ensure DML/DDL Grants Are Limited to Specific Databases and Users (53)]"
titles[index++]="$title"
printf "%s\\n\\n" "$title"
query="SELECT user,host,db FROM mysql.db WHERE Select_priv='Y' OR Insert_priv='Y' OR Update_priv='Y' OR Delete_priv='Y' OR Create_priv='Y' OR Drop_priv='Y' OR Alter_priv='Y';"
mysqlCom=$(mysql -NBe "$query")
printf "%-16s %-16s %s\\n" "User:" "Host:" "Database:"
if [[ -z $mysqlCom ]]; then
    printf "[Empty result]\\n"
else
    mysql -NBe "$query" | while read -a row;
    do
        user="${row[0]}"
        host="${row[1]}"
        db="${row[2]}"
        printf "%-16s %-16s %s\\n" "$user" "$host" "$db"
    done;
fi
printf "\\nEnsure all users returned should have these privileges on the indicated databases.\\n"
results[index-1]="REQUIRES CHECKING"
brLine

# 6.1 Ensure 'log_error' Is Not Empty (54)
title="6.1 Ensure 'log_error' Is Not Empty (54)]"
titles[index++]="$title"
printf "%s\\n\\n" "$title"
var="$(mysql -ss -e "SHOW variables LIKE 'log_error';")"
var=$(echo "$var")
if [[ -z $var ]];then
    printf "log_error NOT FOUND.\\n"
    results[index-1]="NOT OK"
else
    printf "Returned value: %s\\n" "$var"
    results[index-1]="OK"
fi
brLine

# 6.2 Ensure Log Files Are Stored on a Non-System Partition (55)
title="6.2 Ensure Log Files Are Stored on a Non-System Partition (55)]"
titles[index++]="$title"
printf "%s\\n\\n" "$title"
var="$(mysql -ss -e "SELECT @@global.log_bin_basename;")"
var=$(echo "$var")
if [[ -z $var ]]; then
    printf "[No results]\\n"
     results[index-1]="NOT OK"
else
    printf "%s\\n" "$var"
    printf "Ensure the value returned does not indicate root ('/'), /var, or /usr.\\n"
    results[index-1]="REQUIRES CHECKING"
fi
brLine

# 6.5 Ensure 'log-raw' Is Set to 'OFF' (58)
title="6.5 Ensure 'log-raw' Is Set to 'OFF' (58)]"
titles[index++]="$title"
printf "%s\\n\\n" "$title"
var="$(grep log-raw /etc/mysql/my.cnf)"
var=$(echo "$var")
if [[ -z $var ]]; then
    printf "log-raw does not exist in my.cnf and it should be added.\\n"
    results[index-1]="NOT OK"
else
    var2=$(grep log-raw /etc/mysql/my.cnf | awk '{print $3}')
    if [[ "$var2" == "OFF" ]]; then
        printf "log-raw is OFF - OK\\n"
        results[index-1]="OK"
    else
        printf "log-raw is %s. Set it to OFF.\\n" "$var2"
        results[index-1]="NOT OK"
    fi
fi
brLine

# 7.1 Ensure Passwords Are Not Stored in the Global Configuration (59)
title="7.1 Ensure Passwords Are Not Stored in the Global Configuration (59)]"
titles[index++]="$title"
printf "%s\\n\\n" "$title"
var="$(grep password /etc/mysql/my.cnf)"
var=$(echo "$var")
printf "Verify the password option is not used in the global configuration file (my.cnf).\\n\\n[OUTPUT]:\\n"
if [[ -z $var ]]; then
    printf "password option is NOT used in my.cnf - OK\\n"
    results[index-1]="OK"
else
    printf "FOUND password option in my.cnf. Ensure it is removed from there.\\n"
    results[index-1]="NOT OK"
fi
brLine

# 7.2 Ensure 'sql_mode' Contains 'NO_AUTO_CREATE_USER' (60)
title="7.2 Ensure 'sql_mode' Contains 'NO_AUTO_CREATE_USER' (60)]"
titles[index++]="$title"
printf "%s\\n\\n" "$title"
query1="$(mysql -NBe "SELECT @@global.sql_mode;" | grep NO_AUTO_CREATE_USER)"
query2="$(mysql -NBe "SELECT @@session.sql_mode;" | grep NO_AUTO_CREATE_USER)"
if [[ -z "$query1" ]]; then
    printf "global.sql_mode does NOT contain NO_AUTO_CREATE_USER. Add it there.\\n"
    results[index-1]="NOT OK"
else
    printf "NO_AUTO_CREATE_USER found in global.sql_mode - OK\\n"
    results[index-1]="OK"
fi
if [[ -z "$query2" ]]; then
    printf "session.sql_mode does NOT contain NO_AUTO_CREATE_USER. Add it there.\\n"
    results[index-1]="NOT OK"
else
    printf "NO_AUTO_CREATE_USER found in session.sql_mode - OK\\n"
    results[index-1]="OK"
fi
brLine

# 7.3 Ensure Passwords Are Set for All MySQL Accounts (61)
title="7.3 Ensure Passwords Are Set for All MySQL Accounts (61)]"
titles[index++]="$title"
printf "%s\\n\\n" "$title"
query="SELECT user,host FROM mysql.user WHERE authentication_string='';"
result=$(mysql -NBe "$query")
if [[ -z "$result" ]]; then
    printf "[No results] - OK\\n"
    results[index-1]="OK"
else
    printf "%s\\n" "$result"
    printf "Set a password for the returned users.\\n"
    results[index-1]="NOT OK"
fi
brLine

# 7.4 Ensure 'default_password_lifetime' Is Less Than Or Equal To '90' (62)
title="7.4 Ensure 'default_password_lifetime' Is Less Than Or Equal To '90' (62)]"
titles[index++]="$title"
printf "%s\\n\\n" "$title"
query="SHOW VARIABLES LIKE 'default_password_lifetime';"
result=$(mysql -NBe "$query" | sed 's/^[default_password_lifetime]*//;s/[default_password_lifetime]*$//')
result=$(echo "$result")
if [[ $result -lt "90" && $result != "0" || $result == "90" ]]; then
    printf "The default password lifetime is: %s - OK\\n" "$result"
    results[index-1]="OK"
else
    printf "The default password lifetime is: %s\\nThe default_password_lifetime should be less than or equal to 90 (and not 0, 'never').\\n" "$result"
    results[index-1]="NOT OK"
fi
brLine

# 7.5 Ensure Password Complexity Is in Place (63)
title="7.5 Ensure Password Complexity Is in Place (63)] [CASE 1]"
titles[index++]="$title"
printf "%s\\n\\n" "$title"
mysql -e "SHOW VARIABLES LIKE 'validate_password%';"
printf "\\nThe output should be as follows:\\n\\n"
printf "validate_password_length should be 14 or more.\\n"
printf "validate_password_mixed_case_count should be 1 or more.\\n"
printf "validate_password_number_count should be 1 or more.\\n"
printf "validate_password_policy should be MEDIUM or STRONG.\\n"
printf "validate_password_special_char_count should be 1 or more.\\n\\n"

var="$(grep plugin-load /etc/mysql/my.cnf)"
if [[ -z "$var" ]]; then
    printf "Add the following to the global configuration at /etc/mysql/my.cnf: plugin-load=validate_password.so\\n"
fi
var="$(grep validate-password /etc/mysql/my.cnf)"
if [[ -z "$var" ]]; then
    printf "Add the following to the global configuration at /etc/mysql/my.cnf: validate-password=FORCE_PLUS_PERMANENT\\n"
fi
results[index-1]="REQUIRES CHECKING"

title="7.5 Ensure Password Complexity Is in Place (63)] [CASE 2]"
titles[index++]="$title"
printf "%s\\n\\n" "$title"
query="SELECT user,authentication_string,host FROM mysql.user WHERE authentication_string=CONCAT('*', UPPER(SHA1(UNHEX(SHA1(user)))));"
result="$(mysql -e "$query")"
printf "\\nChecking if users have a password which is identical to the username:\\n"
if [[ -z "$result" ]]; then
    printf "[No results] - OK\\n"
    results[index-1]="OK"
else
    printf "Change the passwords of the following users:\\n"
    mysql -e "SELECT user,authentication_string,host FROM mysql.user WHERE authentication_string=CONCAT('*', UPPER(SHA1(UNHEX(SHA1(user)))));"
    results[index-1]="NOT OK"
fi
brLine

# 7.6 Ensure No Users Have Wildcard Hostnames (64)
title="7.6 Ensure No Users Have Wildcard Hostnames (64)]"
titles[index++]="$title"
printf "%s\\n\\n" "$title"
query="SELECT user, host FROM mysql.user WHERE host = '%';"
result=$(mysql -e "$query")
if [[ -z "$result" ]]; then
    printf "[No results] - OK\\n"
    results[index-1]="OK"
else
    printf "%s\\n" "$result"
    printf "Avoid using wildcards within hostnames.\\n"
    results[index-1]="NOT OK"
fi
brLine

# 7.7 Ensure No Anonymous Accounts Exist (65)
title="7.7 Ensure No Anonymous Accounts Exist (65)]"
titles[index++]="$title"
printf "%s\\n\\n" "$title"
query="SELECT user,host FROM mysql.user WHERE user = '';"
result=$(mysql -e "$query")
if [[ -z "$result" ]]; then
    printf "[No results] - OK\\n"
    results[index-1]="OK"
else
    printf "There are anonymous accounts. Disable them.\\n"
    mysql -e "SELECT user,host FROM mysql.user WHERE user = '';"
    results[index-1]="NOT OK"
fi
brLine

# 8.1 Ensure 'have_ssl' Is Set to 'YES' (66)
title="8.1 Ensure 'have_ssl' Is Set to 'YES' (66)]"
titles[index++]="$title"
printf "%s\\n\\n" "$title"
query="SHOW variables WHERE variable_name = 'have_ssl';"
result=$(mysql -NBe "$query" | sed 's/^[have_ssl]*//;s/[have_ssl]*$//')
result=$(echo "$result")
if [[ "$result" == "YES" ]]; then
    printf "Result: have_ssl = %s - OK" "$result"
    results[index-1]="OK"
else
    printf "Result: have_ssl = %s\\n" "$result"
    printf "Ensure the have_ssl is set as YES.\\n"
    results[index-1]="NOT OK"
fi
brLine

# 8.2 Ensure 'ssl_type' Is Set to 'ANY', 'X509', or 'SPECIFIED' for All Remote Users (67)
title="8.2 Ensure 'ssl_type' Is Set to 'ANY', 'X509', or 'SPECIFIED' for All Remote Users (67)]"
titles[index++]="$title"
printf "%s\\n\\n" "$title"
query="SELECT user,host,ssl_type FROM mysql.user WHERE NOT HOST IN ('::1', '127.0.0.1', 'localhost');"
result=$(mysql -NBe "$query")
printf "%-16s %-16s %s\\n" "User:" "Host:" "Ssl_type:"
if [[ -z $result ]]; then
    printf "[Empty result]\\n"
else
    mysql -NBe "$query" | while read -a row;
    do
        user="${row[0]}"
        host="${row[1]}"
        ssl_type="${row[2]}"
        printf "%-16s %-16s %s\\n" "$user" "$host" "$ssl_type"
    done;
fi
printf "\\nEnsure the ssl_type for each user returned is equal to ANY, X509, or SPECIFIED.\\n"
results[index-1]="REQUIRES CHECKING"
brLine

# 9.1 Ensure Replication Traffic Is Secured (Not Scored) (69)
title="9.1 Ensure Replication Traffic Is Secured (Not Scored) (69)]\\n"
results[index-1]="KIND OF OK"
brLine

# 9.2 Ensure 'MASTER_SSL_VERIFY_SERVER_CERT' Is Set to 'YES' or '1' (69)
title="9.2 Ensure 'MASTER_SSL_VERIFY_SERVER_CERT' Is Set to 'YES' or '1' (69)]"
titles[index++]="$title"
printf "%s\\n\\n" "$title"
query="SELECT ssl_verify_server_cert FROM mysql.slave_master_info;"
result=$(mysql -NBe "$query")
if [[ -z "$result" ]]; then
    printf "[No results]\\n"
else
    printf "Result: %s\\nEnsure the value of ssl_verify_server_cert is 1" "$result"
fi
results[index-1]="REQUIRES CHECKING"
brLine

# 9.4 Ensure 'super_priv' Is Not Set to 'Y' for Replication Users (72)
title="9.4 Ensure 'super_priv' Is Not Set to 'Y' for Replication Users (72)]"
titles[index++]="$title"
printf "%s\\n\\n" "$title"
query="SELECT user, host FROM mysql.user WHERE user='replication' AND Super_priv = 'Y';"
result=$(mysql -NBe "$query")
if [[ -z "$result" ]]; then
    printf "[No results] - OK\\n"
    results[index-1]="OK"
else
    printf "Result: %s\\nLimit the account's privileges.\\n" "$result"
    results[index-1]="NOT OK"
fi
brLine

# 9.5 Ensure No Replication Users Have Wildcard Hostnames (73)
title="9.5 Ensure No Replication Users Have Wildcard Hostnames (73)]"
titles[index++]="$title"
printf "%s\\n\\n" "$title"
query="SELECT user, host FROM mysql.user WHERE user='replication' AND host = '%';"
result=$(mysql -NBe "$query")
if [[ -z "$result" ]]; then
    printf "[No results] - OK\\n"
    results[index-1]="OK"
else
    printf "%s\\n" "$result"
    printf "Avoid using wildcards within hostnames.\\n"
    results[index-1]="NOT OK"
fi
brLine


summary
