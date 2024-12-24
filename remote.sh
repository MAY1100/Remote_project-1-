#!bin/bash

# Student Name: May
# Class Code: S5
# Lecturer: Erel

ssh_pass=$1

# Function: Check if Nipe is installed on the remote server and install it if necessary
function NIPE_REMOTE()
{
	nipestart=$(find -type d -name nipe -exec realpath {} \; -quit 2>/dev/null)
	NIPE=$(find -type f -name nipe.pl) >/dev/null 2>&1
	if [ "$NIPE" ]
	then
		echo -e "[ * ] Nipe is already exists...\n"
		cd $nipestart
		echo "$ssh_pass" | sudo -S perl nipe.pl stop
		echo "$ssh_pass" | sudo -S perl nipe.pl restart
	else 
		echo -e "Installing Nipe on the remote serever...\n"
		cd ~/Desktop
		echo "$ssh_pass" | sudo -S git clone https://github.com/htrgouvea/nipe && cd nipe >/dev/null 2>&1
		echo "$ssh_pass" | sudo -S DEBIAN_FRONTEND=noninteractive apt-get install -y cpanminus >/dev/null 2>&1
		echo "$ssh_pass" | sudo -S cpanm --installdeps . >/dev/null 2>&1
		echo "$ssh_pass" | sudo -S cpan install try::Tiny Config::Simple JSON >/dev/null 2>&1
		echo "$ssh_pass" | sudo -S perl nipe.pl install >/dev/null 2>&1
		echo "$ssh_pass" | sudo -S perl nipe.pl start >/dev/null 2>&1
		echo "$ssh_pass" | sudo -S perl nipe.pl restart >/dev/null 2>&1
	fi  
}	

# Function: Check if the remote server is anonymous by using GeoIP and Nipe
function ANONYMOUS_REMOTE()
{
	nipestart=$(find -type d -name nipe -exec realpath {} \; -quit 2>/dev/null)
	echo "$ssh_pass" | sudo -S apt-get update >/dev/null 2>&1
	echo "$ssh_pass" | sudo -S apt-get install -y geoip-bin >/dev/null 2>&1
	nipe=$(cd "$nipestart" && echo "$ssh_pass" | sudo -S perl nipe.pl status | grep Ip: | awk '{print $3}')
	echo -e "IP found by Nipe: $nipe\n"
	COUNTRY=$(geoiplookup $nipe | awk '{print ($NF)}')
		if [ "$COUNTRY" == "Israel" ]
		then
			echo "[ X ]You need to be anonymous to continue!!! EXITING!!"
			exit
		else
			echo -e "[ ✔ ] Yess! You are anonymous!\n"
			echo -e "Country: $COUNTRY\n"
		fi	
}

# Main Execution

echo -e "Checking for Nipe tool...\n"
NIPE_REMOTE
ANONYMOUS_REMOTE
