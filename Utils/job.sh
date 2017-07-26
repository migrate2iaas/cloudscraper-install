#!/bin/sh
echo ">>>> Loading configuration"

EXTRA_MIGRATE_PARMS="-b 15"

if [ "$Re_Upload" != "false" ]; then
   EXTRA_MIGRATE_PARMS="$EXTRA_MIGRATE_PARMS -u"
fi

echo "Extra parms: $EXTRA_MIGRATE_PARMS"

echo ">>>> Updating dependencies"
cd linux
export DEPSONLY=true
chmod +x ./bootstrap.sh
./bootstrap.sh
cd ..

echo ">>>> Updating Cloudscraper engine"

wget -N http://migrate2iaas.blob.core.windows.net/cloudscraper-build-result/${branch}/migrate.zip
unzip -q -o migrate.zip

rm -f lcns.msg
wget http://migrate2iaas.blob.core.windows.net/cloudscraper-release6/lcns.msg

mkdir -p ${ImageDirectory}
mkdir -p logs
ret=`python -c 'import sys; print (str(int(sys.hexversion < 0x02070000)));'`
if [ $ret -eq 1 ]; then
   cd Migrate26
else
   cd Migrate
fi
cd Migrate


python Migrate.pyc -c ../../transfer.ini -k ${SecretKey} ${EXTRA_MIGRATE_PARMS}