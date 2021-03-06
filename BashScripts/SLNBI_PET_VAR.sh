#!/bin/bash

SLC_LOGS_DIR=/usr/share/tomcat_slc/logs
LOG_FILE=$(date '+%Y%m%d_%H%M%S')_SLNBI_PET_logs.txt
SLCTMPDIR=/var/opt/oss/NSN-slc/tmp/
SLCDBDIR=/var/opt/oss/NSN-slc/db/
SLCJMSDIR=/var/opt/oss/NSN-slc/activemq/kahadb/
SENDERPROP=/etc/opt/oss/NSN-slc/sender-application.properties
SLCPORT=8393



function usage(){
	printf "	\n"
	printf "==========================================\n"
	printf "	Available Test Case's: \n"
	printf "==========================================\n"
	printf "	1.SLC restart times\n"
	printf "	2.Send logs to SLC\n"
	printf "	3.Restart SLC with data clearing\n"
	printf "	4.List Component versions\n"
	printf "	5.NetAct basic healtcheck\n"
	printf "	6.Show logs\n"
	printf "	7.Show SLC status\n"
	printf "	8.Stop/Start all ATFC\n"
	printf "	9.Exit\n"	
	printf "==========================================\n"
	printf "\nPlease, enter your choice [1-8]...  "
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

function restartslc(){
    	TIMEOUT=300;
		COUNTER=0;
		SLC_LOGS_DIR=/usr/share/tomcat_slc/logs
		smanager.pl stop service slc-`hostname -s` > /dev/null 2>&1;
		sleep 5;
		smanager.pl start service slc-`hostname -s` > /dev/null 2>&1;
		CATALINA_LOG_FILE=$(ls -ltr ${SLC_LOGS_DIR}/* |grep catalina | tail -1 | awk '{print $NF}');
			while [ $(tail -n 7 $CATALINA_LOG_FILE |grep "Server startup" |wc -l) -eq 0 ];do
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
		rm -rf $SLCTMPDIR*;
		rm -rf $SLCDBDIR*;
		rm -rf $SLCJMSDIR*;
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

function results_of_given_repetitions(){	
	SLC_LOGS_DIR=/usr/share/tomcat_slc/logs
	CATALINA_LOG_FILE=$(ls -ltr ${SLC_LOGS_DIR}/* |grep catalina | tail -1 | awk '{print $NF}');
	REPS=$1;
        echo "Start times: ";
        grep "Server startup" $CATALINA_LOG_FILE |tail -n $REPS;
        echo "Start times average of $REPS repetitions:    $(grep "Server startup" $CATALINA_LOG_FILE |tail -n $REPS | cut -f5 -d' ' | awk '{ cumulative_start_time+= $1} END { print cumulative_start_time/NR }') ms";
#        grep "Server startup" $CATALINA_LOG_FILE |tail -n $REPS | cut -f5 -d' ' | awk '{ cumulative_start_time+= $1} END { print cumulative_start_time/NR }';
}

function results_of_all_restarts(){
        echo "Start times: ";
        grep "Server startup" $CATALINA_LOG_FILE;
        echo "Start times average of "$(grep "Server startup" $CATALINA_LOG_FILE |wc -l)" repetitions:";
        grep "Server startup" $CATALINA_LOG_FILE | cut -f5 -d' ' | awk '{ cumulative_start_time+= $1} END { print cumulative_start_time/NR }';
}

function slcshow(){
	if [ -f /opt/cpf/bin/smanager.pl ];then
		for i in `smanager.pl status service ^slc |cut -d ":" -f2`; do
        	cat /etc/hosts |grep $i;
		done
		return 0;
	else
		printf "\nNo smanager.pl found, make sure you are on NetAct VM.\n\n";
		return 1;
	fi
}

function isLogSent(){
	operationId=`tr " " '\n' < ./send.sh |grep operationId| head -1|tr "=" '\n'|tail -1`;
	ssh -q root@$1 "ls -latr /var/opt/oss/NSN-slc/tmp/ |grep -r $operationId"
	return 0;
}

function healthcheck(){

	smanager.pl status |grep -v started|grep `hostname -f | cut -f1 -d '.' |head -c 2`;
}

function NAversion(){
	NAVERSION=`cat /etc/netact-release |grep -v ^#|tr -d "[aA-zZ][ ]"`
	ATLCVERSION=`rpm -qi NSN-atlc |grep Version|awk '{print $3}'`
	ATFCVERSION=`rpm -qi NSN-atfc |grep Version|awk '{print $3}'`
	SLCVERSION=`ssh -q root@`smanager.pl status service ^slc |head -1 |awk --field-separator=":" '{print $2}'` "rpm -qi NSN-slc |grep Version|tr -d ' '"`
	printf "\nNetAct version : $NAVERSION\nATLC : $ATLCVERSION\nATFC : $ATFCVERSION\nSLC : $SLCVERSION"
}

function SLCstatus(){
	
#	printf "Disk used in `hostname -f` : `df -h |grep rootVG-var |awk '{print $5}'`\n";
	printf "### Number of files in slc temp dir : `ls $SLCTMPDIR |wc -l` with size of `du -sh $SLCTMPDIR |awk '{print $1}'`\n";
	printf "### Number of integrated SIEM systems : `cat $SENDERPROP |grep enabled=true |wc -l`\n";
	printf "### Receiver ports status on `hostname -f`: `netstat -lanp |grep $SLCPORT`\n";
	
}

function makelog(){

	recordsnum=$1
	ip=$2
	repetitions=$3
	filename=created_log.txt
	MaxRecordValue=500000



	if [ $recordsnum -lt $MaxRecordValue ] && [ -e ./slc-atlc-simulator-DYNAMIC-SNAPSHOT-jar-with-dependencies.jar ];then

        	touch ./$filename
        	cat > ./$filename << EOL
<?xml version="1.0" encoding="UTF-8"?>
<atlcroot>
<log logFileName="AUDIT_LOG" logType="AUDIT_LOG" creationTime="`date "+%Y-%m-%dT%H:%M:%S%:z"`">		
EOL
                	for ((i=1 ; i <= $recordsnum ; i++));do
                        	cat >> ./$filename << EOL
<record sessionID="OMAgentWebUISessionId_1510750197" eventTime="`date "+%Y-%m-%dT%H:%M:%S%:z"`">
	<operation>upload_active_faults</operation>
        <interfaceType>OMAgentWebUI</interfaceType>
        <operationId>OMAgentWebUIOperation_alarmUpload</operationId>
</record>
EOL
                		echo -ne "###   Filling log file... : $i\r";
                	done
        	cat >> ./$filename <<EOL
</log>
</atlcroot>
EOL
			
			filesize=`ls -ltr . |grep $filename | awk '{ print $5 }'`;
			logtosentsize=$(( $filesize * $repetitions ));
			logtosentsizeMB=$(( $logtosentsize / 1000000 ));
			
        	printf "\n###   Log file created : `pwd`/$filename with  : `less ./$filename |grep '<rec'|wc -l` records.\n"
        	printf "###     Filesize : `ls -ltrh . |grep $filename | awk '{ print $5 }'` what is $filesize bytes.\n"
		printf "###     ~~Size of logs which will be send to $slcip : $logtosentsize B, $logtosentsizeMB MB\n"
        	printf "###     Sending logs to SLC `cat /etc/hosts |grep "$slcip"` $repetitions times. \n\n\n "
		
		for ((i=1; i <= $repetitions ; i++));do
			printf "Sending logs to $ip Iteration : $i \n";
			log_ts=`date +"%d%H%M%S"`;
			java -DendpointIp=$ip -Doperation=part -DmediationType=NWI3_MED -DoperationId=atlc.cmb.$log_ts -Ddn=PLMN/LNBTS-1 -DseType=LNBTS -DlogType=NWI3 -Dmr=PLMN-PLMN -Dcompression=NONE -DpartNumber=1 -Dinput=./$filename -jar ./slc-atlc-simulator-DYNAMIC-SNAPSHOT-jar-with-dependencies.jar;
			sleep 1;
			java -DendpointIp=$ip -Doperation=feedback -DmediationType=NWI3_MED -DoperationId=atlc.cmb.$log_ts -Ddn=PLMN/LNBTS-1 -DseType=LNBTS -DlogType=NWI3 -Dmr=PLMN-PLMN -DstatusCode=20001 -DtotalFragments=2 -jar ./slc-atlc-simulator-DYNAMIC-SNAPSHOT-jar-with-dependencies.jar;
			sleep 2;
		done

				
        	
	else
        	printf "\nMaximum record value $MaxRecordValue has been reached or simulator is not present in `pwd`.\n"
		ls -la . |grep *.jar
	fi
}

function erase(){
	
	filename=created_log.txt
	if [ -f .${filename} ];then
		printf "\nDo you want to remove created_log_file.txt ?? Y/N";
        	read ans;
        		if [ $ans == 'Y' ];then
                		rm -rf ./$filename
                        	printf "Log $filename has been deleted.\n";
			else
				return 0;
			fi
	fi
			
}

function labCheck(){
		HOSTNAME=`hostname -f |cut -d "." -f1`;
		if [ "echo $HOSTNAME |grep clab" == "0" ];then	
			return 0;
		else
			return 1;
		fi
}
		
##########################################MAIN########################################################
clear;
touch ./$LOG_FILE
printf "\n====================================\n"
printf "======SLNBI PET TESTS SCRIPTS======"
printf "\n====================================\n"


if [ ! -e `pwd`/*.jar ];then
	printf "\n!!!WARNING: No simulator jar has been found in `pwd`. See the listing below:\n\n"  | tee -a $LOG_FILE;
	ls -l .
	#NOT GOING TO MAIN MENU WHEN UNHASHED
	#exit 0;
fi


#find . -type f  -name '*logs.txt' -exec rm {} \;

touch ./$LOG_FILE


	while(true);do
		usage
		read choice
		case "$choice" in 
			1)
				printf "###	Scenario $choice. launched...\n" | tee -a $LOG_FILE;
				printf "###	Provide number of restart repetitions: "
				read rep
				echo "$(date '+%Y%m%d-%H:%M:%S') --- Provided repetitions : ${rep}" >> $LOG_FILE;
				slcshow;
				if [ $? -eq 0 ];then
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
				fi
			;;
			2)	
				printf "###	Scenario $choice. launched...\n" | tee -a $LOG_FILE;
				printf "###	Provide number of records in log file: "
				read records_num;
				echo "$(date '+%Y%m%d-%H:%M:%S') --- Provided numbers of records : ${records_num}" >> $LOG_FILE;
				printf "###	Provide number sending repetitions: "
				read rep;
				echo "$(date '+%Y%m%d-%H:%M:%S') --- Provided numbers of log sending repetitions : ${rep}" >> $LOG_FILE;
				slcshow;
				if [ $? -eq 0 ];then
					printf "\n###	Please, provide slc node IP to proceed : "
					read slcip;
						validateip $slcip;
							if [[ $? -ne 0 ]];then
								continue;
							else
								makelog $records_num $slcip $rep
								erase
							fi
				fi
			;;
			3)
				printf "###	Scenario $choice. launched...\n" | tee -a $LOG_FILE;
				slcshow;
				if [ $? -eq 0 ];then
					printf "\n###	Please, provide slc node IP to proceed : "
					read ip
						validateip $ip;
							if [[ $? -ne 0 ]];then
								continue
							else
								ssh -q root@$ip "$(typeset -f restarting_with_clearing); restarting_with_clearing";
								echo "$(date '+%Y%m%d-%H:%M:%S') --- Restarting $ip SLC with clearing" >> $LOG_FILE;
							fi
					ssh -q root@$ip "$(typeset -f SLCstatus); SLCstatus";
				fi
			;;
			4)
				printf "###	Scenario $choice. launched...\n" | tee -a $LOG_FILE;
				NAversion;
			;;
			5)
				printf "###	Scenario $choice. launched...\n" | tee -a $LOG_FILE;
				printf "### 	Checking for not started services...\n"
				healthcheck;
			;;
			6)
				printf "###	Listing $LOG_FILE file : \n\n";
				tail -n 15 ./$LOG_FILE;
			;;
			7)
				printf "###	Scenario $choice. launched...\n" | tee -a $LOG_FILE;
				for i in `smanager.pl status service ^slc |cut -d ":" -f2`;do
					printf "STATUS FOR : $i\n";
					ssh -q root@$i "$(typeset -f SLCstatus); SLCstatus";
				done
			;;
			8)
				printf "###	Scenario $choice. launched...\n" | tee -a $LOG_FILE;
				printf "###	Please provide action stop/start...\n";
				read action;
				labCheck
				if [ $? -eq 0 ];then
					printf "### ${action}ing all ATFC's\n";
					for i in `cat /etc/hosts |grep clab|cut -d " " -f2|cut -d "." -f1`;do smanager.pl $action service atfc-$i;done
				else
					printf "###	Lab is not clab. please provide hostname prefix (clab/vsp/sprint etc)... "
					read host;
					printf "### ${action}ing all ATFC's\n";
					for i in `cat /etc/hosts |grep $host|cut -d " " -f2|cut -d "." -f1`;do smanager.pl $action service atfc-$i;done
				fi
			;;
			9| exit)
				printf "###	Scenario $choice. launched...\n" | tee -a $LOG_FILE;
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
				printf "\nWrong parameter provided. Exiting... \n" | tee -a $LOG_FILE;
				sleep 2;
				exit 0;
			;;
		esac
		unset choice
	done
#fi
