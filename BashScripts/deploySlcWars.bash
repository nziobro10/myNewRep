#!/bin/bash

#Script for deploying wars from given path
#Restart of slc executed

path_to_wars=$1
webaps=/usr/share/tomcat_slc/webapps/
mode=640

if [ #? -eq 1 ];then
	
	echo "Backuping war in $webaps to $path_to_wars/bak";
	mkdir -p $path_to_wars/bak;
	cp $webaps/*.war $path_to_wars/bak;
	
	echo "Are you sure to deploy new wars in $webaps ? y/n";
	read ans;
	if [ 'ans' == 'y'];then
		smanager.pl stop service slc-`hostname -s`;
		for i in `ls $path_to_wars | grep "\.war"`;do
			echo "Installing `ls $webaps |grep $i`"; 
			actualwar=`ls $webaps |grep $i`;
			install -o tomcat -g tomcat -m $mode $path_to_wars/$i $actualwar; 
		done
		for y in `ls /usr/share/tomcat_slc/webapps/ |grep -v "\.war"`;do
			echo "Removing $y";
			rm -rf $webaps/$y;
		done
		smanager.pl start service slc-`hostname -s`;
	else
		echo "OK. Bye";
		exit 0;
	fi
else
	echo "Parameter: path to war to deploy missing";
	echo "Example: `basename $0` /root/";
fi