# Got from the official tutorial, modified a bit - VFedorov

OutFile "cloudscraper-agent.exe"

!define APPNAME "Migration Agent"
!define COMPANYNAME "4D DC"
!define DESCRIPTION "Cloudscraper Agent Installer"
!define EXEFILE "CloudscraperAgent.exe"

# These three must be integers
!define VERSIONMAJOR 1
!define VERSIONMINOR 1
!define VERSIONBUILD 1
 
RequestExecutionLevel admin ;Require admin rights on NT6+ (When UAC is turned on)

Name "4D Cloud Migration Agent"
#InstallDir "$PROGRAMFILES\${COMPANYNAME}\${APPNAME}"
InstallDir "c:\cloudscraper-agent"

Function MyShowReadme
ExecShell "" "$instdir\Cloudscraper-agent-manual.pdf"
FunctionEnd


!define MUI_ICON "CloudInstall.ico" 
!define MUI_HEADERIMAGE 
!define MUI_HEADERIMAGE_BITMAP "cloud_header2.bmp"
 
!include "MUI2.nsh"
!include LogicLib.nsh
!include InstallOptions.nsh

!define MUI_WELCOMEFINISHPAGE_BITMAP "4d.bmp"

!define MUI_INSTFILESPAGE_COLORS "0000000 FFFFFF" ;Two colors
!define MUI_FINISHPAGE_LINK "www.migrate2iaas.com"
!define MUI_FINISHPAGE_TITLE "Agent Installed"
!define MUI_FINISHPAGE_TEXT "Agent software has been installed! Now register the agent at Web Console by checking Register below. Click Finish to start the registration process."
!define MUI_FINISHPAGE_RUN "$INSTDIR\new_install.bat"
!define MUI_FINISHPAGE_RUN_TEXT "Register Agent"
#!define MUI_FINISHPAGE_RUN_NOTCHECKED
!define MUI_FINISHPAGE_BUTTON "Finish"
!define MUI_PAGE_HEADER_TEXT "4D Migration Agent Installer"
!define MUI_PAGE_HEADER_SUBTEXT "Installing Migration Agent Software on your Windows Server"
!define MUI_DIRECTORYPAGE_TEXT_TOP "Choose the folder to install Cloudscraper"
!define MUI_INSTFILESPAGE_FINISHHEADER_TEXT "Agent has been installed, click Finish to complete the installation"


#!insertmacro MUI_PAGE_DIRECTORY
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
	file /r jre
	file /r tools
	file /r 3rdparty
	file /r jenkins
	file curl.exe
	file libcurl.dll
	file libeay32.dll
	file libidn-11.dll
	file mk-ca-bundle.vbs
	file ncftpput.exe
	file ssleay32.dll
	file wget.exe
	#file _install.bat
	#file install.py
	file new_install.bat
	file install_python.py
	file six.py
	file fcntl_win.py
 
	# Uninstaller - See function un.onInit and section "uninstall" for configuration
	writeUninstaller "$INSTDIR\uninstall.exe"
 
	# Start Menu
	createDirectory "$SMPROGRAMS\${COMPANYNAME}"
	# Note: Icon name is hardcoded here
	createShortCut "$SMPROGRAMS\${COMPANYNAME}\Register Agent.lnk" "$INSTDIR\_install.bat" 
	# Remove Start Menu launcher
	createShortCut "$SMPROGRAMS\${COMPANYNAME}\Uninstall.lnk" "$INSTDIR\uninstall.exe" 
	# Manual
	#createShortCut "$SMPROGRAMS\${COMPANYNAME}\User Manual.lnk" "$INSTDIR\Cloudscraper-Manual.pdf" 
 
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

	#TODO: move to separate uninstall script
	Exec "schtasks /end /tn JenkinsSlave"
	Exec "sc stop schedule"
	Exec "sc start schedule"

	# Remove files	
	rmDir /r $INSTDIR\tools
	rmDir /r $INSTDIR\workspace
	rmDir /r $INSTDIR\3rdparty
	rmDir /r $INSTDIR\jenkins
	rmDir /r $INSTDIR\jre

	delete curl.exe
	delete libcurl.dll
	delete libeay32.dll
	delete libidn-11.dll
	delete mk-ca-bundle.vbs
	delete ncftpput.exe
	delete ssleay32.dll
	delete wget.exe	
 
	# Always delete uninstaller as the last action
	delete $INSTDIR\uninstall.exe
 
	# Try to remove the install directory - this will only happen if it is empty
	rmDir $INSTDIR
 
	# Remove uninstaller information from the registry
	DeleteRegKey HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${COMPANYNAME} ${APPNAME}"
sectionEnd