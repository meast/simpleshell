@echo off
@rem apktool from https://ibotpeaches.github.io/Apktool/
set APKToolPath="d:/server/android/apktool/apktool.jar"
@rem dex2jar from http://sourceforge.net/projects/dex2jar/
set Dex2JARPath="d:/server/android/dex2jar-2.0/d2j-dex2jar.bat"
@rem jd-cli from https://github.com/kwart/jd-cmd/releases 
set JDCLIPath="d:/server/android/jd-cli/jd-cli.bat"
@rem 7-zip from http://7-zip.org
set SEVENTZIPPath="d:/Program Files/7-Zip/7z.exe"
set JAVABINPath="java"
set FullPath=%1

echo Preparing...

if "%1" == "" (
	echo Usage: decompile-apk.bat /path/to/app.apk
	goto end
	) else echo Running
if exist %APKToolPath% (
	echo using %APKToolPath%
	) else (
	echo %APKToolPath% not exist...
	goto end
	)

if exist %Dex2JARPath% (
	echo using %Dex2JARPath%
	) else (
	echo %Dex2JARPath% not exist...
	goto end
	)

if exist %JDCLIPath% (
	echo using %JDCLIPath%
	) else (
	echo %JDCLIPath% not exist...
	goto end
	)


if exist %FullPath% (
	echo using %FullPath%
	) else (
	echo %FullPath% not exist...
	goto end
	)

set ParentPath=%~dp1
set ApkName=%~n1
set DesPath=%ParentPath%/%ApkName%_apk_extract

set ZipDir=%DesPath%/%ApkName%_zip
set ExtractDir=%DesPath%/%ApkName%_extract
set DEXDir=%DesPath%/%ApkName%_dex
set JARDir=%DesPath%/%ApkName%_jar
set SMALIDir=%DesPath%/%ApkName%_smali
set JARSRCDir=%DesPath%/%ApkName%_jarsrc
set ZipFile=%ZipDir%/%ApkName%.zip

if exist %ZipDir% (
	echo Saving to %ZipDir%
	) else (
	echo Creating dir %ZipDir%
	mkdir "%ZipDir%"
	)

xcopy /f /y "%FullPath%" "%ZipFile%"

if exist %DesPath% (
	echo Saving to %DesPath%
	) else (
	echo Creating dir %DesPath%
	mkdir "%DesPath%"
	)

if exist %ExtractDir% (
	echo Saving to %ExtractDir%
	) else (
	echo Creating dir %ExtractDir%
	mkdir "%ExtractDir%"
	)

if exist %DEXDir% (
	echo Saving to %DEXDir%
	) else (
	echo Creating dir %DEXDir%
	mkdir "%DEXDir%"
	)

if exist %JARDir% (
	echo Saving to %JARDir%
	) else (
	echo Creating dir %JARDir%
	mkdir "%JARDir%"
	)

if exist %JARSRCDir% (
	echo Saving to %JARSRCDir%
	) else (
	echo Creating dir %JARSRCDir%
	mkdir "%JARSRCDir%"
	)

%JAVABINPath% -jar %APKToolPath% d %FullPath% -o "%SMALIDir%" -f

%SEVENTZIPPath% x "%ZipFile%" -o"%ExtractDir%/" -y
%SEVENTZIPPath% x "%ZipFile%" -o"%DEXDir%/" *.dex -y

for /f "delims=" %%i in ('dir /b/a-d "%DEXDir%/"') do (
	@rem dex2jar
	%Dex2JARPath% "%DEXDir%/%%i" -f -o "%JARDir%/%%~ni.jar"
	@rem jar2src
	%JDCLIPath% "%JARDir%/%%~ni.jar" -od "%JARSRCDir%"
	)

goto :end

:end
echo  
