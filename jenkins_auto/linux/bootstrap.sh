#!/bin/bash
if [[ $EUID -ne 0 ]]; then
   echo "Error: This script must be run as root!" 
   exit 1
fi


echo =============================
echo migrate2iaas version ${version}
echo =============================
echo CHECKING PYTHON
echo =============================


ret=`python -c 'import sys; print ("%i" % int(sys.hexversion < 0x03000000 and sys.hexversion > 0x02060000));'`
if [ $ret -eq 0 ]; then
   echo "Error: Unsupported python version detected!"
   echo "Python version 2.6 or 2.7 required."
   exit 1
fi


PYTHON=python
PIP=pip

declare -A package;
packageId=0
#In file there are packages in install order
filename="crit_packages.conf"
while read -r package crit os
do
	package[$packageId,package]=$package
	package[$packageId,crit]=$crit
	package[$packageId,os]=$os
	packageId=$((packageId + 1))
done < "$filename"

echo =============================
echo DETECTING PACKET MANAGER
echo =============================

declare -A osInfo;
osInfo[/etc/redhat-release]=yum
osInfo[/etc/arch-release]=pacman
osInfo[/etc/gentoo-release]=emerge
osInfo[/etc/SuSE-release]=zypp
osInfo[/etc/debian_version]=apt-get

for os in ${!osInfo[@]}
do
    if [[ -f $os ]];then
        echo Package manager installed: ${osInfo[$os]} | tee -a cloudscraper_install.log
		INSTALL_COMMAND=${osInfo[$os]}
    fi
done

case $INSTALL_COMMAND in
yum)
	distrib=redhat
	;;
pacman)
	distrib=arch
	;;
emerge)
	distrib=gentoo
	;;
zypp)
	distrib=SuSE
	;;
apt-get)
	distrib=debian
	;;
*)
  echo "ERROR: The OS can't be determined due to Disturbance in the Force" | tee -a cloudscraper_install.log
  exit 1
  ;;
esac


echo =============================
echo INSTALLING THE DEPENDENCIES
echo =============================


CritPackInstErr=0
if [ "$INSTALL_COMMAND" = "apt-get" ]; then
	${INSTALL_COMMAND} update  2>&1  1>>cloudscraper_install.log
fi
for id in `seq 0 $(($packageId-1))`;
do
	echo "."
	if [[ "${package[$id,os]}" = "$distrib" || "${package[$id,os]}" = "All" ]]; then
		echo "Installing ${package[$id,package]}" &>>cloudscraper_install.log
		${INSTALL_COMMAND} -y install ${package[$id,package]}  &>> cloudscraper_install.log
		if [[ $? -ne 0 && ${package[$id,crit]} -eq 1 ]];then
			echo ">>>>>> Error: package" ${package[$id,package]} " failed to install with " ${INSTALL_COMMAND}
			exit 1
		fi
		if [[ $? -ne 0 && ${package[$id,crit]} -ne 1 ]];then
			echo "Warning: Noncritical package" ${package[$id,package]} "failed to install" &>>cloudscraper_install.log
		fi
		
	fi
done


wget --no-check-certificate https://bootstrap.pypa.io/ez_setup.py -nv -O - | python 2>&1 &>>cloudscraper_install.log
easy_install pip &>>cloudscraper_install.log
easy_install -U boto &>>cloudscraper_install.log

${PIP} install boto &>>cloudscraper_install.log
${PIP} install python-dateutil 2>&1 1>>cloudscraper_install.log
${PIP} install httplib2 &>>cloudscraper_install.log
${PIP} install requests &>>cloudscraper_install.log
${PIP} install argparse &>>cloudscraper_install.log
${PIP} install -U six &>>cloudscraper_install.log
${PIP} install tinydb &>>cloudscraper_install.log
${PIP} install funcsigs &>>cloudscraper_install.log
${PIP} install python-swiftclient &>>cloudscraper_install.log
${PIP} install pyopenssl &>>cloudscraper_install.log
${PIP} install python-glanceclient &>>cloudscraper_install.log
${PIP} install python-novaclient &>>cloudscraper_install.log
${PIP} install python-keystone &>>cloudscraper_install.log
${PIP} install importlib &>>cloudscraper_install.log
${PIP} install fusepy &>>cloudscraper_install.log
${PIP} install pytz &>>cloudscraper_install.log
${PIP} install cachetools &>>cloudscraper_install.log




if [ "$DEPSONLY" = "true" ]; then
	exit 0
fi


echo =============================
echo UNPACKING JAVA
echo =============================

MACHINE_TYPE=`uname -m`
if [ ${MACHINE_TYPE} == 'x86_64' ]; then
  JAVAINSTALLER=jre/jre-8u45-linux-x64.tar.gz
else
  JAVAINSTALLER=jre/jre-8u45-linux-i586.tar.gz
fi

mkdir -p jre
tar -zxvf ${JAVAINSTALLER}  -C jre --strip-components 1 &>>cloudscraper_install.log

echo =============================
echo CONNECTING TO THE SERVER
echo =============================

${PYTHON} install_python.py --instcom "$INSTALL_COMMAND" "$@"