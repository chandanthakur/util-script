#!/bin/sh
PackageName=com.skype.m2
date_suffix=`date +%Y%m%d%H%M%S`
profileName=`adb shell dumpsys dbinfo com.skype.m2  | grep -i "live:"  | sed 's#.*/##' | sed 's#.db:##' | sed 's#:#-#'`
deviceName=`adb.exe shell getprop ro.product.model`
androidRelease=`adb.exe shell getprop ro.build.version.release`
appVersion=`adb shell dumpsys package com.skype.m2 | grep versionName | sed 's#.*=##'`
apkPath=`adb shell pm path com.skype.m2 | sed 's#.*:##'`
outDirName=$profileName\_$date_suffix
depth="shallow"
if [! -z "$1" ]
  then
    depth = $1    
fi

rm -Rf $outDirName
mkdir $outDirName
echo "*******************************************************************************************************"
echo "Package: "$PackageName
echo "Device:"$deviceName
echo "Android Version: "$androidRelease
echo "App Version: "$appVersion
echo "Profile Name: "$profileName
echo "*******************************************************************************************************"

printf "Package: "$PackageName > $outDirName/basic_details.txt
printf ", Device:"$deviceName >> $outDirName/basic_details.txt
printf ", Android Version: "$androidRelease >> $outDirName/basic_details.txt
printf ", App Version: "$appVersion >> $outDirName/basic_details.txt
printf ", Profile Name: "$profileName >> $outDirName/basic_details.txt

adb devices -l > $outDirName/deviceInfo.txt
echo "meminfo:begin..."
adb shell dumpsys meminfo $PackageName -v > $outDirName/meminfo.txt
echo "meminfo:success"
echo "glxinfo:begin..."
adb shell dumpsys gfxinfo $PackageName -v > $outDirName/gfxinfo.txt
echo "glxinfo:success"
echo "dbinfo:begin..."
adb shell dumpsys dbinfo $PackageName -v > $outDirName/dbInfo.txt
echo "dbinfo:success"

echo "Fetching databases:begin..."
adb shell dumpsys dbinfo com.skype.m2  | grep -i ".db"  | sed 's#.* ##' | sed 's#.db:##' | awk -v outdir=$outDirName 'function basename(file) {
    sub(".*/", "", file)
    sub(":", ".", file)
    return file
  }{ printf("adb exec-out run-as com.skype.m2 cat %s.db > %s/%s.db\n", $0, outdir, basename($0)); }' |sh
echo "Fetching databases:success..."

echo "Logcat:begin..."
adb logcat -t 10000000 > $outDirName/logcat.txt
echo "Logcat:success..."
echo "ANR/Traces:begin..."
adb pull './data/anr/traces.txt' > $outDirName/anr_traces.txt
echo "ANR/Traces:success..."

echo "Cache Pull:begin..."
adb pull './storage/self/primary/Android/data/'$PackageName'/' $outDirName/
echo "Cache Pull:success..."

if [ "deep" == $depth ]
then
    echo "APK Pull:begin"
    adb pull "."$apkPath $outDirName/
    echo "APK Pull:success"
    echo "Data available in "$outDirName"/"
fi
echo "*******************************************************************************************************"