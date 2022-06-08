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

if [ $shr -eq 00 ] 
then
  eyr=`date -d "$datein +12 hours" -u +%Y`
  emon=`date -d "$datein +12 hours" -u +%m`
  eday=`date -d "$datein +12 hours" -u +%d`
  ehr=`date -d "$datein +12 hours" -u +%H`
else
  eyr=`date -d "$datein +12 hours" -u +%Y`
  emon=`date -d "$datein +12 hours" -u +%m`
  eday=`date -d "$datein +12 hours" -u +%d`
  ehr=`date -d "$datein +12 hours" -u +%H`
fi

echo $eyr$emon$eday$ehr
