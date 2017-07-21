#!/bin/bash

echo =============================
echo INSTALLING THE DEPENDENCIES
echo =============================

set -e

python -mplatform | grep Ubuntu && INSTALL_COMMAND=apt-get || INSTALL_COMMAND=yum

echo ===============================
echo INSTALLING curl and wget
echo ===============================
${INSTALL_COMMAND} -y install curl
${INSTALL_COMMAND} -y install wget
${INSTALL_COMMAND} -y install unzip
${INSTALL_COMMAND} -y install kpartx


echo ===============================
echo DOWNLOADING BITNAMI CONTAINER
echo ===============================

MACHINE_TYPE=`uname -m`
BITNAMI_INSTALLER=bitnami-cloudtools-aws-1.9-0-linux-installer.run
if [[ ${MACHINE_TYPE} == 'x86_64' ]]; then
   BITNAMI_INSTALLER=bitnami-cloudtools-aws-1.9-0-linux-x64-installer.run
fi
wget --no-check-certificate  https://bitnami.com/redirect/to/37396/${BITNAMI_INSTALLER}
chmod +x ${BITNAMI_INSTALLER}

echo ===============================
echo INSTALLING BITNAMI CONTAINER
echo ===============================
echo It could take a dozen of minutes....


./${BITNAMI_INSTALLER} --launchbch 0 --mode unattended --unattendedmodeui minimal 


#default install path
INSTALLPATH=/opt/bitnami-awstools-1.10-0

#set the default tools path
PYTHON_PATH=${INSTALLPATH}/python/bin
PYTHON=${INSTALLPATH}/python/bin/python
EASY_INSTALL=${INSTALLPATH}/python/bin/easy_install
PIP=${INSTALLPATH}/python/bin/pip

wget https://bootstrap.pypa.io/ez_setup.py -O - | ${PYTHON}
${PYTHON} ${EASY_INSTALL} pip

${PYTHON} ${PIP} install boto
${PYTHON} ${PIP} install azure
${PYTHON} ${PIP} install cloudsigma
${PYTHON} ${PIP} install requests
${PYTHON} ${PIP} install -U six

JAVA=${INSTALLPATH}/java/bin/java

# -------------------------------------------------------------------
# Set default migration panel if not set
# -------------------------------------------------------------------
echo Preset host $JENKINS_MASTER_ADDR

if [[ -z "$JENKINS_MASTER_ADDR" ]]; 
then
JENKINS_MASTER_ADDR=54.164.23.220:8080
fi

if [[ -z "$JENKINS_MASTER_USER_NAME" ]];
then
JENKINS_MASTER_USER_NAME=autoregister
fi

if [[ -z "$JENKINS_MASTER_USER_APIKEY" ]];
then
JENKINS_MASTER_USER_APIKEY=751b484e997ed0eefdf4d45023afe3ee
fi

if [[ -z "$SCRIPTED_CLOUD_SLAVE_TYPE" ]];
then
SCRIPTED_CLOUD_SLAVE_TYPE=hudson.slaves.DumbSlave
SCRIPTED_CLOUD_EXTRA_PARMS=
fi

JENKINS_SLAVE_JNLP_SECRET=

if [[ -z "$GENERATOR_JOB" ]];
then
GENERATOR_JOB=migrate_linux_JobGenerator
fi

LOGFILE=./cloudscraper-auto-install.log
JENKINSPATH=/opt/jenkins
mkdir -p ${JENKINSPATH}

echo =============================
echo ENTER YOUR PANEL CREDENTIALS
echo =============================

echo Please enter you migration panel username:
read JENKINS_USERNAME
echo Please enter your migration panel password, Note, it will not be displayed:
stty -echo
echo "Password::"
read JENKINS_PASSWORD
stty echo


if [[ -z "$JENKINS_SLAVE_NODE_NAME" ]];
then 
JENKINS_SLAVE_NODE_NAME=${JENKINS_USERNAME}-
JENKINS_SLAVE_NODE_NAME=${JENKINS_SLAVE_NODE_NAME}`uname -n`
fi

echo "==========================================" >>  ${LOGFILE}
#Try to create new job and get JNLP
echo Registering new node...
curl -d "script=import jenkins.model.* ; import hudson.model.* ; import hudson.slaves.* ; Jenkins.instance.addNode(new ${SCRIPTED_CLOUD_SLAVE_TYPE}(\"${JENKINS_SLAVE_NODE_NAME}\",\"ADD DESCRIPTION HERE\",\"${JENKINSPATH}\",\"1\",Node.Mode.NORMAL,\"linux\",new JNLPLauncher(),new RetentionStrategy.Always(),new LinkedList() ${SCRIPTED_CLOUD_EXTRA_PARMS} )) " -X POST ${JENKINS_MASTER_USER_NAME}:${JENKINS_MASTER_USER_APIKEY}@${JENKINS_MASTER_ADDR}/jenkins/scriptText  >> ${LOGFILE} 2>&1

echo "==========================================" >>  ${LOGFILE}

echo Registering new tasks for nodes...
curl -d "" -X POST ${JENKINS_MASTER_USER_NAME}:${JENKINS_MASTER_USER_APIKEY}@${JENKINS_MASTER_ADDR}/jenkins/job/${GENERATOR_JOB}/build --data-urlencode json="{\"parameter\":[{\"name\":\"Node\",\"value\":\"${JENKINS_SLAVE_NODE_NAME}\"}]}" >> ${LOGFILE} 2>&1

#Try to obtain JNLP 
echo Connecting to jenkins...
JENKINS_SLAVE_JNLP_SECRET=`curl -d "script=println jenkins.slaves.JnlpSlaveAgentProtocol.SLAVE_SECRET.mac('${JENKINS_SLAVE_NODE_NAME}')" -X POST http://${JENKINS_MASTER_USER_NAME}:${JENKINS_MASTER_USER_APIKEY}@${JENKINS_MASTER_ADDR}/jenkins/scriptText`

JENKINS_SLAVE_URL=http://${JENKINS_MASTER_ADDR}/jenkins/computer/${JENKINS_SLAVE_NODE_NAME}

# downloading the slave jar
echo Downloading Jenkins slave binary...
wget http://${JENKINS_MASTER_ADDR}/jenkins/jnlpJars/slave.jar -O ${JENKINSPATH}/slave.jar -a ${LOGFILE}

echo "==========================================" >> ${LOGFILE}
echo "Downloaded slave.jar" >>${LOGFILE}
echo "==========================================" >> ${LOGFILE}

# creating node.bat file
# set python env for it, set it run in background
#TODO: create full-scale .sh service from it
NODEBAT=${JENKINSPATH}\node.sh
echo \#!/bin/bash > ${NODEBAT}
echo \#chkconfig: 2345 95 20 >> ${NODEBAT}
echo \#description: cloudscraper agent service >> ${NODEBAT}
echo \#processname: cloudscraper >> ${NODEBAT}
echo cd ${JENKINSPATH} >> ${NODEBAT}
echo env PATH=${PYTHON_PATH}:\${PATH} ${JAVA} -jar slave.jar -jnlpUrl ${JENKINS_SLAVE_URL}/slave-agent.jnlp -secret ${JENKINS_SLAVE_JNLP_SECRET} '&' >> ${NODEBAT}slave.log 2> ${NODEBAT}slave.error.log >> ${NODEBAT}
cp ${NODEBAT}  /etc/init.d/cloudscraper

echo "==========================================" >> ${LOGFILE}
echo "Created note.bat" >> ${LOGFILE}
echo "==========================================" >> ${LOGFILE}

# registering node.bat as a startup file
sudo chmod +x /etc/init.d/cloudscraper
sudo chown root:root /etc/init.d/cloudscraper

set +e

sudo update-rc.d cloudscraper defaults
sudo update-rc.d cloudscraper enable

if [[ "$INSTALL_COMMAND" = "yum" ]];
then
	chkconfig --level 2345 cloudscraper on
fi

sudo service cloudscraper start

echo "==========================================" >> ${LOGFILE}
echo "Registered the agent" >> ${LOGFILE}
echo "==========================================" >> ${LOGFILE}
