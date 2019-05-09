#!/bin/bash 

function makelog(){

        recordsnum=$1
        filename=created_log.txt
        MaxRecordValue=500000



    

                touch ./$filename
                cat > ./$filename << EOL
<?xml version="1.0" encoding="UTF-8"?>
<log xmlns="http://www.nokia.com" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="http://www.nokia.com NWI3_NE_Log_Schema.xsd" id="WBTS-1737" NEName="WBTS" logFileName="ruem_wbts_1737.xml.gz" logType="SECURITY_LOG"  creationTime="`date "+%Y-%m-%d %H:%M:%S GMT"`">
<header>WBTS-1737 Log File</header>
EOL
                        for ((i=1 ; i <= $recordsnum ; i++));do
                                cat >> ./$filename << EOL
<record sessionID="$i" sessionTime="`date "+%Y-%m-%d %H:%M:%S GMT"`" userName="The RUEM">
<operation>RUEM logfile upload</operation>
<clientIPAddress></clientIPAddress>
<logStatus>Success</logStatus>
<additionalText></additionalText>
</record>
EOL
                                echo -ne "###   Filling log file... : $i\r";
                        done
                cat >> ./$filename <<EOL
</log>
EOL

                        filesize=`ls -ltr . |grep $filename | awk '{ print $5 }'`;
                        logtosentsize=$(( $filesize * $repetitions ));
                        logtosentsizeMB=$(( $logtosentsize / 1000000 ));

                printf "\n###   Log file created : `pwd`/$filename with  : `less ./$filename |grep '<rec'|wc -l` records.\n"
                printf "###     Filesize : `ls -ltrh . |grep $filename | awk '{ print $5 }'` what is $filesize bytes.\n"
            
}

makelog $1