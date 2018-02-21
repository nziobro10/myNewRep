#!/bin/bash
#clearing screen on start
clear;
#############
function usage(){
	printf "\n\n"
	printf "	Available TC's: \n"
	printf "	1.SLC restart times\n"
	printf "	2.MAX log size transfered to SLC\n"
	printf "	3.Restart SLC with clearing\n"
	printf "	4.Components versions\n"
	printf "	5.NA healtcheck\n"
	printf "        6.Show logs\n"
	printf "	7.SLC status\n"
	printf "	8.Exit\n\n"	
}

function validateip(){
    ipadr=$1
    if [[ $ipadr =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then
        OIFS=$IFS
        IFS='.'
        ipadr=($ipadr)
        IFS=$OIFS
        if [[ ${ipadr[0]} -le 255 && ${ipadr[1]} -le 255 && ${ipadr[2]} -le 255 && ${ipadr[3]} -le 255 ]];then
                printf "Given IP correct...\n";
		return 0;

        else
                printf "IP address is not valid. Make sure you provided correct one.\n"
		return 1;

        fi
    else
        echo "Wrong IP adress given";
	return 1;
    fi
}

restartslc(){
    		TIMEOUT=100;
		COUNTER=0;
		SLC_LOGS_DIR=/usr/share/tomcat_slc/logs		
		smanager.pl stop service slc-`hostname -s` > /dev/null 2>&1;
		sleep 1;
		smanager.pl start service slc-`hostname -s` > /dev/null 2>&1;
		CATALINA_LOG_FILE=$(ls -ltr ${SLC_LOGS_DIR}/* |grep catalina | tail -1 | awk '{print $NF}');
			while [ $(tail -n 2 $CATALINA_LOG_FILE |grep "Server startup" |wc -l) -eq 0 ];do
				sleep 1;
				((COUNTER+=1))
				if [ $COUNTER -eq $TIMEOUT ];then
					printf "\nRestart has been timeouted with $TIMEOUT seconds. Check $CATALINA_LOG_FILE for troubleshooting."
					exit 1;
				fi
			done
}

function restarting_with_clearing(){
	SLC_LOGS_DIR=/usr/share/tomcat_slc/logs
	printf "\nAre you sure you want to restart SLC node. DB Data, Temp Data and JMS queue will be deleted: Y/N ?"
	read answear;
	if [ $answear == 'Y' ];then

		printf "\nRESTARTING SLC NODE WITH METADATA CLEARING...\n";
		smanager.pl stop service slc-`hostname -s` > /dev/null 2>&1;
		rm -rf /var/opt/oss/NSN-slc/tmp/*;
		rm -rf /var/opt/oss/NSN-slc/db/*;
		rm -rf /var/opt/oss/NSN-slc/activemq/kahadb/*;
		sleep 1; 
		smanager.pl start service slc-`hostname -s` > /dev/null 2>&1;

		CATALINA_LOG_FILE=$(ls -ltr ${SLC_LOGS_DIR}/* |grep catalina | tail -1 | awk '{print $NF}');
			while [ $(tail -n 2 $CATALINA_LOG_FILE |grep "Server startup" |wc -l) -eq 0 ];do
                        	sleep 1;
        		done

		tail -n 2 $CATALINA_LOG_FILE |grep "Server startup";
		exit 0;
	else
		exit 0;
	fi
}

results_of_given_repetitions(){	
	SLC_LOGS_DIR=/usr/share/tomcat_slc/logs
	CATALINA_LOG_FILE=$(ls -ltr ${SLC_LOGS_DIR}/* |grep catalina | tail -1 | awk '{print $NF}');
	REPS=$1;
        echo "Start times: ";
        grep "Server startup" $CATALINA_LOG_FILE |tail -n $REPS;
        echo "Start times average of $REPS repetitions:    $(grep "Server startup" $CATALINA_LOG_FILE |tail -n $REPS | cut -f5 -d' ' | awk '{ cumulative_start_time+= $1} END { print cumulative_start_time/NR }') ms";
#        grep "Server startup" $CATALINA_LOG_FILE |tail -n $REPS | cut -f5 -d' ' | awk '{ cumulative_start_time+= $1} END { print cumulative_start_time/NR }';
}

results_of_all_restarts(){
        echo "Start times: ";
        grep "Server startup" $CATALINA_LOG_FILE;
        echo "Start times average of "$(grep "Server startup" $CATALINA_LOG_FILE |wc -l)" repetitions:";
        grep "Server startup" $CATALINA_LOG_FILE | cut -f5 -d' ' | awk '{ cumulative_start_time+= $1} END { print cumulative_start_time/NR }';
}

function slcshow(){

	for i in `smanager.pl status service ^slc |cut -d ":" -f2`; do
        	cat /etc/hosts |grep $i;
        done
}

function isLogSent(){
	operationId=`tr " " '\n' < ./send.sh |grep operationId| head -1|tr "=" '\n'|tail -1`;
	ssh -q root@$1 "ls -latr /var/opt/oss/NSN-slc/tmp/ |grep -r $operationId"
	return 0;
}

function healthcheck(){

	smanager.pl status |grep -v started|grep `hostname -f | cut -f1 -d '.' |head -c 2`;
#	smanager.pl status |grep stoppeda
}

function NAversion(){
	NAVERSION=`cat /etc/netact-release |grep -v ^#|tr -d "[aA-zZ][ ]"`
	ATLCVERSION=`rpm -qi NSN-atlc |grep Version|awk '{print $3}'`
	ATFCVERSION=`rpm -qi NSN-atfc |grep Version|awk '{print $3}'`
	SLCVERSION=`ssh -q root@`smanager.pl status service ^slc |head -1 |awk --field-separator=":" '{print $2}'` "rpm -qi NSN-slc |grep Version|tr -d ' '"`
	printf "\nNetAct version : $NAVERSION\nATLC : $ATLCVERSION\nATFC : $ATFCVERSION\nSLC : $SLCVERSION"
}

function SLCstatus(){
	SLC_TEMP_DIR=/var/opt/oss/NSN-slc/tmp/
	
	printf "Disk used in `hostname -f` : `df -h |grep rootVG-var |awk '{print $5}'`\n";
	printf "Number of files in slc temp dir : `ls $SLC_TEMP_DIR |wc -l` with size of `du -sh $SLC_TEMP_DIR|awk '{print $1}'`\n";
	printf "Number of integrated SIEM systems : `cat /etc/opt/oss/NSN-slc/sender-application.properties |grep enabled=true |wc -l`\n";
	printf "\nReceiver ports status on `hostname -f`: `netstat -lanp |grep 8393`\n";
	
	#for i in `smanager.pl status service ^slc |cut -d ":" -f2`;do
}
		


##########################################MAIN########################################################


printf "\n====SLNBI PET TESTS SCRIPT====\n"
#find . -type f  -name '*logs.txt' -exec rm {} \;
LOG_FILE=$(date '+%Y-%m-%d_%H:%M:%S')_SLNBI_PET_logs.txt
touch ./$LOG_FILE

while(true);do
usage
printf "\nPlease, enter your choice: "
read choice



	case "$choice" in 
		1)
			printf "Scenario 1. launched...\n"
			printf "###	Provide number of restart repetitions: "
			read rep
			slcshow;
			printf "\n###	Please, provide slc node IP to proceed : "
			read slcip;
				validateip $slcip;
					if [[ $? -ne 0 ]];then
						continue
					else
						printf "SLC is restarting. It may take longer time....\n"
						ssh -q root@$slcip "$(typeset -f restartslc); for i in {1..$rep};do restartslc;done";
							if [ $? -ne 1 ];then
								ssh -q root@$slcip "$(typeset -f results_of_given_repetitions); results_of_given_repetitions $rep" |while IFS= read -r line; do printf '[%s] %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$line"; done | tee -a $LOG_FILE;
							fi
					fi
			
			
			;;
		2)	
			printf "###	Scenario 2. launched...\n"
			printf "###	Provide number of records in log file: "
			read records_num
			slcshow;
			printf "\n###	Please, provide slc node IP to proceed : "
			read slcip;
				validateip $slcip;
                                        if [[ $? -ne 0 ]];then
                                                continue;
                                        else
												./makelog.sh $records_num $slcip
										fi			
#			printf "provide file name :"
#			read file_name
			printf "\nChecking log on SLC side...  \n"
			sleep 2;
			
			isLogSent $slcip;
			
			;;
		3)
			printf "###	Scenario 3. Launched...\n"
			slcshow;
			printf "###	Please, provide slc node IP to proceed : "
			read ip
				validateip $ip;
					if [[ $? -ne 0 ]];then
						continue
					else
						ssh -q root@$ip "$(typeset -f restarting_with_clearing); restarting_with_clearing";
					fi
			;;
		 4)
			NAversion;
			;;
		 5)
			printf "### 	Checking for not started services...\n"
			healthcheck;
			;;
		 6)
			tail -n 15 ./$LOG_FILE;
			;;
		 7)
			for i in `smanager.pl status service ^slc |cut -d ":" -f2`;do
				ssh -q root@$i "$(typeset -f SLCstatus); SLCstatus";
			done
			;;
		 8| exit)
			printf "\nDo you want to clear logs before exiting? Y/N";
			read ans
			if [ $ans == 'Y' ];then
				find . -type f  -name '*logs.txt' -exec rm {} \;
				printf "\nExiting.\n";
				break
			else
				printf "\nExiting.\n";
                                break
			fi
			;;
			
		*)
			printf "\nWrong parameter provided. Exiting... \n"
			sleep 2;
			exit 0;
			;;
	esac
unset choice
done
