import urllib
import os, sys
import subprocess
import logging, logging.handlers
import datetime, time
import argparse

class OSExecutor:
	fcntl_instance = None
	
	def __init__(self):
		if osName.find("posix") == -1:
			import fcntl_win
			fcntl_instance = fcntl_win
		else:
			import fcntl
			fcntl_instance = fcntl

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
			while s: 
				try:				
					s = non_block_read(p.stdout)
					logger.debug(s)						
				except AttributeError:		
					break
			s = ' '
			while s: 
				try:
					s = non_block_read(p.stderr)
					logger.debug(s)			
				except AttributeError:		
					break	
		except Exception:
			logger.debug(sys.exc_info()[1])
			logger.critical("!!! Critical error. See details in log file " + logPath)
			sys.exit(1)

class SystemInfo():
	os_name=None
	file_separator=None
	line_separator=None
	script_type=None
	sysinfo.log_separator = "==========================================")
	
	def __init__(self):
		if os.name == 'java':
			import java.lang.System
			os_name = java.lang.System.getProperty("os.name")
			self.file_separator = java.lang.System.getProperty("file.separator")
			self.line_separator = java.lang.System.sysinfo.lineSeparator()
			self.script_type = "bat" 
		else:
			if os.name == 'posix':
				self.os_name = os.name
				self.file_separator = "/"
				self.line_separator = "\n"
				self.script_type = "sh"
			else:
				self.os_name = os.name
				self.file_separator = "\\"
				self.line_separator = "\n"
				self.script_type = "bat" 
	
	def is_win():
		if os_name != "posix":
			return True
		else:
			return False
				
def get_parameters():
	parser = argparse.ArgumentParser()
	parser.add_argument("--homedir", dest="home_directory", default="")
	parser.add_argument("--ini_name", dest="ini_file_name", default="transfer")
	parser.add_argument("--branch", dest="branch", default="master")
	parser.add_argument("--reupload", dest="reupload", action="store_true")
	parser.add_argument("--quickupd", dest="quick_update", action="store_true") 
	parser.add_argument("--extraparms", dest="extra_migrate_parms", default="-b 25")
	parser.add_argument("--nordp", dest="no_rdp_check", action="store_true")
	return parser.parse_args()

def get_logger():
	logger.setLevel(logging.DEBUG)
	userFormat=logging.Formatter('%(message)s','%Y-%m-%d %H:%M:%S')  	
	logFormat=logging.Formatter('%(asctime)s.%(msecs)d %(levelname)s in \'%(module)s\' at line %(lineno)d: %(message)s','%Y-%m-%d %H:%M:%S')  	
		
	handler=logging.StreamHandler(sys.stderr)
	handler.setFormatter(userFormat)
	handler.setLevel(logging.DEBUG)
	logger.addHandler(handler)
'''
	handler=logging.FileHandler(logPath, 'a')
	handler.setLevel(logging.DEBUG)
	handler.setFormatter(logFormat)
	logger.addHandler(handler) 
'''
	return logger

try:
	osexec = OSExecutor()
	sysinfo = SystemInfo()	
	fs = sysinfo.file_separator
	logger = get_logger()
	parameters = get_parameters()
	
	logger.info('*********************************************************************************')
	logger.info('AUTOTEST ENVIRONMENT SETUP')
	logger.info('*********************************************************************************')
	
	home_directory = parameters.home_directory
	ini_name = parameters.ini_file_name
	reupload = parameters.reupload
	branch = parameters.branch
	quick_update = parameters.quick_update
	
	########## Set All Variables #######
	revision_path = home_directory + fs + "Migrate" + fs + "revision"
	# the pipeline dir is directory the scripts was run from
	pipeline_dir = os.getcwd() + fs os.getcwd
	logger.info('Pipeline dir is 'pipeline_dir)
	
	logger.info('Updating  time **************')
	osexec.call(['net', 'start', 'w32time'], logger)
	osexec.call(['w32tm', '/config', '/syncfromflags:MANUAL', '/manualpeerlist:time-a.nist.gov,time-b.nist.gov'], logger)
	osexec.call(['w32tm', '/config', '/update'], logger)
	logger.info("Local date is " + datetime.datetime.now())
	logger.info("Updated time **************")
	
	# set home directory
	if home_directory == "":
		if os.getenv("PROCESSOR_ARCHITEW6432") == "AMD64":
			home_directory=os.getenv("ProgramFiles(x86)") + fs + "Migrate2iaas" + fs + "Cloudscraper"
		if os.getenv("PROCESSOR_ARCHITECTURE").find("AMD64") != -1:
			home_directory=os.getenv("ProgramFiles(x86)") + fs + "Migrate2iaas" + fs + "Cloudscraper"	
		else:
			home_directory="C:\Program Files\Migrate2iaas\Cloudscraper"
			
	logger.info("Installation dir is " + home_directory)
	os.mkdir(home_directory, 0755);
	
	ini_name = ini_name + ".ini"
	transfer_config_ini = home_directory + fs + ini_name
	logger.info(transfer_config_ini)
	
	image_path = "C:\cloudscraper-images"
	wget_path="C:\Windows"
	
	extra_migrate_parms = parameters.extra_migrate_parms
	if not parameters.no_rdp_check:
		extra_migrate_parms = extra_migrate_parms + " -t"
		
	logger.info("Testing branch %branch%")
	
	installer_download_path = "ftp://ec2-54-204-35-129.compute-1.amazonaws.com/installer/%branch%/cloudscraper-installer.exe"
	quick_updatePath = "ftp://ec2-54-204-35-129.compute-1.amazonaws.com/compiled/%branch%/Migrate"

	##########  Copy Autotest Config from SVN location #######
	logger.info(">>>>>>>>>>>>>>>>> Copy Autotest Config")

	auto_test_conf_path = pipeline_dir + fs + "auto_test_config.txt"
	try:
		shutil.copyfile(auto_test_conf_path, home_directory)
	except IOError:
		logger.debug(sys.exc_info()[1])
		logger.info("Can't copy file auto_test_config.txt")
		exit(1)
		if not sysinfo.is_win:
			os.chmod(auto_test_conf_path)
			os.chown(auto_test_conf_path, 0, 0)

	##########  Get Wget.exe from SVN location #######
	auto_test_conf = open(auto_test_conf_path, "r")
	SOURCE = auto_test_conf.readline()
	TARGET = auto_test_conf.readline()
	SECRET_KEY = auto_test_conf.readline()
	auto_test_conf.close()

	logger.info("*********************************************************************************")
	logger.info(" STARTING MIGRATION PROCESS FROM %SOURCE% TO %TARGET%")
	logger.info("*********************************************************************************")

	########## Get Previous Version #######
	revision_file = open(revision_path, 'r')
	content = revision_file.readline()
	revision_file.close()
	logger.info(">>>>>>>>>>>>>>>>> Previous Version : " + content)

	########## Deleting  previous logs #######
	logger.info(">>>>>>>>>>>>>>>>> Deleting previous logs")
	try:
		os.remove(pipeline_dir + fs + "logs")
	except IOError:
		logger.debug(sys.exc_info()[1])
		logger.info("Can't delete previous logs ")

	########## Deleting  previous logs #######
	logger.info(">>>>>>>>>>>>>>>>> Deleting previous logs")
	try:
		os.remove(home_directory + fs + "logs")
	except IOError:
		logger.debug(sys.exc_info()[1])
		logger.info("Can't delete previous logs")
	
	if not quick_update:
		########## Deleting existing Migrate2iaas folder #######
		logger.info(">>>>>>>>>>>>>>>>> Deleting existing Migrate2iaas folder... ")
		try:
			os.remove("C:\\Migrate2iaas")
		except IOError:
			logger.debug(sys.exc_info()[1])
			logger.info("Can't delete existing Migrate2iaas folder")
		
		##########  Deleting existing cloudscraper-installer.exe #######
		logger.info(">>>>>>>>>>>>>>>>> Deleting existing cloudscraper-installer.exe...")
		try:
			os.remove(pipeline_dir + fs + "cloudscraper-installer.exe")
		except IOError:
			logger.debug(sys.exc_info()[1])
			logger.info("Can't delete existing cloudscraper-installer.exe ")
			
		##########  Downloading cloudscraper-installer.exe #######
		logger.info(">>>>>>>>>>>>>>>>> Downloading cloudscraper-installer.exe branch: " + branch)	
		try:
			response = urllib.urlopen(installer_download_path).read()
			installerFile = open(pipeline_dir + fs + "cloudscraper-installer.exe", "wb")
			installerFile.write(response)
			installerFile.close()
		except Exception:
			logger.debug(sys.exc_info()[1])	
			logger.info("Can't download cloudscraper-installer.exe")
			exit(1)
		installerFile.close()	
		logger.debug("Downloaded cloudscraper-installer.exe")
		
		##########  Installing cloudscraper-installer.exe #######
		logger.info(">>>>>>>>>>>>>>>>> Installing cloudscraper.....")
		osexec.call(['cloudscraper-installer.exe', '/S'], logger)
	else:
		logger.info(">>>>>>>>>>>>>>>> Performing quick code update of the existing installation")
		osexec.call([pipeline_dir  + fs +  "Tools" + fs + "wget", '-N', '--no-parent', '-r', '-nH', '--cut-dirs=2', quick_updatePath], logger)

except IOError:
	logger.info("File error")
	
##########  Get Current Version #######
revision_file = open(revision_path, 'r')
content = revision_file.readline()
revision_file.close()
logger.info(">>>>>>>>>>>>>>>>> Current Version : " + content)

if not reupload:
	##########  Delete Old Image #######
	logger.info(">>>>>>>>>>>>>>>>> Deleting Existing IMAGE") 
	try:
		os.remove(image_path)
	except:
		logger.debug(sys.exc_info()[1])
		logger.info("Can't delete old image")

##########  Get Transfer.ini from SVN location #######
logger.info(">>>>>>>>>>>>>>>>> Copy " + TARGET + " INI")
try:
	shutil.copyfile(pipeline_dir + fs + ini_name, home_directory)
except IOError:
	logger.debug(sys.exc_info()[1])
	logger.info("Can't copy file " + ini_name)
	exit(1)

##########  Get OS Information and Target #######
logger.info(">>>>>>>>>>>>>>>>> The " + SOURCE + " Source Server It is Running on " + os.name)
ini_file = open(home_directory + fs + ini_name, 'r')
s = ' '
while s: 
	s = ini_file.readline()
	logger.info(s)		
		
migrateError = 0
cd /d %HOME_DIR%
set PATH=%PATH%; %HOME_DIR%\3rdparty\Portable_Python_2.7.3.1\App
cd /d %HOME_DIR%\Migrate\Migrate
if reupload: 
	extra_migrate_parms = extra_migrate_parms + "-u"

if TARGET == "":
	logger.info(">>>>>>>>>>>>>>>>> CONFIG_ERROR: NO TARGET FOUND!!!")
	exit(255)

logger.info(">>>>>>>>>>>>>> Try default config")
logger.info(">>>>>>>>>>>>>>>>> Migrating to the " + TARGET + " Cloud")
osexec.call([home_directory + fs + "3rdparty" + fs + "Portable_Python_2.7.3.1" + fs + "App" + fs + "python", 'migrate.pyc', '-c', transfer_config_ini, '-w', SECRET_KEY, extra_migrate_parms], logger)


if ERRORLEVEL 1 (
ECHO *********************************************************************************
ECHO  Got ERROR MIGRATING INTO %TARGET% - publishing logs to Jenkins 
ECHO *********************************************************************************
 mkdir "%PIPLELINE_DIR%\logs"
 copy /Y "%HOME_DIR%\logs" "%PIPLELINE_DIR%\logs"
 
 GOTO eof_error
) else (
ECHO *********************************************************************************
ECHO ALL DONE MIGRATED INTO %TARGET%
ECHO *********************************************************************************
)


@endlocal
EXIT /B %MIGRATE_ERROR%

:eof_error
echo GOT ERROR
exit /B 255
