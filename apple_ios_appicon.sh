#!/bin/sh

function build_appicon() {
	if [ -z ${1} ]; then
		echo "source file can not be empty ${1} ..."
		return;
	fi
	if [ -z ${2} ]; then
		echo " target dir can not be empty ${2} ..."
		return;
	fi
	if [ ! -f ${1} ]; then
		echo "source file ${1} is not exists or not a file."
		return;
	fi
	if [ ! -d ${2} ]; then
		echo "target directory ${2} is not exists"
		return;
	fi

	# sizes: [size]_[filename]
	ICONSIZES="20_iPhoneNotification20pt 40_iPhoneNotifacation20pt@2x 60_iPhoneNotification20pt@3x 29_iPhoneSpotlight29pt 58_iPhoneSpotlight29pt@2x 87_iPhoneSpotlight29pt@3x 80_iPhoneSpotlight40pt@2x 120_iPhoneSpotlight40pt@3x 57_iPhoneApp57pt 114_iPhoneApp57pt@2x 120_iPhoneApp60pt@2x 180_iPhoneApp60pt@3x 20_iPadNotifications20pt 40_iPadNotifications20pt@2x 29_iPadSetting29pt 58_iPadSettings29pt@2x 40_iPadSpotlight40pt 80_iPadSpatlight40pt@2x 50_iPadSpotlight50pt 100_iPadSpotlight50pt@2x 72_iPadApp72pt 144_iPadApp72pt@2x 76_iPadApp76pt 152_iPadApp76pt@2x 167_iPadProApp83.5pt@2x 1024_AppStore1024 48_AppleWatch38mm24pt@2x 55_AppleWatch42mm27.5pt@2x 58_AppleWatchCompanionSettings29pt@2x 87_AppleWatchCompanionSettings29pt@3x 40_AppleWatchHomeScreen40pt 176_AppleWatchShortLook38mm86pt@2x 176_AppleWatchShortLook42mm196pt@2x 1024_AppleWatchAppStore1024pt 16_Mac16pt 32_Mac16pt@2x 32_Mac32pt 64_Mac32pt@2x 128_Mac128pt 256_Mac128pt@2x 256_Mac256pt 512_Mac256pt@2x 512_Mac512pt 1024_Mac512pt@2x"
	for item in ${ICONSIZES}
	do
		size=${item%_*}
		name=${item/${size}/}
		echo "size: ${size}, name: ${name}"
		echo ""
		convert -resize ${size} ${1} ${2}/AppIcon${name}.png
	done
	convert ${1} -background white -flatten ${2}/AppIcon_AppStore.jpg
}

if [ $(command -v convert) ]; then
	echo ""
	build_appicon ${1} ${2}

else
	echo "convert not exitst."
	echo "please install ImageMagick by running this command"
	echo "brew install ImageMagick"
fi


