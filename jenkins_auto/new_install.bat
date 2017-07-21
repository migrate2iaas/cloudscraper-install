@echo off
set JAVA_HOME=%~dp0\jre
cd "%~dp0"

ver | find "XP" > nul
if %ERRORLEVEL% == 0 goto xp

"%~dp0\3rdparty\Python_2.7.10\python.exe" install_python.py
pause
exit

:xp
"%~dp0\3rdparty\Python_2.7.10\python.exe" install_python.py --winxp
pause