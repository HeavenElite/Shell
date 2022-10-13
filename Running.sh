#!/bin/bash
# Program:
# 	Check if the processes recorded in checkingitems file are existing or not. If not, alert will be prompted.
# History:
#       Qi NIE  2022.09.06      Version 1.0

### CPU & Memory Usage

TotalCpuIdlePercentage=$(top -b -n 2 | grep '%Cpu' | tail -n 1 | awk 'BEGIN{FS=" "}{printf "%2i",$8}')
AverageCpuUsage=$(( 100 - ${TotalCpuIdlePercentage} ))
MemoryUsage=$(free | grep 'Mem' | awk '{printf "%2i",$3/$2*100}')
CoreNumber=$(lscpu | grep '^CPU(s):' | awk '{print $2}')

if [ "${AverageCpuUsage}" -ge '75' ]; then
	echo
	echo -e "CPU usage, including ${CoreNumber} cores, is ${AverageCpuUsage}% now, >= 75%. Shell will stop running.  \n"
	exit
elif [ "${MemoryUsage}" -ge '75' ]; then
	echo
	echo -e "Mem usage now is ${AverageCpuUsage}%, >= 75%. Shell will stop running.  \n"
	exit
else
	echo
	echo -e "CPU Usage is ${AverageCpuUsage}%."
	echo -e "Mem Usage is ${MemoryUsage}%."
	echo -e "System resource is enough. Shell is about to run. \n"
fi

### Process Examnination

declare    File                 # The file that is recording all the checking items.
declare -i ItemCount            # Count the total number of the checking items.
declare -i Item                 # Record the current checking item number.
declare    CurrentItem          # Record the current checking item.
declare    Running              # Record all the existing items.
declare -i RunningCount=0       # Count the Running items.
declare    Error                # Record all the failed items.
declare -i ErrorCount=0         # Count the failure items.

File="./checkingitems"
ItemCount=$(cat "${File}" | wc -l)
echo
echo -e "There are ${ItemCount} processes that will be checked by this Shell. \n"


for Item in $(seq 1 ${ItemCount})
do
        CurrentItem="$(sed -n ${Item}p ${File})"
        ps -ef | sed -e '/grep/d' | grep "jar ${CurrentItem}" &> /dev/null
        if [ "${?}" = "0" ];    then
                RunningCount=$(( ${RunningCount} + 1 ))
                if [ "${RunningCount}" = '1' ]; then
                        Running="$(sed -n ${Item}p ${File})"
                else
                        Running=${Running},${CurrentItem}
                fi
        else
                ErrorCount=$(( ${ErrorCount} + 1 ))
                if [ "${ErrorCount}" = '1' ]; then
                        Error="$(sed -n ${Item}p ${File})"
                else
                        Error=${Error},${CurrentItem}
                fi      
        fi
done

### Result Output

if [ "${ErrorCount}" == '0' ]; then
        echo -e "All the ${RunningCount} processes are running! It's done. \n"
else
        echo -e "${ErrorCount} Errors are detected! The processes below are not started: \n"
        for m in $(seq 1 ${ErrorCount})
        do
                echo -e -n "${m}:\t" 
		echo "${Error}" | cut -d ',' -f ${m}
        done

        if [ "${ErrorCount}" != "${ItemCount}" ]; then
                echo
                echo
                echo -e "${RunningCount} processes are OK: \n"
                for n in $(seq 1 ${RunningCount})
                do
                        echo -e -n "${n}:\t" 
			echo "${Running}" | cut -d ',' -f ${n}
                done
        fi
        echo
        echo
        echo -e "That's all.\n"
fi

### Restart Stop Processes

if [ "${ErrorCount}" != '0' ]; then
	echo -e "Restarting the ${ErrorCount} Dead Processes Now... \n"
	
	declare StartPath='/home/authentic/Runtime/authentic-server/bin/'
	declare Restart=${Error}
	declare RestartItem
	declare RestartCount=${ErrorCount}
	declare RestartFailed
	declare RestartFailedCount=0
	declare RestartSucceed
	declare RestartSucceedCount=0

	echo "${Restart}" | grep LocalC &> /dev/null
      	
	if [ "${?}" == '0' ]; then
		Restart=${Restart/LocalC,/}
		RestartCount=$(( ${RestartCount} - 1 ))
		echo -e "Shell is trying to restart LocalC now..."
		echo -e "If it's pending for a long time, please breakout with Ctrl+C.\nAnd Run '${StartPath}start.sh LocalC' manually to check the error prompts.\n"	

                cd ${StartPath}
                bash start.sh LocalC &> /dev/null		
		
		if [ "${?}" == '0' ]; then
			RestartSucceed=LocalC
			RestartSucceedCount=1
			echo -e "LocalC has been started! Good Luck~ \n"
		else
			RestartFailed=LocalC
			RestartFailedCount=1
			echo -e "Failed to restart LocalC this time. It has been recorded for further steps. \n"
		fi
		echo
		echo
	fi

	for x in $(seq 1 ${RestartCount})
	do
		RestartItem=$( echo ${Restart} | cut -d ',' -f ${x} )
		echo -e "Shell is trying to restart ${RestartItem} now..."
		echo -e "If it's pending for a long time, please breakout with Ctrl+C.\nAnd Run '${StartPath}start.sh -Xmx2048m ${RestartItem}' manually to check the error prompts.\n"	

                cd ${StartPath}
                bash start.sh -Xmx2048m ${RestartItem} &> /dev/null

		if [ "${?}" == '0' ]; then
			if [ "${RestartSucceedCount}" == '0' ]; then
				RestartSucceed=${RestartItem}
			else
				RestartSucceed=${RestartSucceed},${RestartItem}
			fi

			RestartSucceedCount=$(( ${RestartSucceedCount} + 1))
			echo -e "${RestartItem} has been started! Good Luck~ \n"
		else
			if [ "${RestartFailedCount}" == "0" ]; then
				RestartFailed=${RestartItem}
			else
				RestartFailed=${RestartFailed},${RestartItem}
			fi	
			
			RestartFailedCount=$(( ${RestartFailedCount} + 1 ))
			echo -e "Failed to restart ${RestartItem} this time. It has been recorded for further steps.\n"
			echo
		fi	
	done

	if [ "${RestartFailedCount}" == '0' ]; then
		echo -e "Shell has tried to restart the stop processes that detected before."
		echo -e "All stop processes are running now. Congratulations! \n"
	else
		echo -e "Below lists the failed restarting processes: \n"

		for y in $( seq 1 ${RestartFailedCount} )
		do
			echo -e -n "${y}:\t"
			echo "${RestartFailed}" | cut -d ',' -f ${y}
		done

		if [ "${RestartFailedCount}" != "${ErrorCount}" ]; then
			
			echo -e "Besides of the failed restarted, below lists the processes that are successfully restarted: \n"
			
			for z in $( seq 1 ${RestartSucceedCount} )
			do
				echo -e -n "${z}:\t"
				echo "${RestartSucceed}" | cut -d ',' -f ${z}
			done
		fi	
		echo
		echo
	fi

fi

### The End