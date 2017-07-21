#! /bin/bash

echo --------------------------------------------------------------------------------
echo Please download install.sh too prior running this
echo --------------------------------------------------------------------------------


export JENKINS_MASTER_ADDR=dev.migrate2iaas.com:2228
export JENKINS_MASTER_USER_NAME=autoregister
export JENKINS_MASTER_USER_APIKEY=751b484e997ed0eefdf4d45023afe3ee
export SCRIPTED_CLOUD_SLAVE_TYPE=org.jenkinsci.plugins.scripted_cloud.scriptedCloudSlave
export SCRIPTED_CLOUD_EXTRA_PARMS=",\"EC2\",\"ADD INSTANCE ID HERE\",\"\",\"ADD REGION HERE\",\"\",false,\"\",\"Shutdown\""

echo Please specify Jenkins Node Name to create
read JENKINS_SLAVE_NODE_NAME

export JENKINS_SLAVE_NODE_NAME

bash ./install_old.sh