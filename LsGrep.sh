#!/bin/bash
# Program:
#       List Files of Date.
# History:
#       Lauris First Release 2023.1.2


BusinessLine="$1"
Date="$2"

if [ ${BusinessLine} == 'Spot' ]; then
        ls -ltr api/upex-spot-openapi01/logs/ > Temporary.txt
        grep "${Date}" Temporary.txt
elif [ ${BusinessLine} == 'Future' ]; then
        ls -ltr api/upex-contract-openapi01/logs/ > Temporary.txt
        grep "${Date}" Temporary.txt
fi

rm Temporary.txt
