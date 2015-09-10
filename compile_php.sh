#!/bin/sh
SrcDir=""
DesDir="/disk2/server/php"
ApxsPath=""
EnvName="development"

if [[ $# -lt 1 ]];then
    echo "Usage: `basename $0` -s SourceDir -d DestinationDir [-a /path/to/apxs]"
fi

while getopts "s:d:a:e:h" optname
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
            h)
                echo "Usage: `basename $0` -s SourceDir -d DestinationDir [-a /path/to/apxs]"
                exit 1
                ;;
            *)
                # do nothing.
                ;;
    esac
done

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
    sudo make clean
    if [ ! -f $DesDir/bin/php ] && [ ! -f $desDir/bin/phpize ] && [ ! -f $DesDir/bin/php-config ]; then
        sudo ./buildconf --force
        # enable mysqllnd for compile ext mysql and mysqli and pdo_mysql 
        if [ -f $ApxsPath ] && [ "$WithApxs" == "$ApxsPath" ]; then
            echo "with apxs2"
            sudo ./configure --prefix=$DesDir --enable-cli --enable-cgi --enable-fpm --enable-mysqlnd --with-apxs2=$ApxsPath
        else
            echo "without apxs2"
            sudo ./configure --prefix=$DesDir --enable-cli --enable-cgi --enable-fpm --enable-mysqlnd
        fi
        if [ ! -f $SrcDir/Makefile ]; then
            echo "Makefile is not found"
            exit 1
        fi
        sudo make && sudo make install
        if [ ! -f $Desc/lib/php.ini ]; then
            sudo cp "$SrcDir/php.ini-$EnvName" $DesDir/lib/php.ini
        fi
    fi
    if [ -f $DesDir/bin/phpize ] && [ -f $DesDir/bin/php-config ] && [ -d $SrcDir/ext ]; then

        sudo chmod a+x $DesDir/bin/phpize
        sudo chmod a+x $DesDir/bin/php-config
        for ExtName in `ls -l "$SrcDir"/ext |egrep '^d'|awk '{print $NF}'`; do
            #if [ $ExtName != "mssql" ] && [ $ExtName != "com_dotnet" ]; then
                echo $ExtName
                cd $SrcDir/ext/$ExtName
                sudo make clean
                # there is no config.m4 but config0.m4 in openssl,zlib extension dir
                if [ -f $SrcDir/ext/zlib/config0.m4 ] && [ ! -f $SrcDir/ext/zlib/config.m4 ]; then
                    sudo cp $SrcDir/ext/$ExtName/config0.m4 $SrcDir/ext/$ExtName/config.m4
                fi
                sudo $DesDir/bin/phpize
                if [ $ExtName == "gd" ]; then
                    sudo ./configure --prefix=$DesDir --with-php-config=$DesDir/bin/php-config --with-freetype-dir --with-jpeg-dir --enable-gd-native-ttf --with-xpm-dir
                else
                    sudo ./configure --prefix=$DesDir --with-php-config=$DesDir/bin/php-config
                fi
                if [ -f $SrcDir/ext/$ExtName/Makefile ]; then
                    sudo make && sudo make install 
                    sudo make clean
                fi
            #fi
        done
    else
        echo "can not find $DesDir/bin/phpize or $DesDir/bin/php-config or dir $SrcDir/ext"
    fi
fi

