#!/usr/bin/env bash

if ! command -v python3 &> /dev/null
then
	echo "python3 could not be found starting installation"
	sleep 5 
	sudo apt-get install libgtk-3-dev build-essential python3 python3-pip
else 
	echo "python3 is installed" 
	
	if ! command -v upp &> /dev/null
	then
    		echo "uplift power play could not be found starting installation" 
		sleep 5
		pip3 install upp
	else
		echo "uplift power play is installed" 
	fi 
fi 

x=0

for (( c=0; c<$(gpu-detect listjson | jq 'length'); c++ ))
	do
	i=$c; 
	if [ "$(gpu-detect listjson | jq '.['$i'] | .brand')" != '"amd"' ]; 
	then 
		if [ "$(gpu-detect listjson | jq '.['$i'] | .subvendor')" != '"Advanced Micro Devices, Inc. [AMD/ATI]"' ]; 
		then 
			echo "$(gpu-detect listjson | jq '.['$i'] | .name')"; 
			echo "GPU $x is not AMD, incrementing counter"; 
			((x+=1)); 
		fi 
	fi 
done

echo "Searching for AMD cards" 

for (( c=0; c<$(gpu-detect listjson | jq 'length'); c++ )) 
	do 
	i=$c; 
	if [ "$(gpu-detect listjson | jq '.['$i'] | .brand')" == '"amd"' ]; 
	then 
		if [ "$(gpu-detect listjson | jq '.['$i'] | .name')" == '"Radeon RX 6800"' ]; 
		then 

			Fclk=$(upp -p /sys/class/drm/card$x/device/pp_table get smc_pptable/FreqTableFclk/0) 
			echo "GPU $x is RX 6800"; 

			if (($Fclk < 1550)); 
			then 
				echo "Increase Fclk frequency"; 
				upp -p /sys/class/drm/card$x/device/pp_table set smc_pptable/FreqTableFclk/0=1550 --write; 
			else 
				echo "Fclk is already set to 1550"; 
			fi 

			TdcLimit=$(upp -p /sys/class/drm/card$x/device/pp_table get smc_pptable/TdcLimit/1) 
			
			if (($TdcLimit == 30)); 
			then 
				echo "Increase SOC power limit"; 
				upp -p /sys/class/drm/card$x/device/pp_table set smc_pptable/FreqTableFclk/0=33 --write; 
			else 
				echo "TdcLimit is already set to 33"; 
			fi 
			((x+=1)); 
	else 
		echo "$(gpu-detect listjson | jq '.['$i'] | .name')"; 
		echo "GPU $i is not RX 6800, incrementing counter"; 
		fi 
	fi 
done
