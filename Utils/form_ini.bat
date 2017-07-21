@ECHO OFF 
SetLocal EnableDelayedExpansion enableextensions

::This script generates ini files from the parms given

REM  ########## Set All Variables #######

if "%SOURCECLOUD%"=="" set SOURCECLOUD=UNKNOWN
if "%TARGETCLOUD%"=="" set TARGETCLOUD=EC2
if "%IMAGEDIR%"=="" set IMAGEDIR=C:\cloudscraper-images
if "%SECRETKEY%"=="" set SECRETKEY=UNKNOWNKEY
if "%INSTANCETYPE%"=="" set INSTANCETYPE=m3.medium
if "%ONAPP_VM_BUILD_TIMEOUT%"=="" set ONAPP_VM_BUILD_TIMEOUT=6000


copy /Y .\Tools\empty_unicode.ini transfer.ini

echo [%TARGETCLOUD%] >> transfer.ini
if "%REGION%" neq ""  (
echo region=%REGION%>> transfer.ini
echo zone=%REGION%b>> transfer.ini
)

if "%TARGETCLOUD%"=="EC2" (
:: Handle extra parms
if "%AWS_Firewall%" neq "" (
echo security-group=%AWS_Firewall%>> transfer.ini
)

if "%AWS_VPC%" neq "" (
if "%AWS_VPC%" neq "None" (
if "%AWS_VPC_Subnet%" neq "" (
echo vpcsubnet=%AWS_VPC_Subnet%>> transfer.ini
)
)
)

if "%AWS_Availability_Zone%" neq "" (
echo zone=%AWS_Availability_Zone%>> transfer.ini
)

)


echo user=%storagekey%>> transfer.ini

if "%TARGETCLOUD%"=="OpenStack" (
rem split user:tenant to two vars
for /F "tokens=1,2 delims=:" %%I in ("%storagekey%") do (
echo user=%%J>> transfer.ini
echo tennant=%%I>> transfer.ini
)
)

if "%TARGETCLOUD%"=="onApp" (
echo user = %storagekey% >> transfer.ini
echo endpoint=%REGION%>> transfer.ini
)
:: if there is a preset in cloud preconf then 
if exist %~dp0\CloudPreconf\%REGION% (
  type %~dp0\CloudPreconf\%REGION% >> transfer.ini
) else (
   echo datastore = %ONAPP_DATASTORE% >> transfer.ini
   echo port = %ONAPP_PORT% >> transfer.ini
   echo minipad_vm_id = %ONAPP_VM_ID% >> transfer.ini
   echo minipad_template = %ONAPP_TEMPLATE_VM% >> transfer.ini
   echo vm_build_timeout = %ONAPP_VM_BUILD_TIMEOUT% >> transfer.ini
   echo s3bucket = %ONAPP_S3BUCKET% >> transfer.ini
   echo s3user = %ONAPP_S3USER% >> transfer.ini
   echo s3secret = %ONAPP_S3SECRET% >> transfer.ini
   echo s3region = %ONAPP_S3REGION% >> transfer.ini
)


echo instance-type = %INSTANCETYPE% >> transfer.ini
echo target-arch = x86_64 >> transfer.ini

if "%storagekey%" neq "" (
echo storageaccount=%storagekey% >> transfer.ini
echo s3key=%storagekey% >> transfer.ini
echo user-uuid=%storagekey% >> transfer.ini
)

if "%BACKUPBUCKET%" neq "" (
echo bucket=%BACKUPBUCKET% >> transfer.ini
echo swift_container=%BACKUPBUCKET% >> transfer.ini
)

echo [DR] >> transfer.ini
if "%Incremental%" neq "false" (
echo increment_depth=2 >> transfer.ini
)
echo manifest_path=%~dp0\..\cloudscraper-database >> transfer.ini

echo [Image] >> transfer.ini

echo image-dir=%IMAGEDIR% >> transfer.ini
echo source-arch = x86_64 >> transfer.ini
echo image-placement = local >> transfer.ini
set IMAGETYPE=RAW
if "%TARGETCLOUD%"=="Azure" set IMAGETYPE=fixed.VHD
if "%TARGETCLOUD%"=="ProfitBricks" set IMAGETYPE=vmdk
if "%TARGETCLOUD%"=="OpenStack" set IMAGETYPE=RAW
echo image-type=%IMAGETYPE% >> transfer.ini

echo [Fixes] >> transfer.ini
echo postprocess=True >> transfer.ini

echo [Volumes] >> transfer.ini
echo letters = %VOLUMES% >> transfer.ini

::Just write all volumes, let them be
for %%p in (A B C D E F G H I J K L M N O P Q R S T U V W X Y Z) do (
 echo [%%p] >> transfer.ini
 echo autoexclude=True >> transfer.ini
 if "%1" neq "" echo pathtoupload=%1-%%p
)

if "!Extra!" neq "" (
  echo !Extra! >> transfer.ini
)