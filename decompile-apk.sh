#!/bin/sh
# usage: decompile-apk.sh /path/to/app.apk

# paths of tools, executable is needed
# apktool from https://ibotpeaches.github.io/Apktool/
APKToolPath=/disk2/server/android/apktool/apktool
# dex2jar from http://sourceforge.net/projects/dex2jar/
Dex2JARPath=/disk2/server/android/dex2jar-2.0/d2j-dex2jar.sh
#

if [ -z $@ ]; then echo "Usage: decompile-apk.sh /path/to/app.apk"; exit; fi
if [ ! -f $@ ]; then echo "$@ is not a file..."; exit; fi
if [ ! -x "${APKToolPath}" ]; then echo "${APKToolPath} is not executable..."; exit; fi
if [ ! -x "${Dex2JARPath}" ]; then echo "${Dex2JARPath} is not executable..."; exit; fi

FullPath=$@
FilePath=${FullPath%'.apk'}
APKFileName=${FilePath##*/}
SaveDEXDir=${FilePath}/${APKFileName}_dex
SaveJARDir=${FilePath}/${APKFileName}_jar
SaveSmaliDir=${FilePath}/${APKFileName}_smali
echo Running...
${APKToolPath} d $@ -o "${SaveSmaliDir}"
echo Inflating...
if [ ! -d "${SaveDEXDir}"]; then mkdir -p "${SaveDEXDir}"; fi
# there might be many *.dex(classes.dex, classes2.dex,...) files in the apk.
DEXFiles=`unzip -v $@ |egrep 'classes*'|awk '{print $NF}'`
# unzip the .dex files
unzip -od "${SaveDEXDir}" $@ ${DEXFiles}

ArrDEXFiles=`ls ${SaveDEXDir}/*.dex|awk '{print $NF}'`

for DEXFile in ${ArrDEXFiles}; do
    # get the dex file name without path
    DEXFileName="${DEXFile##*/}";
    SaveJARFile="${SaveJARDir}/${APKFileName}_${DEXFileName%'.dex'}_dex2jar.jar";
    echo "Decompiling ${DEXFileName} ";
    # dex2jar
    ${Dex2JARPath} "${SaveDEXDir}/${DEXFileName}" -f -o "${SaveJARFile}";
done
CountJARFiles=`ls -l ${SaveJARDir}/*.jar|grep "^-"|wc -l`
echo "Finished: ${CountJARFiles} jar file(s) in ${SaveJARDir}"
#ls -alh "${SaveJARDir}"

