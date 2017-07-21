@echo off

:: PREDEFINED PARMS FOR THE DEMO PANEL
if "%JENKINS_MASTER_ADDR%"=="" set JENKINS_MASTER_ADDR=54.164.23.220:8080
if "%JENKINS_MASTER_USER_NAME%"=="" set JENKINS_MASTER_USER_NAME=autoregister
if "%JENKINS_MASTER_USER_APIKEY%"=="" set JENKINS_MASTER_USER_APIKEY=751b484e997ed0eefdf4d45023afe3ee

:: GET DOMAIN NAME
for /f "tokens=1-3 delims= " %%d in ('systeminfo ^| findstr /B /C:"Domain"') do set machinedomain=%%e

:: PRELOAD NAME, ADD MACHINE DOMAIN IF PRESENT
set JENKINS_SLAVE_NODE_NAME=%MACHINEDOMAIN%-%COMPUTERNAME%
if "%MACHINEDOMAIN%"=="WORKGROUP" set JENKINS_SLAVE_NODE_NAME=%COMPUTERNAME%


set JENKINS_SLAVE_JNLP_SECRET=
set GENERATOR_JOB=migrateEc2_JobGenerator

set LOCALPATH=%~dp0
set LOCALPATH=%LOCALPATH:~0,-1%
set LOGFILE="%~dp0\cloudscraper-auto-install.log"
set JAVALOGFILE=.\java-auto-install.log
set JENKINSPATH=%LOCALPATH:\=\\%
set JAVAPATH=%~dp0\jre



:: Enable ping to keep heartbeat
echo Enabling ICMP...
netsh firewall set icmpsetting 8 >> %LOGFILE% 2>&1

:: obtaining parms, if they are not pre-defined, prompt
if "%JENKINS_MASTER_ADDR%"=="" set /p JENKINS_MASTER_ADDR="Enter the migration master address e.g. http://72.58.33.45:8080: " 
if "%JENKINS_MASTER_USER_NAME%"=="" set /p JENKINS_MASTER_USER_NAME="Authorize to migration master, enter username : " 
if "%JENKINS_MASTER_USER_APIKEY%"=="" set /p JENKINS_MASTER_USER_APIKEY="Authorize to migration master, enter API key: "
if "%JENKINS_SLAVE_NODE_NAME%"=="" set /p JENKINS_SLAVE_NODE_NAME="Enter Jenkins slave name: " 

echo =============================
echo ENTER YOUR PANEL CREDENTIALS
echo =============================

set /p JENKINS_USERNAME="Please enter you migration panel username:"

set /p JENKINS_PASSWORD="Please enter you migration panel password:"

set JENKINS_SLAVE_NODE_NAME=%JENKINS_USERNAME%-%JENKINS_SLAVE_NODE_NAME%

echo "==========================================" >> %LOGFILE%
::Try to create new job and get JNLP
echo Registering new node...
%~dp0\curl -d "script=import jenkins.model.* ; import hudson.model.* ; import hudson.slaves.* ; Jenkins.instance.addNode(new hudson.slaves.DumbSlave(\"%JENKINS_SLAVE_NODE_NAME%\",\"%JENKINS_SLAVE_NODE_NAME%\",\"%JENKINSPATH%\",\"1\",Node.Mode.NORMAL,\"%MACHINEDOMAIN%\",new JNLPLauncher(),new RetentionStrategy.Always(),new LinkedList())) " -X POST %JENKINS_MASTER_USER_NAME%:%JENKINS_MASTER_USER_APIKEY%@%JENKINS_MASTER_ADDR%/jenkins/scriptText  >> %LOGFILE% 2>&1

echo "==========================================" >> %LOGFILE%

echo Registering new tasks for nodes...
%~dp0\curl -d "" -X POST %JENKINS_MASTER_USER_NAME%:%JENKINS_MASTER_USER_APIKEY%@%JENKINS_MASTER_ADDR%/jenkins/job/%GENERATOR_JOB%/build --data-urlencode json="{\"parameter\":[{\"name\":\"Node\",\"value\":\"%JENKINS_SLAVE_NODE_NAME%\"}]}" >> %LOGFILE% 2>&1

echo Getting the connection settings...
for /f %%i in ('%~dp0\curl -d "script=println jenkins.slaves.JnlpSlaveAgentProtocol.SLAVE_SECRET.mac('%JENKINS_SLAVE_NODE_NAME%')" -X POST %JENKINS_MASTER_USER_NAME%:%JENKINS_MASTER_USER_APIKEY%@%JENKINS_MASTER_ADDR%/jenkins/scriptText') do set JENKINS_SLAVE_JNLP_SECRET=%%i

set JENKINS_SLAVE_URL=http://%JENKINS_MASTER_ADDR%/jenkins/computer/%JENKINS_SLAVE_NODE_NAME%

if "%JENKINS_SLAVE_JNLP_SECRET%"==""  (
echo FAILED CONNECTING TO THE CONTROL PANEL...
pause
exit /B 255
)

:: downloading the slave jar
echo Downloading Jenkins slave binary...
"%~dp0\wget" http://%JENKINS_MASTER_ADDR%/jenkins/jnlpJars/slave.jar -O %JENKINSPATH%\slave.jar -a %LOGFILE%

echo "==========================================" >> %LOGFILE%
echo "Downloaded slave.jar" >> %LOGFILE%
echo "==========================================" >> %LOGFILE%

:: creating node.bat file
set NODEBAT=%JENKINSPATH%\node.bat
echo cd %JENKINSPATH% > %NODEBAT%
echo "%JAVAPATH%\bin\java.exe" -jar slave.jar -jnlpUrl %JENKINS_SLAVE_URL%/slave-agent.jnlp -secret %JENKINS_SLAVE_JNLP_SECRET% ^>^> %NODEBAT%slave.log 2^> %NODEBAT%slave.error.log >> %NODEBAT%

echo "==========================================" >> %LOGFILE% 
echo "Created note.bat" >> %LOGFILE%
echo "==========================================" >> %LOGFILE%

:: registering node.bat as a startup file
echo Set agent to run at system startup...
schtasks /create /F /tn "JenkinsSlave" /tr "cmd.exe /c %NODEBAT% >> %NODEBAT%.log" /sc onstart /ru System >> %LOGFILE% 2>&1
schtasks /run /tn "JenkinsSlave"

echo "==========================================" >> %LOGFILE%
echo "Registered the agent" >> %LOGFILE%
echo "==========================================" >> %LOGFILE%

:: updating time
echo Updating system time...
net start w32time
w32tm /config /syncfromflags:MANUAL /manualpeerlist:time.windows.com,time-a.nist.gov,time-b.nist.gov
w32tm /config /update 

echo "==========================================" >> %LOGFILE%
echo "Time updated" >> %LOGFILE%
echo "==========================================" >> %LOGFILE%

:: updating time
echo Updating system time...
net start w32time
w32tm /config /syncfromflags:MANUAL /manualpeerlist:time.windows.com,time-a.nist.gov,time-b.nist.gov
w32tm /config /update 

echo "==========================================" >> %LOGFILE%
echo "Time updated" >> %LOGFILE%
echo "==========================================" >> %LOGFILE%

:: waiting till slave is registered
echo Registering the Agent in Web Console...

:WAIT_AGAIN
if exist %JENKINSPATH%\workspace (
goto :END
)
timeout /t 50 /nobreak 
goto :WAIT_AGAIN

:END
echo ----------------------------------------------------------------------------------------------------------------
echo Success! Browse to Web Console to start the server migration.
echo ----------------------------------------------------------------------------------------------------------------
pause