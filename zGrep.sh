#!/bin/bash
# Program:
# 	Get Log Data. Format Output.
# History:
# 	Lauris	2023.1.1	First Release

if [ -d LogData ]; then
	echo -e "\nLogData is existing.\n\nProgram starts running." 
else
	mkdir -m 755 LogData
	echo -e "\nLogData directory is created right here.\n\nProgram starts running."
fi

Market=$1
UserID=$2
Filename=$3

if [ ${Market} == 'Spot' ]; then
	zgrep ${UserID} api/upex-spot-openapi0{1,2,3,4}/logs/${Filename} > LogData/Output.txt
elif [ ${Market} == 'Future' ]; then
	zgrep ${UserID} api/upex-contract-openapi0{1,2,5}/logs/${Filename} > LogData/Output.txt
elif [ ${Market} == 'SpotNow' ]; then
	zgrep ${UserID} api/upex-spot-openapi0{1,2,3,4}/info.log > LogData/Output.txt
elif [ ${Market} == 'FutureNow' ]; then
	zgrep ${UserID} api/upex-contract-openapi0{1,2,5}/info.log > LogData/Output.txt
fi

echo -e "\nLog data has been greped and stored in LogData/Output.txt"

cat LogData/Output.txt | sed -e 's/api\/upex/\n\napi\/upex/g' -e 's/Root/\nRoot/g' -e 's/INFO/\nINFO/g' -e 's/=====/\n/g' -e 's/\",\"/\"\n\"/g' -e 's/\[#/\n/g' -e 's/#\]//g' | sed -e '1,2d' -e 's/{"/\n{\n"/g' -e 's/}/\n}/g' -e 's/,"/\n"/g' -e 's/:\[/:\n\[\n/g' -e 's/\ \[/\n[/g' -e 's/\"\]/\"\n\]/g' > LogData/Format.txt

echo -e "\nLog data has been formated and stored in LogData/Format.txt"
echo -e "\nSee you next time~\n"

