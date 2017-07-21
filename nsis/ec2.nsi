# Got from the official tutorial, modified a bit - VFedorov

OutFile "cloudscraper-installer.exe"

!define APPNAME "Cloudscraper"
!define COMPANYNAME "Migrate2Iaas"
!define DESCRIPTION "Cloudscraper Software Installer"
!define EXEFILE "CloudScraper.exe"

# These three must be integers
!define VERSIONMAJOR 1
!define VERSIONMINOR 1
!define VERSIONBUILD 1
 
RequestExecutionLevel admin ;Require admin rights on NT6+ (When UAC is turned on)

Name "Migrate2iaas Cloudscraper"
InstallDir "$PROGRAMFILES\${COMPANYNAME}\${APPNAME}"

Function MyShowReadme
ExecShell "" "$instdir\Cloudscraper-manual.pdf"
FunctionEnd



!define MUI_ICON "CloudInstall.ico" 
!define MUI_HEADERIMAGE 
!define MUI_HEADERIMAGE_BITMAP "cloud_header2.bmp"
 
!include "MUI2.nsh"
!include LogicLib.nsh
!include InstallOptions.nsh

!define MUI_WELCOMEFINISHPAGE_BITMAP "cloudscaper-190-176.bmp"

!define MUI_INSTFILESPAGE_COLORS "0000000 FFFFFF" ;Two colors
!define MUI_FINISHPAGE_RUN "$instdir\Cloudscraper.exe"
!define MUI_FINISHPAGE_RUN_NOTCHECKED
!define MUI_FINISHPAGE_SHOWREADME #"${APP_INST_DIR}\Cloudscraper-manual.pdf"
!define MUI_FINISHPAGE_SHOWREADME_NOTCHECKED
!define MUI_FINISHPAGE_LINK "www.migrate2iaas.com"
!define MUI_FINISHPAGE_TITLE "Cloudscraper Installed!"
!define MUI_FINISHPAGE_TEXT "Cloudscraper software has been installed! You can either start the application or read the user manual. Also you can run the application by navigating Migrate2iaas in Start > Programs menu"
!define MUI_FINISHPAGE_RUN_TEXT "Run Cloudscraper Now"
!define MUI_FINISHPAGE_SHOWREADME_TEXT "Read PDF Manual"
!define MUI_FINISHPAGE_SHOWREADME_FUNCTION MyShowReadme
!define MUI_FINISHPAGE_BUTTON "Finish"
!define MUI_PAGE_HEADER_TEXT "Migrate2iaas Cloudscraper Installer"
!define MUI_PAGE_HEADER_SUBTEXT "Installing Cloudscraper Software on your Windows Server"
!define MUI_DIRECTORYPAGE_TEXT_TOP "Choose the folder to install Cloudscraper"
!define MUI_INSTFILESPAGE_FINISHHEADER_TEXT "Cloudscraper has been installed, click Finish to complete the installation"


#!insertmacro MUI_PAGE_WELCOME
!insertmacro MUI_PAGE_LICENSE "license.rtf"
!insertmacro MUI_PAGE_DIRECTORY
!insertmacro MUI_PAGE_INSTFILES
!insertmacro MUI_PAGE_FINISH

!insertmacro MUI_LANGUAGE "English" 

!macro VerifyUserIsAdmin
UserInfo::GetAccountType
pop $0
${If} $0 != "admin" ;Require admin rights on NT4+
        messageBox mb_iconstop "Administrator rights required!"
        setErrorLevel 740 ;ERROR_ELEVATION_REQUIRED
        quit
${EndIf}
!macroend
 
function .onInit
	setShellVarContext all
	!insertmacro VerifyUserIsAdmin
functionEnd
 
section "install"
	# Files for the install directory - to build the installer, these should be in the same directory as the install script (this file)
	setOutPath $INSTDIR
	# Files added here should be removed by the uninstaller (see section "uninstall")
	file /r 3rdparty
	file /r Migrate
	file /r Icons
	file /r service
	file /r Net35
	file /nonfatal /r logs
	file CloudScraper.exe
	file CloudScraper.exe.config
	file CloudScraper.exe.mdb
	file NLog.dll
	file NLog.config
	file /nonfatal AWSSDK.dll
	file ICSharpCode.SharpZipLib.dll
	file AssemblaAPI.dll
	file migrate.cmd
	file build
	file revision-gui
	file license.rtf
	file makecert.exe
	file Cloudscraper-Manual.pdf
	file  /nonfatal lcns.msg
	file AWSSDK.Core.dll
	file AWSSDK.EC2.dll
	file AWSSDK.S3.dll

 
	# Uninstaller - See function un.onInit and section "uninstall" for configuration
	writeUninstaller "$INSTDIR\uninstall.exe"
 
	# Start Menu
	createDirectory "$SMPROGRAMS\${COMPANYNAME}"
	# Note: Icon name is hardcoded here
	createShortCut "$SMPROGRAMS\${COMPANYNAME}\${APPNAME}.lnk" "$INSTDIR\${EXEFILE}" 
	# Remove Start Menu launcher
	createShortCut "$SMPROGRAMS\${COMPANYNAME}\Uninstall.lnk" "$INSTDIR\uninstall.exe" 
	# Manual
	createShortCut "$SMPROGRAMS\${COMPANYNAME}\User Manual.lnk" "$INSTDIR\Cloudscraper-Manual.pdf" 
 
	# Registry information for add/remove programs
	WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${COMPANYNAME} ${APPNAME}" "DisplayName" "${COMPANYNAME} - ${APPNAME} - ${DESCRIPTION}"
	WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${COMPANYNAME} ${APPNAME}" "UninstallString" "$\"$INSTDIR\uninstall.exe$\""
	WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${COMPANYNAME} ${APPNAME}" "QuietUninstallString" "$\"$INSTDIR\uninstall.exe$\" /S"
	WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${COMPANYNAME} ${APPNAME}" "InstallLocation" "$\"$INSTDIR$\""
	WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${COMPANYNAME} ${APPNAME}" "DisplayIcon" "$\"$INSTDIR\${ICOFILE}$\""
	WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${COMPANYNAME} ${APPNAME}" "Publisher" "$\"${COMPANYNAME}$\""
	WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${COMPANYNAME} ${APPNAME}" "HelpLink" "$\"${HELPURL}$\""
	WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${COMPANYNAME} ${APPNAME}" "URLUpdateInfo" "$\"${UPDATEURL}$\""
	WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${COMPANYNAME} ${APPNAME}" "URLInfoAbout" "$\"${ABOUTURL}$\""
	WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${COMPANYNAME} ${APPNAME}" "DisplayVersion" "$\"${VERSIONMAJOR}.${VERSIONMINOR}.${VERSIONBUILD}$\""
	WriteRegDWORD HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${COMPANYNAME} ${APPNAME}" "VersionMajor" ${VERSIONMAJOR}
	WriteRegDWORD HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${COMPANYNAME} ${APPNAME}" "VersionMinor" ${VERSIONMINOR}
	# There is no option for modifying or repairing the install
	WriteRegDWORD HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${COMPANYNAME} ${APPNAME}" "NoModify" 1
	WriteRegDWORD HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${COMPANYNAME} ${APPNAME}" "NoRepair" 1
	# Set the INSTALLSIZE constant (!defined at the top of this script) so Add/Remove Programs can accurately report the size
	WriteRegDWORD HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${COMPANYNAME} ${APPNAME}" "EstimatedSize" ${INSTALLSIZE}
sectionEnd
 
# Uninstaller
 
function un.onInit
	SetShellVarContext all
 
	#Verify the uninstaller - last chance to back out
	MessageBox MB_OKCANCEL "Do you want to remove ${APPNAME} permanantly?" /SD IDOK IDOK next
		Abort
	next:
	!insertmacro VerifyUserIsAdmin
functionEnd
 
section "uninstall"
 
	# Remove Start Menu launcher
	delete "$SMPROGRAMS\${COMPANYNAME}\${APPNAME}.lnk"
	delete "$SMPROGRAMS\${COMPANYNAME}\Uninstall.lnk" 
	# Try to remove the Start Menu folder - this will only happen if it is empty
	rmDir "$SMPROGRAMS\${COMPANYNAME}"
 
	# Remove files
	rmDir /r $INSTDIR\3rdparty
	rmDir /r $INSTDIR\Migrate
	rmDir /r $INSTDIR\Icons
	rmDir /r $INSTDIR\service
	#let's leave logs untouched
	#rmDir /r $INSTDIR\logs
	delete $INSTDIR\CloudScraper.exe
	delete $INSTDIR\CloudScraper.exe.config
	delete $INSTDIR\CloudScraper.exe.mdb
	delete $INSTDIR\NLog.dll
	delete $INSTDIR\NLog.config
	delete $INSTDIR\AWSSDK.dll
	delete $INSTDIR\ICSharpCode.SharpZipLib.dll
	delete $INSTDIR\migrate.cmd
	delete $INSTDIR\build
	delete $INSTDIR\revision
	delete $INSTDIR\license.rtf
	delete $INSTDIR\makecert.exe
	delete $INSTDIR\revision-gui
	delete $INSTDIR\Cloudscraper-Manual.pdf
	
 
	# Always delete uninstaller as the last action
	delete $INSTDIR\uninstall.exe
 
	# Try to remove the install directory - this will only happen if it is empty
	rmDir $INSTDIR
 
	# Remove uninstaller information from the registry
	DeleteRegKey HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${COMPANYNAME} ${APPNAME}"
sectionEnd