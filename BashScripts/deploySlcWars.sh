#!/bin/bash

#Script for deploying wars from given path
#Restart of slc executed

path_to_wars=$1
webaps=/usr/share/tomcat_slc/webapps
slclib=/opt/oss/NSN-slc/lib
mode=640

if [[ $# -eq 1 && $(ls $path_to_wars | grep "\.war" | wc -l) -gt 0 ]];then
	echo "Backuping war in $webaps to $path_to_wars/bak";
	mkdir -p $path_to_wars/bak;
	cp $slclib/*.war $path_to_wars/bak;
	echo "Are you sure to deploy new wars in $webaps ? y/n";
	read ans;
	if [ $ans == 'y' ];then
		smanager.pl stop service slc-`hostname -s`;
			for i in `ls $path_to_wars | grep "\.war"|cut -d "." -f 1`;do
				echo "-----------------------------------";
				echo "Installing $path_to_wars/$i.war"; 
				for y in `ls $slclib | grep "\.war"`;do
					if [[ $y == *"$i"* ]];then
						echo "Exchanging $path_to_wars/$i.war $webaps/$y.war ..."; 
						install -o tomcat -g tomcat -m $mode $path_to_wars/$i.war $slclib/$y.war;
						
						echo "Removing $webaps/$y";
						rm -rf $webaps/$y;
					fi
				done
			done
				 

		smanager.pl start service slc-`hostname -s`;
	else
		echo "OK. Bye";
		exit 0;
	fi
else
	echo "Missing: location or war files are missing";
	echo "Usage example: `basename $0` /root/";
	exit 0;
fi
	

