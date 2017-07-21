#! /bin/bash
#This script generates ini and autotestconfig.txt files from the parms given
if [ -z "$SOURCECLOUD" ]
 then
SOURCECLOUD=UNKNOWN
fi
if [ -z "$TARGETCLOUD" ] 
 then 
TARGETCLOUD=EC2
fi
if [ -z "$IMAGEDIR" ] 
 then 
IMAGEDIR=/tmp/cloudscraper-images
fi
if [ -z "$SECRETKEY" ] 
 then
SECRETKEY=UNKNOWNKEY
fi
if [ -z "$INSTANCETYPE" ]
 then
INSTANCETYPE=m3.xlarge
fi
if [ -z "$IMAGETYPE" ]
 then
IMAGETYPE=sparsed.raw
fi

if [ -n "$RestorationPointList" ]
 then
RESTORE_VOL=`echo "${RestorationPointList}" | cut -d "|" -f2 | cut -d "|" -f1`
#decide os by the volume name length
WINDOWS=false
if [ ${#RESTORE_VOL} -le 3 ]
then
   WINDOWS=true   
fi
RESTORE_VOL=${RESTORE_VOL:1:1}  
RESTORE_KEY=${RestorationPointList// | //}
RESTORE_KEY=${RESTORE_KEY// /_}
fi

echo [${TARGETCLOUD}] > transfer.ini
if [ -n "$REGION" ]
then 
   echo region=${REGION} >> transfer.ini
fi

REGIONFILE=`dirname $0`/CloudPreconf/${REGION}
echo "$REGIONFILE"
if [ -f "$REGIONFILE" ]
then
  cat ${REGIONFILE} >> transfer.ini
fi

#AWS options:
if [ "${TARGETCLOUD}" = "EC2" ] 
then
  if [ -n "$AWS_Firewall" ] 
  then
   echo security-group=${AWS_Firewall}>> transfer.ini
  fi

  if [ -n "$AWS_VPC" ] 
  then
  if [  "$AWS_VPC" != "None" ] 
  then
  if [ -n "$AWS_VPC_Subnet" ] 
  then
      echo vpcsubnet=${AWS_VPC_Subnet} >> transfer.ini
  fi
  fi
  fi
  if [ -n "$AWS_Availability_Zone" ]
  then
   echo zone=${AWS_Availability_Zone} >> transfer.ini
  fi
fi

if [ -n "$BACKUPBUCKET" ] 
then
   echo bucket=${BACKUPBUCKET} >> transfer.ini
   echo swift_container=${BACKUPBUCKET} >> transfer.ini
fi

if [ "$WINDOWS" = "true" ]
then
         echo os_override=Windows >> transfer.ini
fi

echo instance-type = ${INSTANCETYPE} >> transfer.ini
echo target-arch = x86_64 >> transfer.ini



if [ -n "$storagekey" ] 
then
echo storageaccount=${storagekey} >> transfer.ini
echo s3key=${storagekey} >> transfer.ini
echo user-uuid=${storagekey} >> transfer.ini
echo user=${storagekey} >> transfer.ini
if [ "$TARGETCLOUD" = "OpenStack" ]
then
  echo user = ${storagekey%:*} >> transfer.ini
  echo tennant = ${storagekey#*:} >> transfer.ini
fi
fi

echo [Image] >> transfer.ini

echo image-dir=${IMAGEDIR} >> transfer.ini
echo source-arch = x86_64 >> transfer.ini
echo image-placement = local >> transfer.ini
echo image-type=${IMAGETYPE} >> transfer.ini

echo [Volumes] >> transfer.ini
echo letters = ${VOLUMES},${RESTORE_VOL} >> transfer.ini
echo system=True>> transfer.ini
if [ -n "$RestorationPointList" ] 
then
echo letters = ${RESTORE_VOL} >> transfer.ini
echo system=False>>transfer.ini
fi

if [ "$RESTORE_VOL" = "C" ]
then 
   echo [C] >> transfer.ini
   echo "pathtoupload=${Server}/${RESTORE_KEY}" >> transfer.ini
   echo "system=True" >> transfer.ini
fi
if [ -n "$Server" ]
then 
   echo [${RESTORE_VOL}] >> transfer.ini
   echo "pathtoupload=${Server}/${RESTORE_KEY}" >> transfer.ini
   if [ "$WINDOWS" = "false" ]
   then
         echo "system=True" >> transfer.ini
   fi
fi
echo [all] >> transfer.ini


if [ -n "$Extra" ]
then 
   echo "${Extra}" >> transfer.ini
fi

