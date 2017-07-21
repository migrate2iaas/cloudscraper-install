@ECHO OFF 

if "%SOURCECLOUD%"=="" set SOURCECLOUD=UNKNOWN
if "%TARGETCLOUD%"=="" set TARGETCLOUD=EC2
if "%IMAGEDIR%"=="" set IMAGEDIR=C:\cloudscraper-images
if "%SECRETKEY%"=="" set SECRETKEY=UNKNOWNKEY

echo %SOURCECLOUD%> autotestconfig.txt 
echo %TARGETCLOUD%>> autotestconfig.txt 
echo %SECRETKEY%>> autotestconfig.txt 