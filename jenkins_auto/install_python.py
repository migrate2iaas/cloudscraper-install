#!/usr/bin/python
# -*- coding: UTF-8 -*-

import urllib
import socket
import os, sys
import subprocess
import shlex
import logging, logging.handlers
import time
import shutil
import stat


fcntl_instance = None
jenkins_instance = None

logPath = "cloudscraper-auto-install.log"
# header for linux service
LSB_header = "#!/bin/bash\n\
### BEGIN INIT INFO\n\
# Provides:          cloudscraper\n\
# Required-Start:    networking\n\
# Required-Stop:     networking\n\
# Default-Start:     2 3 4 5\n\
# Default-Stop:      0 1 6\n\
# Short-Description: Cloudscraper Agent\n\
# Description:       This is a simple service\n\
#                    connecting the Linux server\n\
#                    with Cloudscraper Web Portal.\n\
### END INIT INFO\n"

class CredContainer:
	instance=None
	user_name=''
	user_password=''
	
	def __init__(self, url, name, password):
                import jenkins
		self.user_name = name
		self.user_password = password
		self.instance = jenkins.Jenkins(url, name, password)	
		
		
def check_jenkins_user_credentials(jenkins_url, attempts_count):
	for i in range(0, attempts_count, 1):
                import getpass
                
		jenkins_user_name = raw_input("Please enter you migration panel username:")
		jenkins_password = getpass.getpass("Please enter you migration panel password:")		
		credentials = CredContainer(jenkins_url, jenkins_user_name, jenkins_password)
		try:
			credentials.instance.get_info()
			return credentials
		except Exception:
			if str(sys.exc_info()[1]).find("URLError") != -1:
				logger.info("Failed connecting to the server")
				sys.exit(1)
			if str(sys.exc_info()[1]).find("[401]") != -1:
				logger.info("Access denied")
			else:
				logger.debug(sys.exc_info()[1])
				logger.critical("!!! Critical error. See details in log file " + logPath)
				sys.exit(1)
	exit(1)
		
def non_block_read(output):
    fd = output.fileno()
    fl = fcntl_instance.fcntl(fd, fcntl_instance.F_GETFL)
    fcntl_instance.fcntl(fd, fcntl_instance.F_SETFL, fl | os.O_NONBLOCK)
    try:
        return output.readline()
    except:
        return ""

def call(command, logger):	
	try:	
		logger.debug("Trying to execute command:" + str(command))
		p = subprocess.Popen(command, stderr = subprocess.PIPE, stdout = subprocess.PIPE, universal_newlines=True )
		p.wait()	
		
		processResponse = ''
		s = ' '
		s = p.stdout.read()
		logger.debug(s)						
		s = p.stderr.read()
		logger.debug(s)			
		
	except Exception:
		logger.debug(sys.exc_info()[1])
		logger.critical("!!! Critical error. See details in log file " + logPath)
		sys.exit(1)
		
def set_job_icon(job, icon):
	script = 'import jenkins.plugins.jobicon.CustomIconProperty; Jenkins.getInstance().getItemByFullName(\"'+job+'\", AbstractItem).addProperty(new CustomIconProperty(\"' +icon+ '\"))'
	call(['curl', '-sS', '-d', 'script='+script, '-X', 'POST', jenkinsMasterUserName+':'+jenkinsMasterUserApiKey+'@'+jenkinsMasterAddress+jenkinsSuffix+'scriptText'], logger)
	
	
osName = ""
if os.name == 'java':
	import java.lang.System
	osName = java.lang.System.getProperty("os.name")
	fileSeparator = java.lang.System.getProperty("file.separator")
	lineSeparator = java.lang.System.lineSeparator()
	scriptType = "bat" #todo:make separate section to init os-dependent vals
else:
	if os.name == 'posix':
		osName = os.name
		fileSeparator = "/"
		lineSeparator = "\n"
		scriptType = "sh"
	else:
		osName = os.name
		fileSeparator = "\\"
		lineSeparator = "\n"
		scriptType = "bat"
				

if osName.find("posix") == -1:
	import fcntl_win
	fcntl_instance = fcntl_win
else:
	import fcntl
	fcntl_instance = fcntl
		
logSeparator = "=========================================="
secretKeySize = 64

installCommand = 'yum' #for linux only
jenkinsMasterAddress = "54.164.23.220:8080"
jenkinsMasterUserName = "autoregister"
jenkinsMasterUserApiKey = "751b484e997ed0eefdf4d45023afe3ee"
jenkinsSuffix = "/jenkins/"

# id of icons in jenkins repo
winIcon = 'e62237c91d0b62878807ecb010ab991e85f41db7.png'
linuxIcon = 'e08a9d64a9291c8c24904e6747be18e05f099205.png'

if osName.find("Windows") == -1 and osName.find("nt") == -1:
	jenkinsSlaveNodeName = socket.gethostname()
	icon = linuxIcon
else:
	jenkinsSlaveNodeName = os.getenv("COMPUTERNAME")
	icon = winIcon
jenkinsSlaveJnlpSecret = ""
jobGenerator = "migrateEc2_JobGenerator"
skip_job_creation = False
skip_user_check = False
slaveLabel = ""
verbose = False

jenkinsPath = os.getcwd() + fileSeparator
if osName.find("Windows") != -1:
	javaPath = jenkinsPath + "jre" + fileSeparator + "bin" + fileSeparator
else:
	javaPath = jenkinsPath + "jre" + fileSeparator + "bin" + fileSeparator
timeout = 40

try:
	logger=logging.getLogger('main')
	logger.setLevel(logging.DEBUG)
	userFormat=logging.Formatter('%(message)s','%Y-%m-%d %H:%M:%S')  	
	logFormat=logging.Formatter('%(asctime)s.%(msecs)d %(levelname)s in \'%(module)s\' at line %(lineno)d: %(message)s','%Y-%m-%d %H:%M:%S')  	
		
	handler=logging.StreamHandler(sys.stderr)
	handler.setFormatter(userFormat)
	handler.setLevel(logging.INFO)
	logger.addHandler(handler)

	handler=logging.FileHandler(logPath, 'a')
	handler.setLevel(logging.DEBUG)
	handler.setFormatter(logFormat)
	logger.addHandler(handler) 

	# TODO: use argpars in python version
	if __name__ == "__main__":
		i = 1;
		while i < len(sys.argv):		
			if sys.argv[i] == "--maddr":
				jenkinsMasterAddress=sys.argv[i+1]
			if sys.argv[i] == "--user":
				jenkinsMasterUserName=sys.argv[i+1]
			if sys.argv[i] == "--apikey":
				jenkinsMasterUserApiKey=sys.argv[i+1]
			if sys.argv[i] == "--suffix":
				jenkinsSuffix=sys.argv[i+1]
			if sys.argv[i] == "--logfile":
				logPath=sys.argv[i+1]
			if sys.argv[i] == "--jen":
				jenkinsPath=sys.argv[i+1]
			if sys.argv[i] == "--timeout":
				timeout=sys.argv[i+1]
			if sys.argv[i] == "--instcom":
				installCommand=sys.argv[i+1]
			if sys.argv[i] == "--winxp":
				osName="Windows XP"
			if sys.argv[i] == "--nojob":
                                skip_job_creation = True
                        if sys.argv[i] == "--slavelabel":
                                slaveLabel=sys.argv[i+1]
                        if sys.argv[i] == "--javapath":
                                javaPath=sys.argv[i+1]+fileSeparator
                        if sys.argv[i] == "--skipuser":
                                skip_user_check = True
                        if sys.argv[i] == "--verbose":
                                verbose = True
			i = i+1			

        if verbose:
                handler=logging.StreamHandler(sys.stderr)
                handler.setFormatter(userFormat)
                handler.setLevel(logging.DEBUG)
                logger.addHandler(handler)

	if osName.find("posix") == -1:
		logger.info(">>>>>>>> Enabling ICMP...")
		call( ['netsh', 'firewall', 'set', 'icmpsetting', '8'], logger) 
		
	# checking of user credentials
	if skip_user_check == False:
                logger.info(">>>>>>>> ENTER YOUR CLOUDSCRAPER WEB PANEL CREDENTIALS")
                logger.info("You may obtain them at http://www.migrate2iaas.com/saas_register1 if got none yet")
                credentials = check_jenkins_user_credentials("http://" + jenkinsMasterAddress + jenkinsSuffix, 3)
                jenkins_user_name = credentials.user_name
                jenkins_instance = credentials.instance
        else:
                jenkins_user_name = "System"
	
	jenkinsSlaveNodeName = jenkins_user_name + "-" + jenkinsSlaveNodeName
	jenkinsSlaveURL = "http://" + jenkinsMasterAddress + jenkinsSuffix +"computer/"+ jenkinsSlaveNodeName
	
	# creating node and job on jenkins
	logger.info(">>>>>>>> Registering new node...")
	call(['curl', '-sS', '-d', 'script=import jenkins.model.* ; import hudson.model.* ; import hudson.slaves.* ; Jenkins.instance.addNode(new hudson.slaves.DumbSlave(\"' + jenkinsSlaveNodeName + '\", \"' + jenkinsSlaveNodeName + '\", \"'\
              + jenkinsPath.replace(fileSeparator, fileSeparator + fileSeparator) + '\",\"1\",Node.Mode.NORMAL,\"' + slaveLabel+\
              '\",new JNLPLauncher(),new RetentionStrategy.Always(),new LinkedList()))', '-X', 'POST', jenkinsMasterUserName+':'+jenkinsMasterUserApiKey+'@'+jenkinsMasterAddress+jenkinsSuffix+'scriptText'], logger)
	
	if skip_job_creation==False:
                logger.info(">>>>>>>> Registering new tasks for node...")
                call([ 'curl', '-sS', '-d', '', '-X', 'POST', jenkinsMasterUserName+':'+jenkinsMasterUserApiKey+'@'+jenkinsMasterAddress+jenkinsSuffix+'job/'+jobGenerator+'/build', '--data-urlencode', 'json={\"parameter\":[{\"name\":\"Node\",\"value\":\"'+jenkinsSlaveNodeName+'\"}]}'], logger)
                logger.info(">>>>>>>> Getting the connection settings...")
                # wait for 15 sec till project is created
                time.sleep(15)
                #setting os icon
                logger.info(">>>>>>>> Sending OS info")
                set_job_icon(jenkinsSlaveNodeName+'-migrate', icon)
	
	# downloading the secret key for jenkins client
	try:
		success = True
		p = subprocess.Popen(['curl', '-sS', '-d', 'script=println jenkins.slaves.JnlpSlaveAgentProtocol.SLAVE_SECRET.mac(\''+jenkinsSlaveNodeName+'\')', '-X', 'POST', jenkinsMasterUserName+':'+jenkinsMasterUserApiKey+'@'+jenkinsMasterAddress+jenkinsSuffix+'scriptText'], stderr = subprocess.PIPE, stdout = subprocess.PIPE, universal_newlines=True )
		p.wait()
		logger.debug("curl stderr: " + p.stderr.read())
		s = ' '
		try:
			s = p.stdout.readline()		
			jenkinsSlaveJnlpSecret = s.rstrip()
		except AttributeError:
			logger.info(">>>>>>>> Failed connecting to the control panel " + jenkinsMasterAddress+jenkinsSuffix )
			success = False
			
		if len(jenkinsSlaveJnlpSecret) != 64:
			logger.info(">>>>>>>> Failed connecting to the control panel")
			success = False
		masterResponse = s
		s = ' ' 
		while s: 
			try:
				s = p.stderr.readline()
				masterResponse += s			
			except AttributeError:
				logger.warn("Can't read stderr")
				break
		logger.debug(masterResponse)
		if not success:
			exit(1)
	except Exception:
		logger.debug(sys.exc_info()[1])
		logger.info("!!! Critical error. See details in log file " + logPath)
		exit(1)

	logger.info(">>>>>>>> Downloading Jenkins slave binary...")	
	try:
		response = urllib.urlopen("http://" + jenkinsMasterAddress + jenkinsSuffix+"jnlpJars/slave.jar").read()
		file = open("slave.jar", "wb")
		file.write(response)
		file.close()
	except Exception:
		logger.debug(sys.exc_info()[1])	
		logger.info(">>>>>>>> Critical error. Details see in log file")
		exit(1)
	file.close()	
	logger.debug("Downloaded slave.jar")

	nodePath = jenkinsPath + fileSeparator + 'node.' + scriptType	
	nodebat = open(nodePath, "w")
	#nodebat.write("D: " + lineSeparator)
	if osName.find("posix") == -1:
                nodebat.write("cd " + jenkinsPath + lineSeparator)
		nodebat.write('"' + javaPath + 'java" -jar slave.jar -jnlpUrl ' + jenkinsSlaveURL + "/slave-agent.jnlp -secret " + jenkinsSlaveJnlpSecret + " >> " + nodePath + "slave.log 2> " + nodePath + "slave.error.log")
	else:
		nodebat.write(LSB_header)
		nodebat.write(javaPath + 'java -jar ' + jenkinsPath + '/slave.jar -jnlpUrl ' + jenkinsSlaveURL + "/slave-agent.jnlp -secret " + jenkinsSlaveJnlpSecret + " & >> " + nodePath + "slave.log 2> " + nodePath + "slave.error.log")
	nodebat.close()
	logger.info(">>>>>>>> Created node." + scriptType)

	logger.info(">>>>>>>> Registering to run at system startup")
	if osName.find("posix") == -1:	
		if osName == 'Windows XP':
			call("schtasks /create /tn \"JenkinsSlave\" /tr \"cmd.exe /c " + nodePath + ' >> ' + nodePath + '.log" /sc onstart /ru System', logger)
		else:
			call("schtasks /create /F /tn \"JenkinsSlave\" /tr \"cmd.exe /c " + nodePath + ' >> ' + nodePath + '.log" /sc onstart /ru System', logger)
		call("schtasks /run /tn \"JenkinsSlave\"", logger)
	else:
		try:
			shutil.copyfile(nodePath, r'/etc/init.d/cloudscraper')		
		except IOError:
			logger.debug(sys.exc_info()[1])
			logger.info(">>>>>>>> Critical error")
			exit(1)
		os.chmod('/etc/init.d/cloudscraper', stat.S_IEXEC)
		os.chown('/etc/init.d/cloudscraper', 0, 0)
		if installCommand == 'yum':
			call(['chkconfig', '--level', '2345', 'cloudscraper', 'on'], logger)
		else:
			call(['update-rc.d', 'cloudscraper', 'defaults'], logger)
			call(['update-rc.d', 'cloudscraper', 'enable'], logger)		
		call(['service', 'cloudscraper', 'start'], logger)	
	logger.debug("Registered the agent")
	
	if osName.find("posix") == -1:
		logger.info(">>>>>>>> Updating system time")
		call(['net', 'start', 'w32time'], logger)
		call(['w32tm', '/config', '/syncfromflags:MANUAL', '/manualpeerlist:time.windows.com,time-a.nist.gov,time-b.nist.gov'], logger)
		call(['w32tm', '/config', '/update'], logger)
		logger.debug("Time updated")	
		
	
	# Checking connection
	for i in range(0, timeout, 1):
		try:			
			logger.info(">>>>>>>> Estabilishing connection...")
			try:
				isOffline = jenkins_instance.get_node_info(jenkinsSlaveNodeName)["offline"]
				if not isOffline:
					logger.info(">>>>>>>> Connected. Proceed to Cloudscraper Web Panel at " + jenkinsMasterAddress + jenkinsSuffix + " to set up the agent tasks.")
					exit(0)
			except Exception:
				if str(sys.exc_info()[1]).find("URLError") != -1:
					logger.info(">>>>>>>> Failed connecting to the server")
					exit(1)					
		except Exception:
			logger.debug(sys.exc_info()[1])	
			logger.info("!!! Critical error. Please see details in log file " + logPath)
			exit(1)		
		time.sleep(20)
	logging.warning("!!! Timeout checking for connection. Please contact support via support@migrate2iaas.com or support portal at http://www.migrate2iaas.com/support_portal ")
		
except IOError:
	logger.info(">>>>>>>> File error")
	
