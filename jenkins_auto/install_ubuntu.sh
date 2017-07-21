#! /bin/sh

python -mplatform | grep -i 'Ubuntu\|Debian\|Gentoo' && INSTALL_COMMAND=apt-get || INSTALL_COMMAND=yum

${INSTALL_COMMAND} update


#TODO: get wget and curl
${INSTALL_COMMAND} -y install curl
${INSTALL_COMMAND} -y install wget
if [INSTALL_COMMAND==yum] 
then
sudo easy_install pip
fi
${INSTALL_COMMAND} -y install python-pip
${INSTALL_COMMAND} -y install unzip

pip install boto
pip install azure
pip install cloudsigma
pip install requests


JENKINS_MASTER_ADDR=54.164.23.220:8080
JENKINS_MASTER_USER_NAME=autoregister
JENKINS_MASTER_USER_APIKEY=751b484e997ed0eefdf4d45023afe3ee
JENKINS_SLAVE_NODE_NAME=
JENKINS_SLAVE_JNLP_SECRET=

GENERATOR_JOB=migrateEc2_linux_JobGenerator

LOGFILE=./cloudscraper-auto-install.log
JENKINSPATH=/opt/jenkins

mkdir -p ${JENKINSPATH}

# install java
#TODO: unpack java here from local stuff in the future
#TODO: How to locate java?
${INSTALL_COMMAND} install openjdk-7-jre




echo "==========================================" >> ${LOGFILE}
echo "Finished JAVA" >> ${LOGFILE}
echo "==========================================" >> ${LOGFILE}

# Enable ping to keep heartbeat
# Nothing here

# obtaining parms, if they are not pre-defined, prompt
#if "%JENKINS_MASTER_ADDR%"=="" set /p JENKINS_MASTER_ADDR="Enter the migration master address e.g. 72.58.33.45:8080: " 
#if "%JENKINS_MASTER_USER_NAME%"=="" set /p JENKINS_MASTER_USER_NAME="Authorize to migration master, enter username : " 
#if "%JENKINS_MASTER_USER_APIKEY%"=="" set /p JENKINS_MASTER_USER_APIKEY="Authorize to migration master, enter API key: "
#if "%JENKINS_SLAVE_NODE_NAME%"=="" set /p JENKINS_SLAVE_NODE_NAME="Enter Jenkins slave name: " 

JENKINS_SLAVE_NODE_NAME=`uname -n`

echo "==========================================" >>  ${LOGFILE}
#Try to create new job and get JNLP
echo Registering new node...
curl -d "script=import jenkins.model.* ; import hudson.model.* ; import hudson.slaves.* ; Jenkins.instance.addNode(new hudson.slaves.DumbSlave(\"${JENKINS_SLAVE_NODE_NAME}\",\"${JENKINS_SLAVE_NODE_NAME}\",\"${JENKINSPATH}\",\"1\",Node.Mode.NORMAL,\"linux\",new JNLPLauncher(),new RetentionStrategy.Always(),new LinkedList())) " -X POST ${JENKINS_MASTER_USER_NAME}:${JENKINS_MASTER_USER_APIKEY}@${JENKINS_MASTER_ADDR}/jenkins/scriptText  >> ${LOGFILE} 2>&1

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
NODEBAT=${JENKINSPATH}\node.sh
echo cd ${JENKINSPATH} > ${NODEBAT}
echo java -jar slave.jar -jnlpUrl ${JENKINS_SLAVE_URL}/slave-agent.jnlp -secret ${JENKINS_SLAVE_JNLP_SECRET} '&' >> ${NODEBAT}slave.log 2> ${NODEBAT}slave.error.log >> ${NODEBAT}
cp ${NODEBAT}  /etc/init.d/cloudscraper
echo "==========================================" >> ${LOGFILE}
echo "Created note.bat" >> ${LOGFILE}
echo "==========================================" >> ${LOGFILE}

# registering node.bat as a startup file
sudo chmod +x /etc/init.d/cloudscraper
sudo chown root:root /etc/init.d/cloudscraper

sudo update-rc.d cloudscraper defaults
sudo update-rc.d cloudscraper enable

#TODO: Add else
if [ INSTALL_COMMAND == yum ] 
then
chkconfig --level 3 cloudscraper on
fi


sudo service cloudscraper start

echo "==========================================" >> ${LOGFILE}
echo "Registered the agent" >> ${LOGFILE}
echo "==========================================" >> ${LOGFILE}

#:: updating time
#echo Updating system time
#w32tm /config /syncfromflags:MANUAL /manualpeerlist:time.windows.com,time-a.nist.gov,time-b.nist.gov
#w32tm /config /update 

#echo "==========================================" >> %LOGFILE%
#echo "Time updated" >> %LOGFILE%
#echo "==========================================" >> %LOGFILE%
