#!/bin/sh

TargetPath=$(pwd)

if [ -n "${1}" ]; then
    if [ -d "${1}" ]; then
        TargetPath="${1}"
        echo "\033[32m count dir: \033[0m ${TargetPath}"
    else
        echo  "\033[31m target not exists.\033[0m ${1} "
    fi
fi

for SubDir in `ls -l "${TargetPath}" |egrep '^d'|awk '{print $NF}'`; do
    #
    NewPath="${TargetPath}/${SubDir}"
    if [ -d ${NewPath} ]; then
        DirSize=$(sudo du -hs ${NewPath})
        #echo "${NewPath} \033[32m ${DirSize} \033[0m "
        DirSize=${DirSize/\/Users\/ime/"~"}
        echo "\033[32m ${DirSize} \033[0m "
    else
        echo  "\033[31m dir not exists.\033[0m ${SubDir} "
    fi
done

AllSize=$(sudo du -hs ${TargetPath})
echo "\033[32m ${AllSize} \033[0m "
