#!/bin/bash

# Find current date and time from the system (UTC)
#################################################################
cyr=`date -d "0 hours ago" -u +%Y`
cmon=`date -d "0 hours ago" -u +%m`
cday=`date -d "0 hours ago" -u +%d`
cjday=`date -d "0 hours ago" -u +%j`
chr=`date -d "0 hours ago" -u +%H`
#
# Replace rhr with closest synoptic time
#
if [ $chr -ge 22 ]
then
  ryr=$cyr
  rmon=$cmon
  rday=$cday
  #ryr=`date -d "tomorrow" -u +%Y`
  #rmon=`date -d "tomorrow" -u +%m`
  #rday=`date -d "tomorrow" -u +%d`
  rhr=18
fi
if [ $chr -lt 22 ] && [ $chr -ge 18 ]
then
   ryr=$cyr
   rmon=$cmon
   rday=$cday
   rhr=12
fi
if [ $chr -lt 18 ] && [ $chr -ge 14 ]
then
   ryr=$cyr
   rmon=$cmon
   rday=$cday
   rhr=06
fi
if [ $chr -lt 14 ] && [ $chr -ge 11 ]
then
   ryr=$cyr
   rmon=$cmon
   rday=$cday
   rhr=00
fi
if [ $chr -lt 10 ]
then
   ryr=`date -d "yesterday" -u +%Y`
  rmon=`date -d "yesterday" -u +%m`
  rday=`date -d "yesterday" -u +%d`
  # ryr=$cyr
  # rmon=$cmon
  # rday=$cday
   rhr=18
fi

echo $ryr$rmon$rday$rhr
