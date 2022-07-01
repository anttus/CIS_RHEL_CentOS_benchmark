#!/bin/bash
[ ! -d "./results" ] && mkdir ./results
sudo sh 2-services.sh
sudo sh 3-network-config.sh
sudo sh 4-logging-auditing.sh
sudo sh 5-access-auth.sh
sudo sh 6-system-maintenance.sh
sudo chmod 775 results/*