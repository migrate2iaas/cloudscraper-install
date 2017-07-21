@ECHO OFF & SetLocal EnableDelayedExpansion enableextensions
ECHO *********************************************************************************
ECHO STARTING THE MIGRATION PROCESS FROM %SOURCE% TO %TARGET%
ECHO *********************************************************************************
REM  ########## Set All Variables #######
set FILE=revision
set PIPLELINE_DIR=C:\AutoTestMaterial
if exist "C:\Program Files (x86)\Migrate2iaas\Cloudscraper\CloudScraper.exe" (
 	set HOME_DIR="C:\Program Files (x86)\Migrate2iaas\Cloudscraper"
 	set TRANSFER_CONFIG_INI="C:\Program Files (x86)\Migrate2iaas\Cloudscraper\transfer.ini"
 	CALL :dequote HOME_DIR
	CALL :dequote TRANSFER_CONFIG_INI
        goto print
 	Goto :eof
    ) else (
        set HOME_DIR="C:\Program Files\Migrate2iaas\Cloudscraper"
        set TRANSFER_CONFIG_INI="C:\Program Files\Migrate2iaas\Cloudscraper\transfer.ini"
 	CALL :dequote HOME_DIR
	CALL :dequote TRANSFER_CONFIG_INI
 	goto print
 	Goto :eof 
    )
:DeQuote
for /f "delims=" %%A in ('echo %%%1%%') do set %1=%%~A
Goto :eof
:print
set PATH=%PATH%;%CLOUDSCRAPER_DIR%\3rdparty\Portable_Python_2.7.3.1\App
set IMAGE_PATH=C:\cloudscraper-images
set WGETPATH=C:\Windows
set CURLPATH=C:\Windows\System32

REM  ##########  Get Wget.exe from SVN location #######
echo ">>>>>>>>>>>>>>>>>" Copy Wget
copy "%PIPLELINE_DIR%\wget.exe" "%WGETPATH%"

REM  ##########  Get Curl.exe from SVN location #######
echo ">>>>>>>>>>>>>>>>>" Copy Curl
copy "%PIPLELINE_DIR%\curl.exe" "%CURLPATH%"

if "%SOURCE%" EQU "" goto :eof
if %SOURCE% EQU AWS GOTO AWS
if %SOURCE% EQU ElasticHost GOTO ElasticHost
if %SOURCE% EQU CloudSigma GOTO CloudSigma
if %SOURCE% EQU Azure GOTO Azure
goto :eof
:AWS
Echo ">>>>>>>>>>>>>>>>>" Start %SOURCE% Source
echo curl -k -u 434b6010-6509-4b8e-ab7a-9bbfcacbeed8:C4Db9bu2g4WMJHkwdyL7yLA73Zy7nxwbMMSKEuUv https://api.ams-e.elastichosts.com/servers/4925d97d-700a-4dd2-a3e2-08a50c6a95f0/start
GOTO CONTINUE
:ElasticHost
Echo ">>>>>>>>>>>>>>>>>"  Start %SOURCE% Source
echo curl -k -u 434b6010-6509-4b8e-ab7a-9bbfcacbeed8:C4Db9bu2g4WMJHkwdyL7yLA73Zy7nxwbMMSKEuUv --request POST https://api.ams-e.elastichosts.com/servers/4925d97d-700a-4dd2-a3e2-08a50c6a95f0/start
GOTO CONTINUE
:CloudSigma
Echo ">>>>>>>>>>>>>>>>>"  Start %SOURCE% Source
curl -k -u 434b6010-6509-4b8e-ab7a-9bbfcacbeed8:C4Db9bu2g4WMJHkwdyL7yLA73Zy7nxwbMMSKEuUv --request POST https://api.ams-e.elastichosts.com/servers/4925d97d-700a-4dd2-a3e2-08a50c6a95f0/start
GOTO CONTINUE
:Azure
Echo ">>>>>>>>>>>>>>>>>" Start %SOURCE% Source
echo curl -k -u 434b6010-6509-4b8e-ab7a-9bbfcacbeed8:C4Db9bu2g4WMJHkwdyL7yLA73Zy7nxwbMMSKEuUv https://api.ams-e.elastichosts.com/servers/4925d97d-700a-4dd2-a3e2-08a50c6a95f0/start
GOTO CONTINUE
:CONTINUE
REM  ########## Get Previous Version #######
cd /D "%HOME_DIR%\Migrate"
set content=
for /F "delims=" %%i in (%FILE%) do set content=!content! %%i
echo ">>>>>>>>>>>>>>>>>" Previous Version : %content%
REM  ########## Deleting existing Migrate2iaas folder #######
ECHO ">>>>>>>>>>>>>>>>>" Deleting existing Migrate2iaas folder...
cd ..\..\..
RMDIR /S /Q c:Migrate2iaas
REM  ##########  Deleting existing cloudscraper-installer.exe #######
ECHO ">>>>>>>>>>>>>>>>>" Deleting existing cloudscraper-installer.exe...
cd /D %PIPLELINE_DIR%
DEL cloudscraper-installer.exe
REM  ##########  Downloading cloudscraper-installer.exe #######
ECHO ">>>>>>>>>>>>>>>>>" Downloading cloudscraper-installer.exe
wget ftp://ec2-107-20-170-219.compute-1.amazonaws.com/installer/cloudscraper-installer.exe
REM  ##########  Installing cloudscraper-installer.exe #######
ECHO ">>>>>>>>>>>>>>>>>" Installing cloud scraper.....
cloudscraper-installer.exe /S
REM  ##########  Get Current Version #######
cd /D "%HOME_DIR%\Migrate"
set content=
for /F "delims=" %%i in (%file%) do set content=!content! %%i
echo ">>>>>>>>>>>>>>>>>" Current Version : %content%
REM  ##########  Delete Old Image #######
echo ">>>>>>>>>>>>>>>>>" Deleting Existing VHD's
cd /D %IMAGE_PATH%
DEL /Q *.*
REM  ##########  Get Transfer.ini from SVN location #######
echo ">>>>>>>>>>>>>>>>>" Copy EC2 INI
copy "%PIPLELINE_DIR%\transfer.ini" "%HOME_DIR%"
REM  ##########  Get OS Information and Target #######
echo ">>>>>>>>>>>>>>>>>" The Cloud Server It Was Run on
systeminfo | findstr /B /C:"OS Name" /C:"OS Version"
cd /D %HOME_DIR%
set lines=1 2
set curr=1
for /f "delims=" %%a in ('type transfer.ini') do (
    for %%b in (!lines!) do (
        if !curr!==%%b echo %%a
    )
    set /a "curr = curr + 1"
)

cd /d %HOME_DIR%
set PATH=%PATH%;%HOME_DIR%\3rdparty\Portable_Python_2.7.3.1\App
cd /d "%HOME_DIR%\Migrate\Migrate"

if "%TARGET%" EQU "" goto :eof
if %TARGET% EQU AWS GOTO AWS
if %TARGET% EQU ElasticHost GOTO ElasticHost
if %TARGET% EQU CloudSigma GOTO CloudSigma
if %TARGET% EQU Azure GOTO Azure
goto :eof
:AWS
Echo ">>>>>>>>>>>>>>>>>" Migrating to the %TARGET% Cloud
..\..\3rdparty\Portable_Python_2.7.3.1\App\python.exe migrate.pyc -c "%TRANSFER_CONFIG_INI%" -k "%SECRET_KEY%"
GOTO CONTINUE
:ElasticHost
Echo ">>>>>>>>>>>>>>>>>" Migrating to the %TARGET% Cloud
..\..\3rdparty\Portable_Python_2.7.3.1\App\python.exe migrate.pyc -c "%TRANSFER_CONFIG_INI%" -e "%SECRET_KEY%"
GOTO CONTINUE
:CloudSigma
Echo ">>>>>>>>>>>>>>>>>" Migrating to the %TARGET% Cloud
echo ..\..\3rdparty\Portable_Python_2.7.3.1\App\python.exe migrate.pyc -c "%TRANSFER_CONFIG_INI%" -e "%SECRET_KEY%"
GOTO CONTINUE
:Azure
Echo ">>>>>>>>>>>>>>>>>" Migrating to the %TARGET% Cloud
echo ..\..\3rdparty\Portable_Python_2.7.3.1\App\python.exe migrate.pyc -c "%TRANSFER_CONFIG_INI%" -e "%SECRET_KEY%"
GOTO CONTINUE
:CONTINUE

if "%SOURCE%" EQU "" goto :eof
if %SOURCE% EQU AWS GOTO AWS
if %SOURCE% EQU ElasticHost GOTO ElasticHost
if %SOURCE% EQU CloudSigma GOTO CloudSigma
if %SOURCE% EQU Azure GOTO Azure
goto :eof
:AWS
Echo ">>>>>>>>>>>>>>>>>" Stop %SOURCE% Source
echo curl -k -u 434b6010-6509-4b8e-ab7a-9bbfcacbeed8:C4Db9bu2g4WMJHkwdyL7yLA73Zy7nxwbMMSKEuUv https://api.ams-e.elastichosts.com/servers/4925d97d-700a-4dd2-a3e2-08a50c6a95f0/stop
GOTO CONTINUE
:ElasticHost
Echo ">>>>>>>>>>>>>>>>>"  Stop %SOURCE% Source
echo curl -k -u 434b6010-6509-4b8e-ab7a-9bbfcacbeed8:C4Db9bu2g4WMJHkwdyL7yLA73Zy7nxwbMMSKEuUv --request POST https://api.ams-e.elastichosts.com/servers/4925d97d-700a-4dd2-a3e2-08a50c6a95f0/stop
GOTO CONTINUE
:CloudSigma
Echo ">>>>>>>>>>>>>>>>>"  Stop %SOURCE% Source
echo curl -k -u 434b6010-6509-4b8e-ab7a-9bbfcacbeed8:C4Db9bu2g4WMJHkwdyL7yLA73Zy7nxwbMMSKEuUv https://api.ams-e.elastichosts.com/servers/4925d97d-700a-4dd2-a3e2-08a50c6a95f0/stop
GOTO CONTINUE
:Azure
Echo ">>>>>>>>>>>>>>>>>" Stop %SOURCE% Source
echo curl -k -u 434b6010-6509-4b8e-ab7a-9bbfcacbeed8:C4Db9bu2g4WMJHkwdyL7yLA73Zy7nxwbMMSKEuUv https://api.ams-e.elastichosts.com/servers/4925d97d-700a-4dd2-a3e2-08a50c6a95f0/stop
GOTO CONTINUE
:CONTINUE
@endlocal
ECHO *********************************************************************************
ECHO ALL DONE MIGRATED INTO %TARGET%
ECHO *********************************************************************************
EXIT