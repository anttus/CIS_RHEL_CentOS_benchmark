#!/bin/bash -
#title          :Tomcat
#description    :This script checks the hardening standards of tomcat server, based on CIS_Apache_Tomcat_8_Benchmark_v1.0.1.pdf
#author         :Anttu Suhonen
#date           :20180529
#version        :1.0
#usage          :./tomcat.sh
#============================================================================

exec > ./results/"$(hostname)"_CIS_tomcat_"$(date +%d-%m-%Y)".log
exec 2>&1

# Functions ------------->
function brLine {
    printf "\\n--------------------\\n"
}

function summary {
    printf "\\n\\n-------------------- [SUMMARY - tomcatCheck] --------------------\\n\\n"
    for (( i = 0; i < ${#titles[@]}; i++ )); do
        printf "%-80s - %s\\n\\n" "${titles[$i]}" "${results[$i]}"
    done
}
# End of functions -------------|

printf "\\nThis script checks the hardening standards of tomcat server, based on CIS_Apache_Tomcat_8_Benchmark_v1.0.1.pdf.\\n\\n"

pathServicesWebXml="/services/tomcat/conf/web.xml"
pathProcountorWebXml="/services/tomcat/webapps/.../WEB-INF/web.xml"
pathProcountorContextXml="/services/tomcat/webapps/.../META-INF/context.xml"
pathServiceServerXml="/services/tomcat/conf/server.xml"
pathServiceTomcat="/services/tomcat"
pathServiceTomcatConf="/services/tomcat/conf"
pathServiceTomcatLogs="/services/tomcat/logs"
pathServiceTomcatTemp="/services/tomcat/temp"
pathServiceTomcatBin="/services/tomcat/bin"
pathServiceTomcatWebapps="/services/tomcat/webapps"
pathWebInfClasses="/services/tomcat/webapps/.../WEB-INF/classes/"
pathServiceTomcatMangerWebXml="/services/tomcat/apache-tomcat-8.5.31/webapps/manager/WEB-INF/web.xml"

index=0

# 2.5 Disable client facing Stack Traces (22)
printf "[2.5 Disable client facing Stack Traces (22)]\\n"

title="[2.5 Disable client facing Stack Traces (22)] [CASE 1]"
titles[index++]="$title"
printf "[CASE 1] Ensure an <error-page> element is defined in \$CATALINA_HOME/conf/web.xml. ($pathServicesWebXml and $pathProcountorWebXml)\\n"
var1="$(grep -r '<error-page>' $pathServicesWebXml | sed 's/.*<error-page>\(.*\)<\/error-page>.*/\1/')"
var1=`echo $var1`
if [[ "$var1" = *"<error-page>"* ]]; then
    printf "Element <error-page> FOUND in $pathServicesWebXml\\n"
    results[index-1]="OK"
else
    printf "Element NOT FOUND in $pathServicesWebXml\\n";
    results[index-1]="NOT OK"
fi
varb1="$(grep -r '<error-page>' $pathProcountorWebXml | sed 's/.*<error-page>\(.*\)<\/error-page>.*/\1/')"
varb1=`echo $varb1`
if [[ "$varb1" = *"<error-page>"* ]]; then
    printf "Element <error-page> FOUND in $pathProcountorWebXml\\n"
    results[index-1]="OK"
else
    printf "Element NOT FOUND in $pathProcountorWebXml\\n";
    results[index-1]="NOT OK"
fi

title="[2.5 Disable client facing Stack Traces (22)] [CASE 2]"
titles[index++]="$title"
printf "[CASE 2] Ensure the <error-page> element has an <exception-type> child element with a value of java.lang.Throwable.\\n"
var2="$(grep -r '<exception-type>' $pathServicesWebXml | sed 's/.*<exception-type>\(.*\)<\/exception-type>.*/\1/')"
var2=`echo $var2`
if [[ "$var2" = *"java.lang.Throwable"* ]]; then
    printf "FOUND child element <exception-type> with value of java.lang.Throwable in $pathServicesWebXml \\n"
    results[index-1]="OK"
else
    printf "Element NOT FOUND in $pathServicesWebXml\\n"
    results[index-1]="NOT OK"
fi
varb2="$(grep -r '<exception-type>' $pathProcountorWebXml | sed 's/.*<exception-type>\(.*\)<\/exception-type>.*/\1/')"
varb2=`echo $varb2`
if [[ "$varb2" = *"java.lang.Throwable"* ]]; then
    printf "FOUND child element <exception-type> with value of java.lang.Throwable in $pathProcountorWebXml\\n"
    results[index-1]="OK"
else
    printf "Element NOT FOUND in $pathProcountorWebXml\\n"
    results[index-1]="NOT OK"
fi

title="[2.5 Disable client facing Stack Traces (22)] [CASE 3]"
titles[index++]="$title"
printf "[CASE 3] Ensure the <error-page> element has a <location> child element.\\n"
var3="$(grep -r '<location>' $pathServicesWebXml | sed 's/.*<location>\(.*\)<\/location>.*/\1/')"
var3=`echo $var3`
if [ "$var3" != "" ]; then
    printf "Element <location> FOUND in $pathServicesWebXml\\n"
    results[index-1]="OK"
else
    printf "Element NOT FOUND in $pathServicesWebXml\\n"
    results[index-1]="NOT OK"
fi
varb3="$(grep -r '<location>' $pathProcountorWebXml | sed 's/.*<location>\(.*\)<\/location>.*/\1/')"
varb3=`echo $varb3`
if [ "$varb3" != "" ]; then
    printf "Element <location> FOUND in $pathProcountorWebXml\\n"
    results[index-1]="OK"
else
    printf "Element NOT FOUND in $pathProcountorWebXml\\n"
    results[index-1]="NOT OK"
fi

printf "\\nNote: Perform the above for each application hosted within Tomcat.
Per application instances of web.xml can be found at \$CATALINA_HOME/webapps/<APP_NAME>/WEB-INF/web.xml\\n"
brLine

# 2.6 Turn off TRACE (24)
printf "[2.6 Turn off TRACE (24)]\\n"

title="[2.6 Turn off TRACE (24)] [CASE 1]"
titles[index++]="$title"
printf "[CASE 1] Locate all Connector elements in \$CATALINA_HOME/conf/server.xml.\\n"
printf "\\nIn $pathServiceServerXml\\n"
grep -nr '<Connector ' $pathServiceServerXml
results[index-1]="REQUIRES CHECKING"

title="[2.6 Turn off TRACE (24)] [CASE 1]"
titles[index++]="$title"
printf "[CASE 2] Ensure each Connector does not have a allowTrace attribute or if the allowTrace attribute is not set true.\\n"
var4="$(sed -rn 's/.*allowTrace="([^"]*)".*/\1/p' $pathServiceServerXml)"
var4=`echo $var4`
if [ "$var4" = "true" ]; then
    printf "Connector allowTrace is TRUE in $pathServiceServerXml \\n"
    results[index-1]="NOT OK"
else
    printf "allowTrace is not set in Connector or it is FALSE - OK\\n"
    results[index-1]="OK"
fi

printf "\\nNote: Perform the above for each application hosted within Tomcat.
Per application instances of web.xml can be found at \$CATALINA_HOME/webapps/<APP_NAME>/WEBINF/web.xml\\n"
brLine

# 3.1 Set a nondeterministic Shutdown command value (26)
title="[3.1 Set a nondeterministic Shutdown command value (26)]"
titles[index++]="$title"
printf "%s\\n\\n" "$title"
var5="$(sed -rn 's/.*shutdown="([^"]*)".*/\1/p' $pathServiceServerXml)"
var5=`echo $var5`
if [ "$var5" = "SHUTDOWN" ]; then
    printf "Shutdown attribute is SHUTDOWN. Change it to a nondeterministic value.\\n"
    results[index-1]="NOT OK"
else
    printf "Shutdown attribute - OK.\\n"
    results[index-1]="OK"
fi
brLine

# 4.1 Restrict access to $CATALINA_HOME (29)
title="[4.1 Restrict access to \$CATALINA_HOME (29)]"
titles[index++]="$title"
printf "%s\\n\\n" "$title"
var6="$(find $pathServiceTomcat -follow -maxdepth 0 \( -perm /o+rwx,g=w -o ! -user tomcat -o ! -group tomcat \) -ls)"
var6=`echo $var6`
if [ "$var6" = "" ]; then
    printf "Permissions in $pathServiceTomcat - OK\\n"
    results[index-1]="OK"
else
    results[index-1]="NOT OK"
    printf "Check the permissions of $pathServiceTomcat\\n"
    find $pathServiceTomcat -follow -maxdepth 0 \( -perm /o+rwx,g=w -o ! -user tomcat -o ! -group tomcat \) -ls
    printf "1. Set the ownership of the \$CATALINA_HOME to tomcat:tomcat.\\n2. Remove read, write, and execute permissions for the world\\n3. Remove write permissions for the group.\\n"
fi
brLine

# 4.2 Restrict access to $CATALINA_BASE (31)
title="[4.2 Restrict access to \$CATALINA_BASE (31)]"
titles[index++]="$title"
printf "%s\\n\\n" "$title"
find $CATALINA_BASE -follow -maxdepth 0 \( -perm /o+rwx,g=w -o ! -user tomcat -o ! -group tomcat \) -ls
results[index-1]="REQUIRES CHECKING"
brLine

# 4.3 Restrict access to Tomcat configuration directory (32)
title="[4.3 Restrict access to Tomcat configuration directory (32)]"
titles[index++]="$title"
printf "%s\\n\\n" "$title"
var7="$(find $pathServiceTomcatConf -maxdepth 0 \( -perm /o+rwx,g=w -o ! -user tomcat -o ! -group tomcat \) -ls)"
var7=`echo $var7`
if [ "$var7" = "" ]; then
    printf "Permissions in $pathServiceTomcatConf - OK\\n"
    results[index-1]="OK"
else
    results[index-1]="NOT OK"
    printf "Check the permissions of $pathServiceTomcatConf\\n"
    find $pathServiceTomcatConf -maxdepth 0 \( -perm /o+rwx,g=w -o ! -user tomcat -o ! -group tomcat \) -ls
    printf "1. Set the ownership of the \$CATALINA_HOME/conf to tomcat_admin:tomcat.\\n2. Remove read, write, and execute permissions for the world\\n3. Remove write permissions for the group.\\n"
fi
brLine

# 4.4 Restrict access to Tomcat logs directory (34)
title="[4.4 Restrict access to Tomcat logs directory (34)]"
titles[index++]="$title"
printf "%s\\n\\n" "$title"
var8="$(find $pathServiceTomcatLogs -follow -maxdepth 0 \( -perm /o+rwx -o ! -user tomcat -o ! -group tomcat \) -ls)"
var8=`echo $var8`
if [ "$var8" = "" ]; then
    printf "Permissions in $pathServiceTomcatLogs OK\\n"
    results[index-1]="OK"
else
    results[index-1]="NOT OK"
    printf "Check the permissions of $pathServiceTomcatLogs\\n"
    find $pathServiceTomcatLogs -follow -maxdepth 0 \( -perm /o+rwx -o ! -user tomcat -o ! -group tomcat \) -ls
    printf "1. Set the ownership of the \$CATALINA_HOME/logs to tomcat:tomcat.\\n2. Remove read, write, and execute permissions for the world\\n"
fi
brLine

# 4.5 Restrict access to Tomcat temp directory (35)
title="[4.5 Restrict access to Tomcat temp directory (35)]"
titles[index++]="$title"
printf "%s\\n\\n" "$title"
var9="$(find $pathServiceTomcatTemp -follow -maxdepth 0 \( -perm /o+rwx -o ! -user tomcat -o ! -group tomcat \) -ls)"
var9=`echo $var9`
if [ "$var9" = "" ]; then
    printf "Permissions in $pathServiceTomcatTemp - OK\\n"
    results[index-1]="OK"
else
    results[index-1]="NOT OK"
    printf "Check the permissions of $pathServiceTomcatTemp\\n"
    find $pathServiceTomcatTemp -follow -maxdepth 0 \( -perm /o+rwx -o ! -user tomcat -o ! -group tomcat \) -ls
    printf "1. Set the ownership of the $CATALINA_HOME/logs to tomcat_admin:tomcat.\\n2. Remove read, write, and execute permissions for the world\\n"
fi
brLine

# 4.6 Restrict access to Tomcat binaries directory (36)
title="[4.6 Restrict access to Tomcat binaries directory (36)]"
titles[index++]="$title"
printf "%s\\n\\n" "$title"
var10="$(find $pathServiceTomcatBin -follow -maxdepth 0 \( -perm /o+rwx,g=w -o ! -user tomcat -o ! -group tomcat \) -ls)"
var10=`echo $var10`
if [ "$var10" = "" ]; then
    printf "Permissions in $pathServiceTomcatBin - OK\\n"
    results[index-1]="OK"
else
    results[index-1]="NOT OK"
    printf "Check the permissions of $pathServiceTomcatBin\\n"
    find $pathServiceTomcatBin -follow -maxdepth 0 \( -perm /o+rwx,g=w -o ! -user tomcat -o ! -group tomcat \) -ls
    printf "1. Set the ownership of the \$CATALINA_HOME/bin to tomcat_admin:tomcat.\\n2. Remove read, write, and execute permissions for the world.\\n"
fi
brLine

# 4.7 Restrict access to Tomcat web application directory (37)
title="[4.7 Restrict access to Tomcat web application directory (37)]"
titles[index++]="$title"
printf "%s\\n\\n" "$title"
var11="$(find $pathServiceTomcatWebapps -follow -maxdepth 0 \( -perm /o+rwx,g=w -o ! -user tomcat -o ! -group tomcat \) -ls)"
var11=`echo $var11`
if [ "$var11" = "" ]; then
    printf "Permissions in $pathServiceTomcatWebapps - OK\\n"
    results[index-1]="OK"
else
    results[index-1]="NOT OK"
    printf "Check the permissions of $pathServiceTomcatWebapps\\n"
    find $pathServiceTomcatWebapps -follow -maxdepth 0 \( -perm /o+rwx,g=w -o ! -user tomcat -o ! -group tomcat \) -ls
    printf "1. Set the ownership of the \$CATALINA_HOME/webapps to tomcat:tomcat.\\n2. Remove read, write, and execute permissions for the world.\\n"
fi
brLine

# 4.8 Restrict access to Tomcat catalina.policy (39)
title="[4.8 Restrict access to Tomcat catalina.policy (39)]"
titles[index++]="$title"
printf "%s\\n\\n" "$title"
var12="$(find $pathServiceTomcatConf/catalina.policy -follow -maxdepth 0 \( -perm /o+rwx -o ! -user tomcat -o ! -group tomcat \) -ls)"
var12=`echo $var12`
if [ "$var12" = "" ]; then
    printf "Permissions in $pathServiceTomcatConf/catalina.policy - OK\\n"
    results[index-1]="OK"
else
    results[index-1]="NOT OK"
    printf "Check the permissions of $pathServiceTomcatConf/catalina.policy\\n"
    find $pathServiceTomcatConf/catalina.policy -follow -maxdepth 0 \( -perm /o+rwx -o ! -user tomcat -o ! -group tomcat \) -ls
    printf "Set the owner and group owner of the contents of \$CATALINA_HOME/conf/catalina.policy to tomcat_admin and tomcat, respectively.\\n"
fi
brLine

# 4.9 Restrict access to Tomcat catalina.properties (40)
title="[4.9 Restrict access to Tomcat catalina.properties (40)]"
titles[index++]="$title"
printf "%s\\n\\n" "$title"
var13="$(find $pathServiceTomcatConf/catalina.properties -follow -maxdepth 0 \( -perm /o+rwx,g=w -o ! -user tomcat -o ! -group tomcat \) -ls)"
var13=`echo $var13`
if [ "$var13" = "" ]; then
    printf "Permissions in $pathServiceTomcatConf/catalina.properties - OK\\n"
    results[index-1]="OK"
else
    results[index-1]="NOT OK"
    printf "Check the permissions of $pathServiceTomcatConf/catalina.properties\\n"
    find $pathServiceTomcatConf/catalina.properties -follow -maxdepth 0 \( -perm /o+rwx,g=w -o ! -user tomcat -o ! -group tomcat \) -ls
    printf "1. Set the ownership of the \$CATALINA_HOME/conf/catalina.properties to tomcat_admin:tomcat.\\n2. Remove read, write, and execute permissions for the world.\\n3. Remove write permissions for the group.\\n"
fi
brLine

# 4.10 Restrict access to Tomcat context.xml (42)
title="[4.10 Restrict access to Tomcat context.xml (42)]"
titles[index++]="$title"
printf "%s\\n\\n" "$title"
var14="$(find $pathServiceTomcatConf/context.xml -follow -maxdepth 0 \( -perm /o+rwx,g=w -o ! -user tomcat -o ! -group tomcat \) -ls)"
var14=`echo $var14`
if [ "$var14" = "" ]; then
    printf "Permissions in $pathServiceTomcatConf/context.xml OK\\n"
    results[index-1]="OK"
else
    results[index-1]="NOT OK"
    printf "Check the permissions of $pathServiceTomcatConf/context.xml\\n"
    find $pathServiceTomcatConf/context.xml -follow -maxdepth 0 \( -perm /o+rwx,g=w -o ! -user tomcat -o ! -group tomcat \) -ls
    printf "1. Set the ownership of the \$CATALINA_HOME/conf/context.xml to tomcat_admin:tomcat.\\n2. Remove read, write, and execute permissions for the world.\\n3. Remove write permissions for the group.\\n"
fi
brLine

# 4.11 Restrict access to Tomcat logging.properties (44)
title="[4.11 Restrict access to Tomcat logging.properties (44)]"
titles[index++]="$title"
printf "%s\\n\\n" "$title"
var15="$(find $pathServiceTomcatConf/logging.properties -follow -maxdepth 0 \( -perm /o+rwx,g=w -o ! -user tomcat -o ! -group tomcat \) -ls)"
var15=`echo $var15`
if [ "$var15" = "" ]; then
    printf "Permissions in $pathServiceTomcatConf/logging.properties OK\\n"
    results[index-1]="OK"
else
    results[index-1]="NOT OK"
    printf "Check the permissions of $pathServiceTomcatConf/logging.properties\\n"
    find $pathServiceTomcatConf/logging.properties -follow -maxdepth 0 \( -perm /o+rwx,g=w -o ! -user tomcat -o ! -group tomcat \) -ls
    printf "1. Set the ownership of the \$CATALINA_HOME/conf/logging.properties to tomcat_admin:tomcat.\\n2. Remove read, write, and execute permissions for the world.\\n3. Remove write permissions for the group.\\n"
fi
brLine

# 4.12 Restrict access to Tomcat server.xml (46)
title="[4.12 Restrict access to Tomcat server.xml (46)]"
titles[index++]="$title"
printf "%s\\n\\n" "$title"
var16="$(find $pathServiceTomcatConf/server.xml -follow -maxdepth 0 \( -perm /o+rwx,g=w -o ! -user tomcat -o ! -group tomcat \) -ls)"
var16=`echo $var16`
if [ "$var16" = "" ]; then
    printf "Permissions in $pathServiceTomcatConf/server.xml OK\\n"
    results[index-1]="OK"
else
    results[index-1]="NOT OK"
    printf "Check the permissions of $pathServiceTomcatConf/server.xml\\n"
    find $pathServiceTomcatConf/server.xml -follow -maxdepth 0 \( -perm /o+rwx,g=w -o ! -user tomcat -o ! -group tomcat \) -ls
    printf "1. Set the ownership of the \$CATALINA_HOME/conf/server.xml to tomcat_admin:tomcat.\\n2. Remove read, write, and execute permissions for the world.\\n3. Remove write permissions for the group.\\n"
fi
brLine

# 4.13 Restrict access to Tomcat tomcat-users.xml (48)
title="[4.13 Restrict access to Tomcat tomcat-users.xml (48)]"
titles[index++]="$title"
printf "%s\\n\\n" "$title"
find $pathServiceTomcatConf/tomcat-users.xml -follow -maxdepth 0 \( -perm /o+rwx,g=w -o ! -user tomcat -o ! -group tomcat \) -ls
var17="$(find $pathServiceTomcatConf/tomcat-users.xml -follow -maxdepth 0 \( -perm /o+rwx,g=w -o ! -user tomcat -o ! -group tomcat \) -ls)"
var17=`echo $var17`
if [ "$var17" = "" ]; then
    printf "Permissions in $pathServiceTomcatConf/tomcat-users.xml OK\\n"
    results[index-1]="OK"
else
    results[index-1]="NOT OK"
    printf "Check the permissions of $pathServiceTomcatConf/tomcat-users.xml\\n"
    find $pathServiceTomcatConf/tomcat-users.xml -follow -maxdepth 0 \( -perm /o+rwx,g=w -o ! -user tomcat -o ! -group tomcat \) -ls
    printf "1. Set the ownership of the \$CATALINA_HOME/conf/tomcat-users.xml to tomcat_admin:tomcat.\\n2. Remove read, write, and execute permissions for the world.\\n3. Remove write permissions for the group.\\n"
fi
brLine

# 4.14 Restrict access to Tomcat web.xml (50)
title="[4.14 Restrict access to Tomcat web.xml (50)]"
titles[index++]="$title"
printf "%s\\n\\n" "$title"
var18="$(find $pathServiceTomcatConf/web.xml -follow -maxdepth 0 \( -perm /o+rwx,g=w -o ! -user tomcat -o ! -group tomcat \) -ls)"
var18=`echo $var18`
if [ "$var18" = "" ]; then
    printf "Permissions in $pathServiceTomcatConf/web.xml OK\\n"
    results[index-1]="OK"
else
    results[index-1]="NOT OK"
    printf "Check the permissions of $pathServiceTomcatConf/web.xml\\n"
    find $pathServiceTomcatConf/web.xml -follow -maxdepth 0 \( -perm /o+rwx,g=w -o ! -user tomcat -o ! -group tomcat \) -ls
    printf "1. Set the ownership of the \$CATALINA_HOME/conf/web.xml to tomcat_admin:tomcat.\\n2. Remove read, write, and execute permissions for the world.\\n3. Remove write permissions for the group.\\n"
fi
brLine

# 6.2 Ensure SSLEnabled is set to True for Sensitive Connectors (54, not scored)
title="[6.2 Ensure SSLEnabled is set to True for Sensitive Connectors (54, not scored)]"
titles[index++]="$title"
printf "%s\\n\\n" "$title"
var19="$(sed -rn 's/.*SSLEnabled="([^"]*)".*/\1/p' $pathServiceServerXml)"
var19=`echo $var19`
if [ "$var19" = "true" ]; then
    printf "SSLEnabled is TRUE in $pathServiceServerXml - OK\\n"
    results[index-1]="OK"
else
    results[index-1]="NOT OK"
    printf "SSLEnabled is FALSE or not set in $pathServiceServerXml\\n"
fi
brLine

# 6.3 Ensure scheme is set accurately (55)
title="[6.3 Ensure scheme is set accurately (55)]"
titles[index++]="$title"
printf "%s\\n\\n" "$title"
var20="$(sed -rn 's/.*scheme="([^"]*)".*/\1/p' $pathServiceServerXml)"
var20=`echo $var20`
if [ "$var20" = "https" ]; then
    printf "Scheme is HTTPS in Connector at $pathServiceServerXml - OK\\n"
    results[index-1]="OK"
else
    results[index-1]="NOT OK"
    printf "Scheme is NOT HTTPS in Connector at $pathServiceServerXml\\n"
fi
brLine

# 6.4 Ensure secure is set to true only for SSL-enabled Connectors (56)
title="[6.4 Ensure secure is set to true only for SSL-enabled Connectors (56)]"
titles[index++]="$title"
printf "%s\\n\\n" "$title"
var21="$(sed -rn 's/.*secure="([^"]*)".*/\1/p' $pathServiceServerXml)"
var21=`echo $var21`
if [ "$var19" = "true" ]; then
    if [ "$var21" != "true" ]; then
        printf "Set the secure element in Connector to true\\n"
        results[index-1]="NOT OK"
    else
        printf "Secure element and SSLEnabled are TRUE in Connector - OK\\n"
        results[index-1]="OK"
    fi
fi
if [ "$var19" = "false" ]; then
    if [ "$var21" = "true" ]; then
        printf "Set the secure element in Connector to false\\n"
        results[index-1]="NOT OK"
    else
        printf "Secure element and SSLEnabled are FALSE in Connector\\n"
        results[index-1]="OK"
    fi
fi
brLine

# 6.5 Ensure SSL Protocol is set to TLS for Secure Connectors (57)
title="[6.5 Ensure SSL Protocol is set to TLS for Secure Connectors (57)]"
titles[index++]="$title"
printf "%s\\n\\n" "$title"
var22="$(sed -rn 's/.*sslProtocol="([^"]*)".*/\1/p' $pathServiceServerXml)"
var22=`echo $var22`
if [ "$var19" = "true" ]; then
    if [ "$var22" = "TLS" ]; then
        printf "SSLProtocol is set as TLS in Connector at $pathServiceServerXml - OK\\n"
        results[index-1]="OK"
    else
        results[index-1]="NOT OK"
        printf "SSLProtocol is NOT set as TLS in Connector at $pathServiceServerXml. Please set it to TLS.\\n"
    fi
fi
if [ "$var19" = "false" ]; then
    printf "Check the SSLEnabled element\\n"
    results[index-1]="REQUIRES CHECKING"
fi
brLine

# 7.2 Specify file handler in logging.properties files (59)
title="[7.2 Specify file handler in logging.properties files (59)]"
titles[index++]="$title"
printf "%s\\n\\n" "$title"
printf "Review each applications logging.properties file located in the applications \$CATALINA_BASE\webapps\<app name>\WEB-INF\classes
directory and determine if the file handler properties are set:\\n\\n[OUTPUT]:\\n"
if [ -e "$pathWebInfClasses/logging.properties" ]; then
    grep handlers $pathWebInfClasses/logging.properties
else
    grep handlers $pathServiceTomcatConf/logging.properties
fi
results[index-1]="REQUIRES CHECKING"
brLine

# 7.4 Ensure directory in context.xml is a secure location (61)
title="[7.4 Ensure directory in context.xml is a secure location (61)]"
titles[index++]="$title"
printf "%s\\n\\n" "$title"
printf "Ensure context.xml permissions are o-rwx and it is owned by tomcat:tomcat.\\n\\n[OUTPUT]:\\n"
grep directory $pathServiceTomcatConf/context.xml
ls -ld $pathServiceTomcatConf/context.xml
results[index-1]="REQUIRES CHECKING"
brLine

# 7.5 Ensure pattern in context.xml is correct (62)
title="[7.5 Ensure pattern in context.xml is correct (62)]"
titles[index++]="$title"
printf "%s\\n\\n" "$title"
printf "Check the pattern for \$CATALINA_BASE/webapps/<app-name>/META-INF/context.xml with 'grep pattern'\\n"
printf "Testing for /services/tomcat/conf/context.xml:\\n"
grep pattern $pathServiceTomcatConf/context.xml
results[index-1]="REQUIRES CHECKING"
brLine

# 7.6 Ensure directory in logging.properties is a secure location (63)
title="[7.6 Ensure directory in logging.properties is a secure location (63)]"
titles[index++]="$title"
printf "%s\\n\\n" "$title"
printf "Review the permissions of the directory specified by the directory setting to ensure the permissions are o-rwx and owned by tomcat:tomcat:\\n\\n[OUTPUT]:\\n"
if [ -e "$pathWebInfClasses/logging.properties" ]; then
    grep directory $pathWebInfClasses/logging.properties
    printf "\\nPermissions: \\n"
    ls -ld $pathWebInfClasses/logging.properties
else
    grep directory $pathServiceTomcatConf/logging.properties
    printf "\\nPermissions: \\n"
    ls -ld $pathServiceTomcatConf/logging.properties
fi
results[index-1]="REQUIRES CHECKING"
brLine

# 8.1 Restrict runtime access to sensitive packages (65)
title="[8.1 Restrict runtime access to sensitive packages (65)]"
titles[index++]="$title"
printf "%s\\n\\n" "$title"
printf "Review package.access list in \$CATALINA_BASE/conf/catalina.properties to ensure only allowed packages are defined.\\n\\n[OUTPUT]:\\n"
grep "^[^#;]" $pathServiceTomcatConf/catalina.properties
results[index-1]="REQUIRES CHECKING"
brLine

# 9.1 Starting Tomcat with Security Manager (66)
title="[9.1 Starting Tomcat with Security Manager (66)]"
titles[index++]="$title"
printf "%s\\n\\n" "$title"
printf "Review the startup configuration in /etc/init.d for Tomcat to ascertain if Tomcat is started with the -security option:\\n"
results[index-1]="REQUIRES CHECKING"
brLine

# 10.4 Force SSL when accessing the manager application (72)
title="[10.4 Force SSL when accessing the manager application (72)]"
titles[index++]="$title"
printf "%s\\n\\n" "$title"
printf "Ensure \$CATALINA_HOME/webapps/manager/WEB-INF/web.xml has the <transport- guarantee> attribute set to CONFIDENTIAL:\\n\\n[OUTPUT]:\\n"
var23="$(grep transport-guarantee $pathServiceTomcatMangerWebXml)"
if [ -z "$var23" ]; then
    printf "Element transport-gurarantee NOT FOUND in $pathServiceTomcatMangerWebXml.\\n"
else
    grep transport-guarantee $pathServiceTomcatMangerWebXml
fi
results[index-1]="REQUIRES CHECKING"
brLine

# 10.6 Enable strict servlet Compliance (75)
title="[10.6 Enable strict servlet Compliance (75)]"
titles[index++]="$title"
printf "%s\\n\\n" "$title"
printf "Ensure the above parameter is added to the startup script which by default is located at \$CATALINA_HOME\\n\\n[OUTPUT]:\\n"
var24="$(grep STRICT_SERVLET_COMPLIANCE $pathServiceTomcatBin/catalina.sh)"
if [ -z "$var24" ]; then
    printf "The row '-Dorg.apache.catalina.STRICT_SERVLET_COMPLIANCE=true' NOT FOUND in bin/catalina.sh\\n"
else
    printf "Add -Dorg.apache.catalina.STRICT_SERVLET_COMPLIANCE=true to bin/catalina.sh\\n"
fi
results[index-1]="REQUIRES CHECKING"
brLine

# 10.7 Turn off session façade recycling (76)
title="[10.7 Turn off session façade recycling (76)]"
titles[index++]="$title"
printf "%s\\n\\n" "$title"
printf "Ensure the above parameter is added to the startup script which by default is located at \$CATALINA_HOME/bin/catalina.sh.\\n\\n[OUTPUT]:\\n"
var25="$(grep STRICT_SERVLET_COMPLIANCE $pathServiceTomcatBin/catalina.sh)"
if [ -z "$var25" ]; then
    printf "The row '-Dorg.apache.catalina.connector.RECYCLE_FACADES=true' NOT FOUND in bin/catalina.sh\\n"
else
    printf "Add -Dorg.apache.catalina.connector.RECYCLE_FACADES=true to bin/catalina.sh\\n"
fi
results[index-1]="REQUIRES CHECKING"
brLine

# 10.13 Do not allow symbolic linking (82)
title="[10.13 Do not allow symbolic linking (82)]"
titles[index++]="$title"
printf "%s\\n\\n" "$title"
printf "Ensure all context.xml have the allowLinking attribute set to false or allowLinking does not exist.\\n\\n[OUTPUT]:\\n"
var26="$(find . -name context.xml | xargs grep "allowLinking")"
var26=`echo $var26`
if [ -z "$var26" ]; then
    printf "AllowLinking does not exist - OK\\n"
    results[index-1]="OK"
else
    results[index-1]="NOT OK"
    if [ "$var26" = "true" ]; then
        find . -name context.xml | xargs grep "allowLinking"
        printf "Set allowLinking to false in context.xml.\\n"
    fi
fi
brLine

# 10.14 Do not run applications as privileged (83)
title="[10.14 Do not run applications as privileged (83)]"
titles[index++]="$title"
printf "%s\\n\\n" "$title"
printf "Ensure all context.xml have the privileged attribute set to false or privileged does not exist.\\n\\n[OUTPUT]:\\n"
var27="$(find . -name context.xml | xargs grep "privileged")"
var27=`echo $var27`
if [ -z "$var27" ]; then
    printf "Privileged does not exist - OK\\n"
    results[index-1]="OK"
else
    results[index-1]="NOT OK"
    if [[ "$var27" = "true" ]]; then
        find . -name context.xml | xargs grep "privileged"
        printf "Set privileged to false in context.xml.\\n"
    fi
fi
brLine

# 10.15 Do not allow cross context requests (84)
title="[10.15 Do not allow cross context requests (84)]"
titles[index++]="$title"
printf "%s\\n\\n" "$title"
printf "Ensure all context.xml have the crossContext attribute set to false or crossContext does not exist.\\n\\n[OUTPUT]:\\n"
var28="$(find . -name context.xml | xargs grep "crossContext")"
var28=`echo $var28`
if [ -z "$var28" ]; then
    printf "CrossContext does not exist - OK\\n"
    results[index-1]="OK"
else
    results[index-1]="NOT OK"
    if [[ "$var28" = "true" ]]; then
        find . -name context.xml | xargs grep "crossContext"
        printf "Set crossContext to false in context.xml.\\n"
    fi
fi
brLine

# 10.17 Enable memory leak listener (86)
title="[10.17 Enable memory leak listener (86)]"
titles[index++]="$title"
printf "%s\\n\\n" "$title"
printf "Review the \$CATALINA_HOME/conf/server.xml and see whether JRE Memory Leak Prevention Listener is enabled.\\n\\n[OUTPUT]:\\n"
var29="$(find $pathServiceServerXml -name server.xml | xargs grep "JreMemoryLeakPreventionListener")"
var29=`echo $var29`
if [ -z "$var29" ]; then
    printf "JreMemoryLeakPreventionListener does not exist - OK\\n"
    results[index-1]="OK"
else
    results[index-1]="NOT OK"
    if [[ ${x:0:1} == '#' ]]; then
        printf "Uncomment the JRE Memory Leak Prevention Listener in \$CATALINA_HOME/conf/server.xml\\n"
    else
        find $pathServiceServerXml -name server.xml | xargs grep "JreMemoryLeakPreventionListener"
        printf "JRE Memory Leak Prevention Listener FOUND in \$CATALINA_HOME/conf/server.xml - OK\\n"
    fi
fi
brLine

# 10.18 Setting Security Lifecycle Listener (87)
title="[10.18 Setting Security Lifecycle Listener (87)]"
titles[index++]="$title"
printf "%s\\n\\n" "$title"
printf "Review server.xml to ensure the Security Lifecycle Listener element is uncommented and checkedOsUsers, minimumUmask attributes are set with expected value.\\n\\n[OUTPUT]:\\n"
var30="$(find $pathServiceServerXml -name server.xml | xargs grep "org.apache.catalina.security.SecurityListener")"
var30=`echo $var30`
if [ -z "$var30" ]; then
    printf "org.apache.catalina.security.SecurityListener does not exist - OK\\n"
    results[index-1]="OK"
else
    results[index-1]="NOT OK"
    if [[ ${x:0:1} == '#' ]]; then
        printf "Uncomment the Security Listener in \$CATALINA_HOME/conf/server.xml\\n"
    else
        find $pathServiceServerXml -name server.xml | xargs grep "org.apache.catalina.security.SecurityListener"
        printf "Security Listener FOUND in \$CATALINA_HOME/conf/server.xml\\n\\n"
        printf "Add the following to the Listener element if they aren't there already:\\n"
        printf "* checkedOsUsers: A comma separated list of OS users that must not be used to start Tomcat. If not specified, the default value of root is used.\\n* minimumUmask: The least restrictive umask that must be configured before Tomcat will start. If not specified, the default value of 0007 is used.\\n"
    fi
fi
brLine

# 10.19 use the logEffectiveWebXml and metadata-complete settings for deploying applications in production (89)
printf "[10.19 use the logEffectiveWebXml and metadata-complete settings for deploying applications in production (89)]\\n"

title="[10.19 use the logEffectiveWebXml and metadata-complete settings for deploying applications in production (89)] [CASE 1]"
titles[index++]="$title"
printf "[CASE 1] Review each application�s web.xml file located in the applications \$CATALINA_BASE\<app name>\WEB-INF\web.xml and determine if the metadata- complete property is set.\\n\\n[OUTPUT]:\\n"
var31="$(sed -rn 's/.*metadata-complete="([^"]*)".*/\1/p' $pathProcountorWebXml)"
var31=`echo $var31`
if [[ "$var31" = true ]]; then
    printf "metadata-complete is TRUE - OK\\n\\n"
    results[index-1]="OK"
else
    results[index-1]="NOT OK"
    printf "Check the metadata-complete value in $pathProcountorWebXml.\\n\\n"
fi

title="[10.19 use the logEffectiveWebXml and metadata-complete settings for deploying applications in production (89)] [CASE 2]"
titles[index++]="$title"
printf "[CASE 2] Review each application�s context.xml file located in the applications \$CATALINA_BASE\<app name>\META-INF\context.xml and determine if the metadata-complete property is set.\\n\\n[OUTPUT]:\\n"
var32="$(sed -rn 's/.*logEffectiveWebXml="([^"]*)".*/\1/p' $pathProcountorContextXml)"
var32=`echo $var32`
var33="$(sed -rn 's/.*logEffectiveWebXml="([^"]*)".*/\1/p' $pathServiceTomcatConf/context.xml)"
var33=`echo $var33`

if [ -f $pathProcountorContextXml ]; then
    if [[ "$var32" = "true" ]]; then
        printf "logEffectiveWebXml is TRUE - OK\\n"
        results[index-1]="OK"
    else
        results[index-1]="NOT OK"
        printf "logEffectiveWebXml value in Context element is FALSE or does not exist at $pathProcountorContextXml.\\n"
    fi
else
    if [[ "$var33" = "true" ]]; then
        printf "logEffectiveWebXml is TRUE - OK\\n"
        results[index-1]="OK"
    else
        results[index-1]="NOT OK"
        printf "logEffectiveWebXml value in Context element is FALSE or does not exist at $pathServiceTomcatConf/context.xml.\\n"
    fi
fi
brLine


summary
