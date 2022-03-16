#!/bin/bash

# Find current date and time from the system (UTC)
#################################################################
syear=${1:0:4}
smon=${1:4:2}
sday=${1:6:2}
shr=${1:8:2}
datein=`date -u --date="$smon/$sday/$syear $shr:00:00"`
#################################################################
#
# Find end date and time from datein (UTC)
#
#################################################################

  eyr=`date -d "$datein 6 hours ago" -u +%Y`
  emon=`date -d "$datein 6 hours ago" -u +%m`
  eday=`date -d "$datein 6 hours ago" -u +%d`
  ehr=`date -d "$datein 6 hours ago" -u +%H`

echo $eyr$emon$eday$ehr
