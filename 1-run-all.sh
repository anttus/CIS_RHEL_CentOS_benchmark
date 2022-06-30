#!/bin/bash
mkdir ./results
sh 2-services.sh
sh 3-network-config.sh
sh 4-logging-auditing.sh
sh 5-access-auth.sh
sh 6-system-maintenance.sh