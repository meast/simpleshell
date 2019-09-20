#!/bin/sh
SrcDir=""
DesDir="/disk2/server/php"
ApxsPath=""
EnvName="development"
TNum=2

if [[ $# -lt 1 ]];then
    echo "Usage: `basename $0` -s SourceDir -d DestinationDir [-a /path/to/apxs]"
fi

while getopts "s:d:a:e:j:h" optname
    do
        case $optname in
            s)
                SrcDir="$OPTARG"
                ;;
            d)
                DesDir="$OPTARG"
                ;;
            a)
                ApxsPath="$OPTARG"
                ;;
            e)
                if [ "$OPTARG" == "p" ] || [ "$OPTARG" == "product" ] || [ "$OPTARG" == "production" ]; then
                    EnvName="production"
                else
                    EnvName="development"
                fi
                ;;
            j)
                TNum=$OPTARG
                ;;
            h)
                echo "Usage: `basename $0` -s SourceDir -d DestinationDir [-a /path/to/apxs]"
                exit 1
                ;;
            *)
                # do nothing.
                ;;
    esac
done

if [ ${TNum} -gt 0 ]; then
    echo "using -j ${TNum}"
else
    TNum=1
    echo "using -j 1"
fi

echo $SrcDir
echo $DesDir
echo $EnvName
echo $ApxsPath
WithApxs=`ls -l ${ApxsPath}|egrep '^-'|awk '{print $NF}'`
DesPDir=$(dirname "$DesDir")
if [ ! -d $DesPDir ]; then
    echo "$DesPDir is not a dir, now try to create the dir(s)"
    sudo mkdir -p $DesPDir
fi

if [ -x $SrcDir ] && [ -w $DesPDir ]; then
    # executable source dir and writable destination dir
    cd $SrcDir
    if [ -f $SrcDir/Makefile ]; then
        sudo make clean
    fi
    if [ ! -f $DesDir/bin/php ] && [ ! -f $desDir/bin/phpize ] && [ ! -f $DesDir/bin/php-config ]; then
        sudo ./buildconf --force
        # enable mysqllnd for compile ext mysql and mysqli and pdo_mysql
        ConfArgs="--prefix=$DesDir --enable-cli --enable-cgi --enable-fpm --enable-mysqlnd   --enable-xml --enable-libxml --enable-xmlreader --enable-xmlwriter --without-iconv"
        if [ -f $ApxsPath ] && [ "$WithApxs" == "$ApxsPath" ]; then
            echo "with apxs2"
            ConfArgs="${ConfArgs} --with-apxs2=$ApxsPath"
        else
            echo "without apxs2"
        fi
        if [ -d "/usr/local/opt" ]; then
            echo "dir /usr/local/opt exists."
        fi
        echo "Config args:"
        echo "${ConfArgs}"
        sudo ./configure ${ConfArgs}
        if [ ! -f $SrcDir/Makefile ]; then
            echo "Makefile is not found"
            exit 1
        fi
        sudo make -j ${TNum} && sudo make install && sudo make clean
        if [ ! -f $Desc/lib/php.ini ]; then
            sudo cp "$SrcDir/php.ini-$EnvName" $DesDir/lib/php.ini
        fi
        if [ ! -f "$DesDir/etc/php-fpm.conf" ] && [ -f "$DesDir/etc/php-fpm.conf.default" ]; then
            sudo cp "$DesDir/etc/php-fpm.conf" "$DesDir/etc/php-fpm.conf.default"
        fi
    fi
    if [ -f $DesDir/bin/phpize ] && [ -f $DesDir/bin/php-config ] && [ -d $SrcDir/ext ]; then

        sudo chmod a+x $DesDir/bin/phpize
        sudo chmod a+x $DesDir/bin/php-config
        for ExtName in `ls -l "$SrcDir"/ext |egrep '^d'|awk '{print $NF}'`; do
            #if [ $ExtName != "mssql" ] && [ $ExtName != "com_dotnet" ]; then
                echo $ExtName
                cd $SrcDir/ext/$ExtName
                if [ -f $SrcDir/ext/$ExtName/Makefile ]; then
                    sudo make clean
                fi
                # there is no config.m4 but config0.m4 in openssl,zlib extension dir
                if [ -f "${SrcDir}/ext/${ExtName}/config0.m4" ] && [ ! -f "${SrcDir}/ext/${ExtName}/config.m4" ]; then
                    sudo cp $SrcDir/ext/$ExtName/config0.m4 $SrcDir/ext/$ExtName/config.m4
                fi
                sudo $DesDir/bin/phpize
                ConfArgs=" --with-php-config=${DesDir}/bin/php-config"
                if [ $ExtName == "gd" ]; then
                    ConfArgs="${ConfArgs} --with-freetype-dir --with-jpeg-dir --enable-gd-native-ttf "
                elif [ $ExtName == "gettext" ]; then
                    if [ -d "/usr/local/opt/gettext" ]; then
                        ConfArgs="${ConfArgs} --with-gettext=/usr/local/opt/gettext"
                    fi
                elif [ $ExtName == "intl" ]; then
                    if [ -d "/usr/local/opt/icu4c" ]; then
                        ConfArgs="${ConfArgs}  --with-icu-dir=/usr/local/opt/icu4c"
                    fi
                elif [ $ExtName == "openssl" ]; then
                    if [ -d "/usr/local/opt/openssl" ]; then
                        ConfArgs="${ConfArgs} --with-openssl=/usr/local/opt/openssl"
                    fi
                elif [ $ExtName == "iconv" ]; then
                    if [ -d "/usr/local/opt/libiconv" ]; then
                        ConfArgs="${ConfArgs} --with-iconv=/usr/local/opt/libiconv"
                    fi
                elif [ $ExtName == "curl" ]; then
                    if [ -d "/usr/local/opt/curl" ]; then
                        ConfArgs="${ConfArgs}  --with-curl=/usr/local/opt/curl "
                    fi
                else
                    echo "else"
                fi
                sudo ./configure ${ConfArgs}
                if [ -f $SrcDir/ext/$ExtName/Makefile ]; then
                    sudo make -j ${TNum} && sudo make install 
                    sudo make clean
                fi
            #fi
        done
        
        if [ -x "${DesDir}/bin/php" ] && [ -d "${DesDir}/lib/php/extensions" ]; then
            ExtDirName=`ls ${DesDir}/lib/php/extensions`
            ExtDirPath="${DesDir}/lib/php/extensions/${ExtDirName}/"
            if [ -d "${ExtDirPath}" ]; then
                ExtsBuilt=`ls ${ExtDirPath}*.so`
                PHPExtsIni="${DesDir}/lib/phpexts.ini"
                echo '' > "${PHPExtsIni}"
                for s in ${ExtsBuilt[@]}; do
                    ExtFileName=${s##*/}
                    ExtFileName=${ExtFileName%.*}
                    IsExtLoaded=`${DesDir}/bin/php -m|grep -i ^${ExtFileName}$`
                    if [ -z "${IsExtLoaded}" ]; then
                        if [ "${ExtFileName}" = "opcache" ] || [ "${ExtFileName}" = "xdebug" ]; then
                            echo ";zend_extension=${ExtDirPath}${ExtFileName}.so" >> "${PHPExtsIni}"
                        else
                            echo ";extension=${ExtFileName}" >> "${PHPExtsIni}"
                        fi
                    else
                        echo "${s} is loaded..."
                    fi
                done
            else
                echo "${ExtDirPath} is not a directory."
            fi
        else
            echo "${DesDir}/bin/php not found or is not executable, or ${DesDir}/lib/php/extensions is not exists."
        fi

    else
        echo "can not find $DesDir/bin/phpize or $DesDir/bin/php-config or dir $SrcDir/ext"
    fi
fi

