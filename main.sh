#!/bin/bash

############################################
############################################
### Variable declarations and assignment ###
############################################

# This is the computer username, so the pi from pi@raspberrypi
PI_NAME=$(logname)

# This is the trucks name, so the raspberrypi from pi@raspberrypi
TRUCKNAME=$(hostname)

# This is the last two digits from the logger's static IP port (ex. the 01 from 65001)
PORT_DIG="RBP00"

# The can interface that will be logged (by default these are set as can0, can1, etc, but can be set to specific names using udev rules at /etc/udev/rules.d/83-can.rules)
INTERFACE_ACAN="canA"
INTERFACE_BCAN="canB"

# Canbus bit/baudrate
BITRATE=250000

############################################
############################################
###        Starting can interface        ###
############################################

# Ensuring that no conflicts happen from the interface already being up
$(sudo /sbin/ip link set $INTERFACE_ACAN down)
$(sudo /sbin/ip link set $INTERFACE_BCAN down)

# Ensuring the logger has enough time to successfully shut the interface
sleep 2s

# Opening the interface at 250,000 baud
$(sudo /sbin/ip link set $INTERFACE_ACAN up type can bitrate $BITRATE)
$(sudo /sbin/ip link set $INTERFACE_BCAN up type can bitrate $BITRATE)

############################################
############################################
###       Time and Date Collection       ###
############################################

# Collecting today's date and time, obsolete /I think/
TODAY=$(date | cut -d ' ' -f 1-3 --output-delimiter '_')
LOGSTART=$(date | cut -d ' ' -f 4 | cut -d ':' -f 1-4 --output-delimiter '-')

# Gets current hour (this is the start hour)
NUMSTART=$(date +%S)
# Removes leading 0s that the date function returns (ex. 01, 02, 03, etc.)
NUMSTART=${NUMSTART#0}

# Collecting time/date info for file naming
YEAR=$(date +%Y)
MONTH=$(date +%m)
DAY=$(date +%d)
TIMESTART=$(date +%T)

############################################
############################################
###         File existance check         ###
############################################

# Sets the directory and first file name for the logging
#ACAN_LOCAL=/home/$PI_NAME/bashLogging/$TRUCKNAME\_$YEAR$MONTH$DAY$NUMSTART\_$INTERFACE_ACAN\_$PORT_DIG.log


ACAN_LOCAL=/home/$PI_NAME/bashLogging/logs/$INTERFACE_ACAN/$TRUCKNAME\_$YEAR$MONTH$DAY$TIMESTART\_$INTERFACE_ACAN\_$PORT_DIG.log
BCAN_LOCAL=/home/$PI_NAME/bashLogging/logs/$INTERFACE_BCAN/$TRUCKNAME\_$YEAR$MONTH$DAY$TIMESTART\_$INTERFACE_BCAN\_$PORT_DIG.log

# Checking if a log file already exists with the same name - If it does it appends, if it doesn't then it is created

# For canA
if [[ -e $LOCAL_ACAN ]]; then
	# >> means stdout to file, appending
	candump $INTERFACE_ACAN | sed -e "s/ /	/g ; s/	/$TIMESTART/ ; s/	//2 ; s/	//3 ; s/	//3 ; s/	//4" >> $ACAN_LOCAL &
	T1=${!}
else
	candump $INTERFACE_ACAN | sed -e "s/ /	/g ; s/	/$TIMESTART/ ; s/	//2 ; s/	//3 ; s/	//3 ; s/	//4" > $ACAN_LOCAL &
	T1=${!}
	echo $T1
fi

# For canB
if [[ -e $LOCAL_BCAN ]]; then
	# >> means stdout to file, appending
	candump $INTERFACE_BCAN | sed -e "s/ /	/g ; s/	/$TIMESTART/ ; s/	//2 ; s/	//3 ; s/	//3 ; s/	//4" >> $BCAN_LOCAL &
	T2=${!}
else
	candump $INTERFACE_BCAN | sed -e "s/ /	/g ; s/	/$TIMESTART/ ; s/	//2 ; s/	//3 ; s/	//3 ; s/	//4" > $BCAN_LOCAL &
	T2=${!}
fi

############################################
############################################
###       Main loop and time logic       ###
############################################

# Main loop that constantly checks if the new hour has started - If it has it creates a new file, if it hasn't it loops back
while true; do

	# Gets the current hour
	NUMCUR=$(date +%S)
	# Removes the leading 0 that the date function provides (ex. 01, 02, 03, etc.)
	NUMCUR=${NUMCUR#0}
	# Takes the difference between the current hour and the hour the log started (logic triggers new file creation when diff between current hour and start hour !=0)
	CUR_START=$(( $NUMCUR - $NUMSTART ))


# Check to make sure that the difference in time between the start and now is positive (ex. started at 23h30m next hour is 00h00m, 0 - 23 = -23 which breaks the loop's logic
	if [[ $CUR_START -lt 0 ]]; then

		DIFF=$(($CUR_START + 60))

	else

		DIFF=$CUR_START
	fi

# Main check to see if the next hour has begun - If it has it gets the current time, terminates the previous candump logging process, and starts a new one
	if [[ $DIFF -eq 10 ]]; then
		echo "swappin"
		#LOGSTART=$(date | cut -d ' ' -f 4 | cut -d ':' -f 1-4 --output-delimiter '-')

		kill -s SIGINT ${T1}
		echo "killing $T1, canA"
		kill -s SIGINT ${T2}
		echo "killing $T2, canB"

		ACAN_LOCAL=/home/$PI_NAME/bashLogging/logs/$INTERFACE_ACAN/$TRUCKNAME\_$YEAR$MONTH$DAY$TIMESTART\_$INTERFACE_ACAN\_$PORT_DIG.log
		BCAN_LOCAL=/home/$PI_NAME/bashLogging/logs/$INTERFACE_BCAN/$TRUCKNAME\_$YEAR$MONTH$DAY$TIMESTART\_$INTERFACE_BCAN\_$PORT_DIG.log

		candump $INTERFACE_ACAN | sed -e "s/ /	/g ; s/	/$TIMESTART/ ; s/	//2 ; s/	//3 ; s/	//3 ; s/	//4" > $ACAN_LOCAL &
		T1=${!}

		candump $INTERFACE_BCAN | sed -e "s/ /	/g ; s/	/$TIMESTART/ ; s/	//2 ; s/	//3 ; s/	//3 ; s/	//4" > $BCAN_LOCAL &
		T2=${!}


		NUMSTART=$(date +%S)
		NUMSTART=${NUMSTART#0}
		TIMESTART=$(date +%T)
	fi


done



# > means stdout to file
#candump $INTERFACE | cut -d ' ' -f 3,5,8,10-17 --output-delimiter '	' > $LOCAL &
#T1=${!}

