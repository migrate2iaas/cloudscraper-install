@ECHO OFF 
SetLocal EnableDelayedExpansion enableextensions

ECHO *********************************************************************************
ECHO AUTOTEST ENVIRONMENT SETUP 
ECHO *********************************************************************************
REM  ########## Set All Variables #######
set FILE=revision
:: the pipeline dir is directory the scripts was run from
set PIPLELINE_DIR=%~dp0\..\
echo Pipeline dir is %PIPLELINE_DIR%

echo Updating  time **************
net start w32time
w32tm /config /syncfromflags:MANUAL /manualpeerlist:time-a.nist.gov,time-b.nist.gov
w32tm /config /update 
echo Local date is %date%_%time%
echo Updated time **************

::32/64Bit Switch to Set HOME_DIR
if "%HOME_DIR%" == ""  if "%PROCESSOR_ARCHITEW6432%" == "AMD64" set HOME_DIR=%ProgramFiles(x86)%\Migrate2iaas\Cloudscraper
if "%HOME_DIR%" == ""  ECHO %PROCESSOR_ARCHITECTURE%|FINDSTR AMD64>NUL && set HOME_DIR=%ProgramFiles(x86)%\Migrate2iaas\Cloudscraper|| set HOME_DIR=%ProgramFiles%\Migrate2iaas\Cloudscraper

ECHO Installation dir is %HOME_DIR%
mkdir "%HOME_DIR%"


::32/64Bit Switch to Set TRANSFER_CONFIG_INI
if "%SUFFIX%"=="" set SUFFIX=transfer
set INI_NAME=%SUFFIX%.ini
set TRANSFER_CONFIG_INI=%HOME_DIR%\%INI_NAME%
ECHO "%TRANSFER_CONFIG_INI%"

if "%RE_UPLOAD%"=="false" set RE_UPLOAD=

set IMAGE_PATH=C:\cloudscraper-images
if "%ImageDirectory%" neq "" (
set IMAGE_PATH=%ImageDirectory%
)
set WGETPATH=C:\Windows

if "%EXTRA_MIGRATE_PARMS%"=="" set EXTRA_MIGRATE_PARMS= -b 25
if "%NO_RDP_CHECK%"=="" set EXTRA_MIGRATE_PARMS= %EXTRA_MIGRATE_PARMS%  -t  
if NOT "%LOGPATH%"=="" set EXTRA_MIGRATE_PARMS= %EXTRA_MIGRATE_PARMS%  -l "%LOGPATH%"
if "%PYTHONPATH%"=="" set PYTHONPATH=..\..\3rdparty\Python_2.7.10\python.exe

if "%branch%"=="" set branch=master
ECHO Testing branch %branch%

set INSTALLER_DOWNLOAD_PATH=http://migrate2iaas.blob.core.windows.net/cloudscraper-build-result/%branch%/cloudscraper-installer.exe
set QUICK_UPDATE_PATH=ftp://ftp.migrate2iaas.com/compiled/%branch%/Migrate


REM  ##########  Copy Autotest Config from SVN location #######
echo Copy Autotest Config
copy "%PIPLELINE_DIR%\autotestconfig.txt" "%HOME_DIR%"
del /Q "%PIPLELINE_DIR%\autotestconfig.txt"

REM  ##########  Get Wget.exe from SVN location #######
rem echo  Setup the Dependency
rem copy "%PIPLELINE_DIR%\Tools\wget.exe" "%WGETPATH%"

cd /D "%HOME_DIR%"
set lines=1
set curr=1
for /f "delims=" %%a in ('type autotestconfig.txt') do (
    for %%b in (!lines!) do (
        if !curr!==%%b set SOURCE=%%a
    )
    set /a "curr = curr + 1"
)
set lines=2
set curr=1
for /f "delims=" %%a in ('type autotestconfig.txt') do (
    for %%b in (!lines!) do (
        if !curr!==%%b set TARGET=%%a
    )
    set /a "curr = curr + 1"
)
set lines=3
set curr=1
for /f "delims=" %%a in ('type autotestconfig.txt') do (
    for %%b in (!lines!) do (
        if !curr!==%%b set SECRET_KEY=%%a
    )
    set /a "curr = curr + 1"
)


ECHO *********************************************************************************
ECHO STARTING MIGRATION PROCESS FROM %SOURCE% TO %TARGET%
ECHO *********************************************************************************

REM  ########## Get Previous Version #######
cd /D "%HOME_DIR%\Migrate"
set content=
for /F "delims=" %%i in (%FILE%) do set content=!content! %%i
echo "Previous Version : %content%  "

REM  ########## Deleting  previous logs #######
rem ECHO "Deleting previous logs"
rem RMDIR /S /Q c:%PIPLELINE_DIR%\logs

ECHO ^>^>^>^>^>^> Updating Cloudscraper Engine.. 

if "%QUICK_UPDATE%" neq "true" (

cd /D "%PIPLELINE_DIR%"

REM ########## Saving installer changed date
for %%a in (cloudscraper-installer.exe) do (
set FileDate=%%~ta
)

REM  ##########  Downloading cloudscraper-installer.exe #######
ECHO Downloading cloudscraper-installer.exe branch: %branch%
"%PIPLELINE_DIR%\Tools\wget.exe" -N "%INSTALLER_DOWNLOAD_PATH%"

REM ########### Download license  ###################
wget http://migrate2iaas.blob.core.windows.net/cloudscraper-release6/lcns.msg

REM ########## Saving updated installer changed date
for %%a in (cloudscraper-installer.exe) do ( 
set UpdFileDate=%%~ta
)

echo Installer is updated "!FileDate!", current version timestamp is "!UpdFileDate!"

if "!FileDate!" neq "!UpdFileDate!" (
ECHO Performing full update

REM  ########## Deleting existing Migrate2iaas folder #######
ECHO "Deleting existing Migrate2iaas folder... "
cd /D "%HOME_DIR%\Migrate"
cd ..\..\..
RMDIR /S /Q c:Migrate2iaas

REM  ##########  Deleting existing cloudscraper-installer.exe #######
ECHO Deleting existing cloudscraper-installer.exe...

cd /D %PIPLELINE_DIR%

REM  ##########  Installing cloudscraper-installer.exe #######
ECHO Updating cloudscraper engine.....
cloudscraper-installer.exe /S
) else (
echo Skipping update
)

) else (
ECHO ">>>>>>>>>>>>>>>>" Performing quick code update of the existing installation
cd "%HOME_DIR%"
"%PIPLELINE_DIR%\Tools\wget.exe" -N --no-parent -r -nH --cut-dirs=2 %QUICK_UPDATE_PATH% 
dir "%HOME_DIR%\Migrate"
dir "%HOME_DIR%\Migrate\Migrate"

)


REM  ##########  Get Current Version #######
cd /D %HOME_DIR%\Migrate
set content=
for /F "delims=" %%i in (%file%) do set content=!content! %%i
echo Current Version : %content%

if "%RE_UPLOAD%"=="" (
REM  ##########  Delete Old Image #######
echo Deleting Existing IMAGE 
if exist "%IMAGE_PATH%\*" ( 
echo ^>^>^>^>^>^>^> Deleting previous local image data...
RMDIR /Q /S %IMAGE_PATH% 
)
)

REM  ##########  Get Transfer.ini from SVN location #######
echo Copy %TARGET% INI
copy "%PIPLELINE_DIR%\%INI_NAME%" "%HOME_DIR%"

REM ########### Copy license ########

copy "%PIPLELINE_DIR%\lcns.msg" "%HOME_DIR%"

REM  ##########  Get OS Information and Target #######
echo The %SOURCE% Source Server It is Running on
systeminfo | findstr /B /C:"OS Name" /C:"OS Version"
set MIGRATE_ERROR=0
cd /d %HOME_DIR%
set PATH=%PATH%;%HOME_DIR%\3rdparty\Python_2.7.10
cd /d %HOME_DIR%\Migrate\Migrate
if "%RE_UPLOAD%" neq "" set EXTRA_MIGRATE_PARMS=%EXTRA_MIGRATE_PARMS% -u

if "%TARGET%" EQU ""  echo ">>>>>>>>>>>>>>>>> CONFIG_ERROR: NO TARGET FOUND!!!" && goto :eof_error
if %TARGET% EQU AWS GOTO AWS
if %TARGET% EQU EC2 GOTO AWS
if %TARGET% EQU ElasticHost GOTO ElasticHost
if %TARGET% EQU CloudSigma GOTO CloudSigma
if %TARGET% EQU Azure GOTO Azure
echo ">>>>>>>>>>>>>> Try default config"
Echo ">>>>>>>>>>>>>>>>>" Migrating to the %TARGET% Cloud
%PYTHONPATH% migrate.pyc -c "%TRANSFER_CONFIG_INI%" -w "!SECRET_KEY!" %EXTRA_MIGRATE_PARMS%
GOTO CONTINUE
:AWS
Echo ">>>>>>>>>>>>>>>>>" Migrating to the %TARGET% Cloud
%PYTHONPATH% migrate.pyc -c "%TRANSFER_CONFIG_INI%" -k "!SECRET_KEY!" %EXTRA_MIGRATE_PARMS% 
GOTO CONTINUE
:ElasticHost
Echo ">>>>>>>>>>>>>>>>>" Migrating to the %TARGET% Cloud
%PYTHONPATH% migrate.pyc -c "%TRANSFER_CONFIG_INI%" -e "!SECRET_KEY!" %EXTRA_MIGRATE_PARMS%
GOTO CONTINUE
:CloudSigma
Echo ">>>>>>>>>>>>>>>>>" Migrating to the %TARGET% Cloud
%PYTHONPATH% migrate.pyc -c "%TRANSFER_CONFIG_INI%" --cloudsigmapass "!SECRET_KEY!" %EXTRA_MIGRATE_PARMS% 
GOTO CONTINUE
:Azure
Echo ">>>>>>>>>>>>>>>>>" Migrating to the %TARGET% Cloud
%PYTHONPATH% migrate.pyc -c "%TRANSFER_CONFIG_INI%" --azurekey "!SECRET_KEY!" %EXTRA_MIGRATE_PARMS%
GOTO CONTINUE
:CONTINUE

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

rem if "%SOURCE%" EQU "" goto :eof
rem if %SOURCE% EQU AWS GOTO AWS
rem if %SOURCE% EQU ElasticHost GOTO ElasticHost
rem if %SOURCE% EQU CloudSigma GOTO CloudSigma
rem if %SOURCE% EQU AZURE GOTO Azure
rem echo ">>>>>>>>>>>>>> CONFIG WARNING: NO CONFIG FOUND TO UPLOAD!!!"
rem GOTO SKIPUPLOAD
rem :AWS
rem set WHERE=/incoming/AutotestLogs/AWS
rem GOTO CONTINUE
rem :ElasticHost
rem set WHERE=/incoming/AutotestLogs/ElasticHost
rem GOTO CONTINUE
rem :CloudSigma
rem set WHERE=/incoming/AutotestLogs/CloudSigma
rem GOTO CONTINUE
rem :Azure
rem set WHERE=/incoming/AutotestLogs/Azure
rem GOTO CONTINUE

:CONTINUE

rem COMMENTING THE LOG UPLOAD DUE TO DISFUNCTIONING
rem cd /D %PIPLELINE_DIR%\Tools
rem set today=%BUILD_ID%
rem echo.%today%
rem set today=%today:~0,10%
rem echo.%today%

rem mkdir %today%
rem cd %today%
rem wget http://user:%jApi%@%jHost%/jenkins/job/%JOB_NAME%/%BUILD_NUMBER%/consoleText
rem ren consoleText %BUILD_ID%.log
rem cd ..
rem ncftpput.exe -d -F -R %ftpHost% %WHERE% %PIPLELINE_DIR%\Tools\%today%

rem cd /D %PIPLELINE_DIR%\Tools\%today%
rem DEL /Q *.*
rem dir

:SKIPUPLOAD

@endlocal
EXIT /B %MIGRATE_ERROR%

:eof_error
echo GOT ERROR
exit /B 255
