#!/bin/bash

echo =============================
echo INSTALLING THE DEPENDENCIES
echo =============================

python -mplatform | grep -i 'Ubuntu\|Debian\|Gentoo' && INSTALL_COMMAND=apt-get || INSTALL_COMMAND=yum

if [[ "$INSTALL_COMMAND"="apt-get" ]]; 
then
${INSTALL_COMMAND} update
fi

${INSTALL_COMMAND} -y install curl
${INSTALL_COMMAND} -y install wget
wget https://bootstrap.pypa.io/ez_setup.py -O - | python
easy_install pip
${INSTALL_COMMAND} -y install unzip

if [ "$INSTALL_COMMAND" = "apt-get" ]; then
${INSTALL_COMMAND} -y install qemu-utils libxml2-dev libxslt-dev python-dev 
else
${INSTALL_COMMAND} -y install qemu-common qemu-img 
fi
echo .
${INSTALL_COMMAND} -y install kpartx 
echo .
${INSTALL_COMMAND} -y install libxslt 
echo .
${INSTALL_COMMAND} -y install libxml2 
echo .
${INSTALL_COMMAND} -y install python-lxml  
echo .

pip install boto
pip install azure
pip install cloudsigma
pip install lxml
pip install requests
pip install -U six

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

# -------------------------------------------------------------------
# Install JAVA
# -------------------------------------------------------------------

mkdir -p ${JENKINSPATH}

if type -p java; then
    echo Found java executable in PATH
    _java=java
elif [[ -n "$JAVA_HOME" ]] && [[ -x "$JAVA_HOME/bin/java" ]];  then
    echo Found java executable in JAVA_HOME     
    _java="$JAVA_HOME/bin/java"
else
    echo No java found, installing
    JRE_PACK=openjdk-7-jre
    echo $INSTALL_COMMAND
    if [[ "$INSTALL_COMMAND" == "yum" ]];
    then
          JRE_PACK=java-1.7.0-openjdk
    fi
    ${INSTALL_COMMAND} install -y ${JRE_PACK}
fi

echo "==========================================" >> ${LOGFILE}
echo "Finished JAVA" >> ${LOGFILE}
echo "==========================================" >> ${LOGFILE}

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
NODEBAT=${JENKINSPATH}/node.sh
echo "#!/bin/bash" > ${NODEBAT}
printf "### BEGIN INIT INFO\n # Provides:          cloudscraper\n# Required-Start:    networking\n# Required-Stop:     networking\n# Default-Start:     2 3 4 5\n# Default-Stop:      0 1 6\n# Short-Description: Cloudscraper Agent\n# Description:       This is a simple service\n#                    connecting the Linux server\n#                    with Cloudscraper Web Portal.\n### END INIT INFO\n" >> ${NODEBAT}
echo cd ${JENKINSPATH} >> ${NODEBAT}
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

if [[ "$INSTALL_COMMAND" = "yum" ]];
then
	chkconfig --level 3 cloudscraper on
fi

sudo service cloudscraper start

echo "==========================================" >> ${LOGFILE}
echo "Registered the agent" >> ${LOGFILE}
echo "==========================================" >> ${LOGFILE}
