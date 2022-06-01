#!/bin/bash

# Find current date and time from the system (UTC)
#################################################################
hrinc=$1
syear=${2:0:4}
smon=${2:4:2}
sday=${2:6:2}
shr=${2:8:2}
datein=`date -u --date="$smon/$sday/$syear $shr:00:00"`
#################################################################
#
# Find end date and time from datein (UTC)
#
#################################################################

eyr=`date -d "$datein +6 hours" -u +%Y`
emon=`date -d "$datein +6 hours" -u +%m`
eday=`date -d "$datein +6 hours" -u +%d`
ehr=`date -d "$datein +6 hours" -u +%H`

dateout=`date +%Y%m%d%H -u -d "$datein $hrinc hours"`

#echo $eyr$emon$eday$ehr
echo $dateout
