#!bin/bash

# Script Header Information
# Student Name: May
# Class Code: S5
# Lecturer: Erel

# Color codes for text styling in the output and variables
GREEN="\e[0;32m"
RED="\e[31m"
STOP="\e[0m"
BOLD="\e[1m"
CYAN="\e[0;36m"
LOG_FILE="/home/kali/Desktop/Log_Folder/project.log"
nipestart=$(find -type d -name nipe -exec realpath {} \; | head -1) >/dev/null 2>&1

# Function: Remote Server Details and Execution
function REMOTE_CONTROL()
{
	LOG "Starting Remote Control Function." >/dev/null 2>&1
	remoteip=$(echo "$ssh_pass" | sudo -S sshpass -p "$ssh_pass" ssh $ssh_user@$ssh_ip 'hostname -I')
	remoteipublic=$(sshpass -p "$ssh_pass" ssh $ssh_user@$ssh_ip 'curl ifconfig.me')
	LOG "Installing geoip-bin on remote server." >/dev/null 2>&1
	geoip=$(echo "$ssh_pass" | sudo -S sshpass -p "$ssh_pass" ssh $ssh_user@$ssh_ip "echo '$ssh_pass' | sudo -S DEBIAN_FRONTEND=noninteractive apt-get install -y geoip-bin")
	remotecountry=$(geoiplookup $remoteipublic | awk '{print($NF)}')
	remoteuptime=$(echo "$ssh_pass" | sudo -S sshpass -p "$ssh_pass" ssh $ssh_user@$ssh_ip 'uptime -p')
	echo "$geoip" >/dev/null 2>&1
	LOG "Remote server details fetched: IP: $remoteip, Country: $remotecountry, Uptime: $remoteuptime." >/dev/null 2>&1
	echo ""
	printf "${CYAN}${BOLD}"
	echo "IP address: $remoteip"
	echo "Country: $remotecountry"
	echo -e "Uptime: $remoteuptime\n"
	printf "${STOP}"
	# Check if the 'Remote' folder exists on the remote server
	folder=$(echo "$ssh_pass" | sudo -S sshpass -p "$ssh_pass" ssh $ssh_user@$ssh_ip 'find ~/Desktop -type d -name Remote')
	if [ "$folder" ]
	then 
		LOG "Remote directory found, transferring script." >/dev/null 2>&1
		sshpass -p "$ssh_pass" scp /home/kali/Desktop/remote.sh $ssh_user@$ssh_ip:/home/kali/Desktop/Remote
		sshpass -p "$ssh_pass" ssh $ssh_user@$ssh_ip "bash /home/kali/Desktop/Remote/remote.sh '$ssh_pass'"
	else
		LOG "Remote directory not found, creating and transferring script." >/dev/null 2>&1
		sshpass -p "$ssh_pass" ssh -o StrictHostKeyChecking=no $ssh_user@$ssh_ip 'mkdir ~/Desktop/Remote'
		sshpass -p "$ssh_pass" scp /home/kali/Desktop/remote.sh $ssh_user@$ssh_ip:/home/kali/Desktop/Remote
		sshpass -p "$ssh_pass" ssh $ssh_user@$ssh_ip "bash /home/kali/Desktop/Remote/remote.sh '$ssh_pass'"
	fi
		
}

# Function: INFORMATION for running whois and nmap on the remote server
function INFORMATION()
{
	LOG "Starting INFORMATION Function for scanning via the remote server." >/dev/null 2>&1
	echo "Please provide the address to scan via the remote server"
	read ip_scan
	count=$(ls ~/Desktop/nmap*.txt 2>/dev/null | wc -l)
	new_count=$((count + 1))
	whois_file="whois${new_count}.txt"
    nmap_file="nmap${new_count}.txt"
    LOG "Running whois and nmap on the remote server for IP: $ip_scan." >/dev/null 2>&1
	sshpass -p "$ssh_pass" ssh $ssh_user@$ssh_ip "whois '$ip_scan' > ~/Desktop/$whois_file"
	sshpass -p "$ssh_pass" ssh $ssh_user@$ssh_ip "nmap -p- '$ip_scan' --open > ~/Desktop/$nmap_file"
	LOG "Transferring whois and nmap results to local machine." >/dev/null 2>&1
	sshpass -p "$ssh_pass" scp $ssh_user@$ssh_ip:/home/kali/Desktop/$nmap_file /home/kali/Desktop/
	sshpass -p "$ssh_pass" scp $ssh_user@$ssh_ip:/home/kali/Desktop/$whois_file /home/kali/Desktop/
}


# Function: Check if the user is anonymous using Nipe and GeoIP
function ANONYMOUS()
{
	LOG "Checking anonymity status." >/dev/null 2>&1
	printf "${CYAN}"
	echo -e "[ ! ] Wait, first thing checking if you are anonymous\n"
	echo -e "This might take a while, we're doing some updates...\n"
	printf "${STOP}"
	LOG "Updating system packages." >/dev/null 2>&1
	echo "$password" | sudo -S apt-get update >/dev/null 2>&1
	echo "$password" | sudo -S apt-get install -y geoip-bin >/dev/null 2>&1
	NIPE=$(cd $nipestart | sudo perl nipe.pl status | grep Ip: | awk '{print $3}')
	COUNTRY=$(geoiplookup "$NIPE" | awk '{print ($NF)}')
	
		if [ "$COUNTRY" == "Israel" ]
		then 
			LOG "User is not anonymous." >/dev/null 2>&1
			printf "${RED}${BOLD}"
			echo "[ X ]You are not anonymous!!! EXITING!![ ⚠ ]"
			printf "${STOP}"
			exit
		else
			LOG "User is anonymous, country: $COUNTRY." >/dev/null 2>&1
			printf "${GREEN}"
			echo "[ ✔ ] You got it! You are anonymous <3"
			echo -e "Country: $COUNTRY\n"
			printf "${STOP}"
			sleep 1
		fi	
}

# Function: Check if SSHPASS is installed and install if necessary
function INSTALL_SSHPASS()
{
	LOG "Checking if sshpass is installed." >/dev/null 2>&1
	ssh=$(which sshpass)
	if [ "$ssh" == "/usr/bin/sshpass" ]
	then 
		LOG "SSHPASS is already installed." >/dev/null 2>&1
		printf "${GREEN}"
		echo -e "[ * ] You already have SSHPASS...\n"
		printf "${STOP}"
	else 
		LOG "SSHPASS not found. Installing it." >/dev/null 2>&1
		printf "${RED}"
		echo -e "[ ! ] You need sshpass also, Installing sshpass...\n"
		printf "${STOP}"
		echo "$password" | sudo apt-get install sshpass >/dev/null 2>&1
		echo -e "Finish installing SSHPASS..\n"
	fi
}

# Function: Check if Nipe is installed and install if necessary
function INSTALL_NIPE() 
{
	LOG "Checking if Nipe is installed." >/dev/null 2>&1
	nipe=$(find -type f -name nipe.pl 2>/dev/null)
	if [ "$nipe" ]
	then 
		LOG "Nipe is already installed." >/dev/null 2>&1
		printf "${GREEN}"
		echo -e "[ * ] The tool Nipe is already exists...\n"
		printf "${STOP}"
		cd $nipestart
		LOG "Stopping and restarting Nipe." >/dev/null 2>&1
		echo "$password" | sudo -S perl nipe.pl stop
		echo "$password" | sudo -S perl nipe.pl restart
	else 
		LOG "Nipe not found. Installing it." >/dev/null 2>&1
		printf "${RED}"
		echo -e "[ ! ]You don't have Nipe... don't worry, it's installing right now!!\n"
		printf "${STOP}"
		cd ~/Desktop
		echo "$password" | sudo -S git clone https://github.com/htrgouvea/nipe >/dev/null 2>&1
		cd nipe >/dev/null 2>&1
		echo "$password" | sudo -S apt-get install -y cpanminus >/dev/null 2>&1
		echo "$password" | sudo -S cpanm --installdeps . >/dev/null 2>&1
		echo "$password" | sudo -S cpan install try::Tiny Config::Simple JSON >/dev/null 2>&1
		echo "$password" | sudo -S perl nipe.pl install >/dev/null 2>&1
		echo "$password" | sudo -S perl nipe.pl start
		echo "$password" | sudo -S perl nipe.pl restart
		echo -e "Finish installing Nipe..\n" 
	fi  
}	

# Function: Check or create the Log_Folder
function LOG_Folder()
{
	
    LOG "Checking or creating Log_Folder directory." >/dev/null 2>&1
    Log_Folder=$(find ~/Desktop -type d -name Log_Folder)
    if [ "$Log_Folder" ]
    then 
		touch ~/Desktop/Log_Folder/project.log
	else
		cd ~/Desktop
		mkdir Log_Folder
		touch ~/Desktop/Log_Folder/project.log
	fi
}

# Function: Log function for recording messages with timestamps
function LOG()
{
	message="$1"
	timestamp=$(date "+%Y-%m-%d %H:%M:%S")
	echo "$timestamp - $message" | tee -a "$LOG_FILE"
	echo "" | tee -a "$LOG_FILE"
}

# Main Execution
LOG "Starting script execution." >/dev/null 2>&1
figlet "My first project"
printf "${CYAN}${BOLD}"
# Prompt user for the system password
echo -e "Please provide me the password for the system:\n"
printf "${STOP}"
read -s password
LOG_Folder
sleep 2
INSTALL_NIPE
sleep 1
INSTALL_SSHPASS
sleep 1
LOG "Installation of required tools completed." >/dev/null 2>&1
printf "${GREEN}${BOLD}"
echo -e "[ ✔ ]Perfect!!!! You have the needed applications, Let's start!![ ✔ ]\n"
printf "${STOP}"
sleep 1
ANONYMOUS
printf "${BOLD}"
echo -e "[ ! ] [ ! ] We're beginning remote control [ ! ] [ ! ]\n"
printf "${STOP}"
sleep 1
# Prompt user for remote server details
echo "Please type the username for the remoste server:"
read ssh_user
echo -e "Please provide the password for the user of the remote server:\n"
read -s ssh_pass
echo "Please provide the IP address of the remote server:"
read ssh_ip
REMOTE_CONTROL
INFORMATION
printf "${CYAN}${BOLD}"
echo "We're done! you have all the info on your Desktop [ ! ]"
echo "Have a nice day!!"
printf "${STOP}"
figlet "GOODBYE😉"

# Credits: ChatGPT.com, github
