#!/bin/bash -
#title          :6. System maintenance
#description    :This script does checks on different system file permissions, based on CIS CentOS / RHEL 7 benchmark chapter 6
#author         :Anttu Suhonen
#date           :20180524
#version        :1.0
#usage          :./6-system-maintenance.sh
#============================================================================

exec > ./results/"$(hostname)"_CIS_system-maintenance_"$(date +%d-%m-%Y)".log
exec 2>&1

# Functions ------------->
function brLine {
    printf "\\n--------------------\\n"
}

function summary {
    printf "\\n\\n-------------------- [SUMMARY - sfPermissionsCheck] --------------------\\n\\n"
    for (( i = 0; i < ${#titles[@]}; i++ )); do
        printf "%-85s - %s\\n\\n" "${titles[$i]}" "${results[$i]}"
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

function rootPathIntegrity {
  if [ "`echo $PATH | grep ::`" != "" ]; then
    echo "Empty Directory in PATH (::)"
  fi
  if [ "`echo $PATH | grep :$`"  != "" ]; then
    echo "Trailing : in PATH"
  fi
  p=`echo $PATH | sed -e 's/::/:/' -e 's/:$//' -e 's/:/ /g'`
  set -- $p
  while [ "$1" != "" ]; do
    if [ "$1" = "." ]; then
      echo "PATH contains ."
      shift
      continue
    fi
    if [ -d $1 ]; then
      dirperm=`ls -ldH $1 | cut -f1 -d" "`
      if [ `echo $dirperm | cut -c6`  != "-" ]; then
        echo "Group Write permission set on directory $1"
      fi
      if [ `echo $dirperm | cut -c9` != "-" ]; then
        echo "Other Write permission set on directory $1"
      fi
      dirown=`ls -ldH $1 | awk '{print $3}'`
      if [ "$dirown" != "root" ] ; then
        echo $1 is not owned by root
      fi
    else
      echo $1 is not a directory
    fi
    shift
  done
}

function checkIfHomeDirsExist {
  cat /etc/passwd | grep -v '^(root|halt|sync|shutdown)' | awk -F: '($7 != "/sbin/nologin" && $7 != "/bin/false") { print $1 " " $6 }' | while read user dir; do
    if [ ! -d "$dir" ]; then
      echo "The home directory ($dir) of user $user does not exist."
    fi
  done
}

function homeDirPermissions {
  cat /etc/passwd | egrep -v '^(root|halt|sync|shutdown)' | awk -F: '($7 != "/sbin/nologin" && $7 != "/bin/false") { print $1 " " $6 }' | while read user dir; do
    if [ ! -d "$dir" ]; then
      echo "The home directory ($dir) of user $user does not exist."
    else
      dirperm=`ls -ld $dir | cut -f1 -d" "`
      if [ `echo $dirperm | cut -c6` != "-" ]; then
        echo "Group Write permission set on the home directory ($dir) of user $user"
      fi
      if [ `echo $dirperm | cut -c8` != "-" ]; then
        echo "Other Read permission set on the home directory ($dir) of user $user"
      fi
      if [ `echo $dirperm | cut -c9` != "-" ]; then
        echo "Other Write permission set on the home directory ($dir) of user $user"
      fi
      if [ `echo $dirperm | cut -c10` != "-" ]; then
        echo "Other Execute permission set on the home directory ($dir) of user $user"
      fi fi
    done
}

function userOwnsHomeDir {
  cat /etc/passwd | egrep -v '^(root|halt|sync|shutdown)' | awk -F: '($7 != "/sbin/nologin" && $7 != "/bin/false") { print $1 " " $6 }' | while read user dir; do
    if [ ! -d "$dir" ]; then
      echo "The home directory ($dir) of user $user does not exist."
    else
      owner=$(stat -L -c "%U" "$dir")
      if [ "$owner" != "$user" ]; then
        echo "The home directory ($dir) of user $user is owned by $owner."
      fi
    fi
  done
}

function dotFilesCheck {
  cat /etc/passwd | egrep -v '^(root|halt|sync|shutdown)' | awk -F: '($7 != "/sbin/nologin" && $7 != "/bin/false") { print $1 " " $6 }' | while read user dir; do
    if [ ! -d "$dir" ]; then
      echo "The home directory ($dir) of user $user does not exist."
    else
      for file in $dir/.[A-Za-z0-9]*; do
        if [ ! -h "$file" ] && [ -f "$file" ]; then
          fileperm=`ls -ld $file | cut -f1 -d" "`
          if [ `echo $fileperm | cut -c6` != "-" ]; then
            echo "Group Write permission set on file $file"
          fi
          if [ `echo $fileperm | cut -c9`  != "-" ]; then
            echo "Other Write permission set on file $file"
          fi
        fi
      done
    fi
  done
}

function userHasNoForwardFiles {
  cat /etc/passwd | egrep -v '^(root|halt|sync|shutdown)' | awk -F: '($7 != "/sbin/nologin" && $7 != "/bin/false") { print $1 " " $6 }' | while read user dir; do
    if [ ! -d "$dir" ]; then
      echo "The home directory ($dir) of user $user does not exist."
    else
      if [ ! -h "$dir/.forward" ] && [ -f "$dir/.forward" ]; then
        echo ".forward file $dir/.forward exists"
      fi
    fi
  done
}

function userHasNoNetrcFiles {
  cat /etc/passwd | egrep -v '^(root|halt|sync|shutdown)' | awk -F: '($7 != "/sbin/nologin" && $7 != "/bin/false") { print $1 " " $6 }' | while read user dir; do
    if [ ! -d "$dir" ]; then
      echo "The home directory ($dir) of user $user does not exist."
    else
      if [ ! -h "$dir/.netrc" ] && [ -f "$dir/.netrc" ]; then
        echo ".netrc file $dir/.netrc exists"
      fi
    fi
  done
}

function usersNetrcFilesAccessibility {
  cat /etc/passwd | egrep -v '^(root|halt|sync|shutdown)' | awk -F: '($7 != "/sbin/nologin" && $7 != "/bin/false") { print $1 " " $6 }' | while read user dir; do
    if [ ! -d "$dir" ]; then
      echo "The home directory ($dir) of user $user does not exist."
    else
      for file in $dir/.netrc; do
        if [ ! -h "$file" ] && [ -f "$file" ]; then
          fileperm=`ls -ld $file | cut -f1 -d" "`
          if [ `echo $fileperm | cut -c5`  != "-" ]; then
            echo "Group Read set on $file"
          fi
          if [ `echo $fileperm | cut -c6`  != "-" ]; then
            echo "Group Write set on $file"
          fi
          if [ `echo $fileperm | cut -c7`  != "-" ]; then
            echo "Group Execute set on $file"
          fi
          if [ `echo $fileperm | cut -c8`  != "-" ]; then
            echo "Other Read set on $file"
          fi
          if [ `echo $fileperm | cut -c9`  != "-" ]; then
            echo "Other Write set on $file"
          fi
          if [ `echo $fileperm | cut -c10`  != "-" ]; then
            echo "Other Execute set on $file"
          fi
        fi
      done
    fi
  done
}

function noUsersHaveRhosts {
  cat /etc/passwd | egrep -v '^(root|halt|sync|shutdown)' | awk -F: '($7 != "/sbin/nologin" && $7 != "/bin/false") { print $1 " " $6 }' | while read user dir; do
    if [ ! -d "$dir" ]; then
      echo "The home directory ($dir) of user $user does not exist."
    else
      for file in $dir/.rhosts; do
        if [ ! -h "$file" ] && [ -f "$file" ]; then
          echo ".rhosts file in $dir"
        fi
      done
    fi
  done
}

function groupsInPasswdAreInGroup {
  for i in $(cut -s -d: -f4 /etc/passwd | sort -u ); do grep -q -P "^.*?:[^:]*:$i:" /etc/group
  if [ $? -ne 0 ]; then
    echo "Group $i is referenced by /etc/passwd but does not exist in /etc/group"
  fi
done
}

function noDuplicateUIDs {
  cat /etc/passwd | cut -f3 -d":" | sort -n | uniq -c | while read x ; do [ -z "${x}" ] && break
  set - $x
  if [ $1 -gt 1 ]; then
    users=`awk -F: '($3 == n) { print $1 }' n=$2 /etc/passwd | xargs` echo "Duplicate UID ($2): ${users}"
  fi
done
}

function noDuplicateGIDs {
  cat /etc/group | cut -f3 -d":" | sort -n | uniq -c | while read x ; do [ -z "${x}" ] && break
  set - $x
  if [ $1 -gt 1 ]; then
    groups=`awk -F: '($3 == n) { print $1 }' n=$2 /etc/group | xargs`
    echo "Duplicate GID ($2): ${groups}"
  fi
done
}

function noDuplicateUnames {
  cat /etc/passwd | cut -f1 -d":" | sort -n | uniq -c | while read x ; do [ -z "${x}" ] && break
  set - $x
  if [ $1 -gt 1 ]; then
    uids=`awk -F: '($1 == n) { print $3 }' n=$2 /etc/passwd | xargs`
    echo "Duplicate User Name ($2): ${uids}"
  fi
done
}

function noDuplicateGnames {
  cat /etc/group | cut -f1 -d":" | sort -n | uniq -c | while read x ; do [ -z "${x}" ] && break
  set - $x
  if [ $1 -gt 1 ]; then
    gids=`gawk -F: '($1 == n) { print $3 }' n=$2 /etc/group | xargs`
    echo "Duplicate Group Name ($2): ${gids}"
  fi
done
}

function printVerifyEmpty {
  if [[ -z $verifyEmptyCmd ]]; then
      printf "[No results] - OK\\n"
      results[index-1]="OK"
  else
      if [[ "$1" == "true" ]]; then
          printf "There are results, which can be checked with the following command:\\n"
          echo "$verifyEmptyCmdString"
      else
          "$verifyEmptyCmd"
      fi
      results[index-1]="NOT OK"
  fi
}
# End of functions -------------|

printf "This script does checks on different system file permissions,\\n based on CIS_CentOS_Linux_7_Benchmark_v2.2.0's chapter 6.\\n\\n"

index=0

# 6.1.2 Ensure permissions on /etc/passwd are configured (327)
title="[6.1.2 Ensure permissions on /etc/passwd are configured (327)]"
titles[index++]="$title"
printf "%s\\n\\n" "$title"
printf "Verify Uid and Gid are both 0/root\\n"
stat /etc/passwd | grep -m 1 Access:
checkPermissions /etc/passwd 644
brLine

# 6.1.3 Ensure permissions on /etc/shadow are configured (328)
title="6.1.3 Ensure permissions on /etc/shadow are configured (328)]"
titles[index++]="$title"
printf "%s\\n\\n" "$title"
printf "Verify Uid and Gid are 0/root\\n"
stat /etc/shadow | grep -m 1 Access:
checkPermissions /etc/shadow 000
brLine

# 6.1.4 Ensure permissions on /etc/group are configured (329)
title="6.1.4 Ensure permissions on /etc/group are configured (329)]"
titles[index++]="$title"
printf "%s\\n\\n" "$title"
printf "Verify Uid and Gid are both 0/root\\n"
stat /etc/group | grep -m 1 Access:
checkPermissions /etc/group 644
brLine

# 6.1.5 Ensure permissions on /etc/gshadow are configured (330)
title="6.1.5 Ensure permissions on /etc/gshadow are configured (330)]"
titles[index++]="$title"
printf "%s\\n\\n" "$title"
printf "Verify Uid and Gid are 0/root\\n"
stat /etc/gshadow | grep -m 1 Access:
checkPermissions /etc/gshadow 000
brLine

# 6.1.6 Ensure permissions on /etc/passwd- are configured (331)
title="6.1.6 Ensure permissions on /etc/passwd- are configured (331)]"
titles[index++]="$title"
printf "%s\\n\\n" "$title"
printf "Verify Uid and Gid are both 0/root\\n"
stat /etc/passwd- | grep -m 1 Access:
checkPermissions /etc/passwd- 644
brLine

# 6.1.7 Ensure permissions on /etc/shadow- are configured (332)
title="6.1.7 Ensure permissions on /etc/shadow- are configured (332)]"
titles[index++]="$title"
printf "%s\\n\\n" "$title"
printf "Verify Uid and Gid is 0/root\\n"
stat /etc/shadow- | grep -m 1 Access:
checkPermissions /etc/shadow- 000
brLine

# 6.1.8 Ensure permissions on /etc/group- are configured (333)
title="6.1.8 Ensure permissions on /etc/group- are configured (333)]"
titles[index++]="$title"
printf "%s\\n\\n" "$title"
printf "Verify Uid and Gid are both 0/root\\n"
stat /etc/group- | grep -m 1 Access:
checkPermissions /etc/group- 644
brLine

# 6.1.9 Ensure permissions on /etc/gshadow- are configured (334)
title="6.1.9 Ensure permissions on /etc/gshadow- are configured (334)]"
titles[index++]="$title"
printf "%s\\n\\n" "$title"
printf "Verify Uid and Gid are 0/root\\n"
stat /etc/gshadow- | grep -m 1 Access:
checkPermissions /etc/gshadow- 000
brLine

# 6.1.10 Ensure no world writable files exist (335)
title="6.1.10 Ensure no world writable files exist (335)]"
titles[index++]="$title"
printf "%s\\n\\n" "$title"
verifyEmptyCmd=$(df --local -P | awk '{if (NR!=1) print $6}' | xargs -I '{}' find '{}' -xdev -type f -perm -0002)
verifyEmptyCmdString="df --local -P | awk '{if (NR!=1) print \$6}' | xargs -I '{}' find '{}' -xdev -type f -perm -0002"
printVerifyEmpty "true"
brLine

# 6.1.11 Ensure no unowned files or directories exist (336)
title="6.1.11 Ensure no unowned files or directories exist (336)]"
titles[index++]="$title"
printf "%s\\n\\n" "$title"
verifyEmptyCmd="$(df --local -P | awk '{if (NR!=1) print $6}' | xargs -I '{}' find '{}' -xdev -nouser)"
verifyEmptyCmdString="df --local -P | awk '{if (NR!=1) print \$6}' | xargs -I '{}' find '{}' -xdev -nouser"
printVerifyEmpty "true"
brLine

# 6.1.12 Ensure no ungrouped files or directories exis (337)
title="[6.1.12 Ensure no ungrouped files or directories exis (337)]"
titles[index++]="$title"
printf "%s\\n\\n" "$title"
verifyEmptyCmd="$(df --local -P | awk '{if (NR!=1) print $6}' | xargs -I '{}' find '{}' -xdev -nogroup)"
verifyEmptyCmdString="df --local -P | awk '{if (NR!=1) print \$6}' | xargs -I '{}' find '{}' -xdev -nogroup"
printVerifyEmpty "true"
brLine

# 6.2.1 Ensure password fields are not empty (341)
title="[6.2.1 Ensure password fields are not empty (341)]"
titles[index++]="$title"
printf "%s\\n\\n" "$title"
verifyEmptyCmd="$(cat /etc/shadow | awk -F: '($2 == "" ) { print $1 " does not have a password "}')"
verifyEmptyCmdString="cat /etc/shadow | awk -F:'(\$2 == \"\" ) { print \$1 \" does not have a password \"}'"
printVerifyEmpty "true"
brLine

# 6.2.2 Ensure no legacy "+" entries exist in /etc/passwd (343)
title="[6.2.2 Ensure no legacy \"+\" entries exist in /etc/passwd (343)]"
titles[index++]="$title"
printf "%s\\n\\n" "$title"
verifyEmptyCmd="$(grep '^\+:' /etc/passwd)"
verifyEmptyCmdString="grep '^\+:' /etc/passwd"
printVerifyEmpty "true"
brLine

# 6.2.3 Ensure no legacy \"+\" entries exist in /etc/shadow (344)
title="[6.2.3 Ensure no legacy \"+\" entries exist in /etc/shadow (344)]"
titles[index++]="$title"
printf "%s\\n\\n" "$title"
verifyEmptyCmd="$(grep '^\+:' /etc/shadow)"
verifyEmptyCmdString="grep '^\+:' /etc/shadow"
printVerifyEmpty "true"
brLine

# 6.2.4 Ensure no legacy \"+\" entries exist in /etc/group (345)
title="[6.2.4 Ensure no legacy \"+\" entries exist in /etc/group (345)]"
titles[index++]="$title"
printf "%s\\n\\n" "$title"
verifyEmptyCmd="$(grep '^\+:' /etc/group)"
verifyEmptyCmdString="grep '^\+:' /etc/group"
printVerifyEmpty "true"
brLine

# 6.2.5 Ensure root is the only UID 0 account (346)
title="[6.2.5 Ensure root is the only UID 0 account (346)]"
titles[index++]="$title"
printf "%s\\n\\n" "$title"
cmd="$(cat /etc/passwd | awk -F: '($3 == 0) { print $1 }')"
if [[ "$cmd" == "root" ]]; then
    printf "The only result is %s - OK\\n" "$cmd"
    results[index-1]="OK"
else
    printf "Result not 'root' only\\n"
    results[index-1]="NOT OK"
fi
brLine

# 6.2.6 Ensure root PATH Integrity (347)
title="[6.2.6 Ensure root PATH Integrity (347)]"
titles[index++]="$title"
printf "%s\\n\\n" "$title"
verifyEmptyCmd="$(rootPathIntegrity)"
verifyEmptyCmdString=""
printVerifyEmpty "false"
brLine

# 6.2.7 Ensure all users' home directories exist (349)
title="[6.2.7 Ensure all users' home directories exist (349)]"
titles[index++]="$title"
printf "%s\\n\\n" "$title"
verifyEmptyCmd="$(checkIfHomeDirsExist)"
verifyEmptyCmdString=""
printVerifyEmpty "false"
brLine

# 6.2.8 Ensure users' home directories permissions are 750 or more restrictive (350)
title="[6.2.8 Ensure users' home directories permissions are 750 or more restrictive (350)]"
titles[index++]="$title"
printf "%s\\n\\n" "$title"
verifyEmptyCmd="$(homeDirPermissions)"
verifyEmptyCmdString=""
printVerifyEmpty "false"
brLine

# 6.2.9 Ensure users own their home directories (352)
title="[6.2.9 Ensure users own their home directories (352)]"
titles[index++]="$title"
printf "%s\\n\\n" "$title"
verifyEmptyCmd="$(userOwnsHomeDir)"
verifyEmptyCmdString=""
printVerifyEmpty "false"
brLine

# 6.2.10 Ensure users' dot files are not group or world writable (354)
title="[6.2.10 Ensure users' dot files are not group or world writable (354)]"
titles[index++]="$title"
printf "%s\\n\\n" "$title"
verifyEmptyCmd="$(dotFilesCheck)"
verifyEmptyCmdString=""
printVerifyEmpty "false"
brLine

# 6.2.11 Ensure no users have .forward files (356)
title="[6.2.11 Ensure no users have .forward files (356)]"
titles[index++]="$title"
printf "%s\\n\\n" "$title"
verifyEmptyCmd="$(userHasNoForwardFiles)"
verifyEmptyCmdString=""
printVerifyEmpty "false"
brLine

# 6.2.12 Ensure no users have .netrc files (358)
title="[6.2.12 Ensure no users have .netrc files (358)]"
titles[index++]="$title"
printf "%s\\n\\n" "$title"
verifyEmptyCmd="$(userHasNoNetrcFiles)"
verifyEmptyCmdString=""
printVerifyEmpty "false"
brLine

# 6.2.13 Ensure users' .netrc Files are not group or world accessible (360)
title="[6.2.13 Ensure users' .netrc Files are not group or world accessible (360)]"
titles[index++]="$title"
printf "%s\\n\\n" "$title"
verifyEmptyCmd="$(usersNetrcFilesAccessibility)"
verifyEmptyCmdString=""
printVerifyEmpty "false"
brLine

# 6.2.14 Ensure no users have .rhosts files (362)
title="[6.2.14 Ensure no users have .rhosts files (362)]"
titles[index++]="$title"
printf "%s\\n\\n" "$title"
verifyEmptyCmd="$(noUsersHaveRhosts)"
verifyEmptyCmdString=""
printVerifyEmpty "false"
brLine

# 6.2.15 Ensure all groups in /etc/passwd exist in /etc/group (364)
title="[6.2.15 Ensure all groups in /etc/passwd exist in /etc/group (364)]"
titles[index++]="$title"
printf "%s\\n\\n" "$title"
verifyEmptyCmd="$(groupsInPasswdAreInGroup)"
verifyEmptyCmdString=""
printVerifyEmpty "false"
brLine

# 6.2.16 Ensure no duplicate UIDs exist (365)
title="[6.2.16 Ensure no duplicate UIDs exist (365)]"
titles[index++]="$title"
printf "%s\\n\\n" "$title"
verifyEmptyCmd="$(noDuplicateUIDs)"
verifyEmptyCmdString=""
printVerifyEmpty "false"
brLine

# 6.2.17 Ensure no duplicate GIDs exist (366)
title="[6.2.17 Ensure no duplicate GIDs exist (366)]"
titles[index++]="$title"
printf "%s\\n\\n" "$title"
verifyEmptyCmd="$(noDuplicateGIDs)"
verifyEmptyCmdString=""
printVerifyEmpty "false"
brLine

# 6.2.18 Ensure no duplicate user names exist (368)
title="[6.2.18 Ensure no duplicate user names exist (368)]"
titles[index++]="$title"
printf "%s\\n\\n" "$title"
verifyEmptyCmd="$(noDuplicateUnames)"
verifyEmptyCmdString=""
printVerifyEmpty "false"
brLine

# 6.2.19 Ensure no duplicate group names exist (369)
title="[6.2.19 Ensure no duplicate group names exist (369)]"
titles[index++]="$title"
printf "%s\\n\\n" "$title"
verifyEmptyCmd="$(noDuplicateGnames)"
verifyEmptyCmdString=""
printVerifyEmpty "false"
brLine


summary
