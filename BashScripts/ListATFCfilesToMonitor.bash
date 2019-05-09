#!/bin/bash

#Lists existing files to be monitored by atfc

NANODE=$1;
FILENAME=$2;



for i in `smanager.pl status service ^$NANODE |cut -d ":" -f 2`;do
        ssh -q $i "echo -ne '\n\nHOSTNAME : $i\n\n';
        ls -ltr /var/opt/oss/log/audit/* |grep $FILENAME;
        ls -ltr /var/log/* |grep $FILENAME;
        ls -ltr /var/opt/oss/NSN-atfc/monitor/snapshot/* |grep $FILENAME;"
done
