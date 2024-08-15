#!/bin/bash

#----------------------------------------------------------------#
# Script name: Install Zabbix agent                              #
# Description: Install and configure Zabbix agent                #
# Author: Marco Antonio da Silva                                 #
# E-mail: marcoa.silva84@gmail.com                               #
# LinkedIn: https://www.linkedin.com/marcosilvarj                #
# Github: https://github.com/marcoantonio11                      #
# Use: ./InstallZabbixAgent2.sh                                  #
#----------------------------------------------------------------#

SERVER_IP=192.168.0.22

echo ' '
echo '###################################################################'
echo '##### This script will install and configure the Zabbix agent #####'
echo '###################################################################'
echo ' '

# Check if the admin knows the passwords
while true; do
echo '###################################################################'
echo '## Did you set the server IP address in the SERVER_IP variable?  ##'
echo '## (Y/N)?                                                        ##'
echo '###################################################################'
read -p "Chosen option: " ANSWER1

   case $ANSWER1 in
      [Y/y])
          echo -e 'Ok, the script will continue...\n'
          sleep 2
   break
          ;;
      [N/n])
          echo 'The script is closing...'
          sleep 2
          exit 1
          ;;
      *)
          echo -e 'Invalid option! Try again.\n'
          sleep 1
          ;;
   esac
done

# Identify the distribution
echo 'Identifying the distribution...'
sleep 2
hostnamectl > /tmp/distro.txt
DISTRO=$(sed -nr 's/Operating System: ([A-Z]{1}[a-z]{1,}) ([A-Z]{1,3}?[a-z]{1,}? ?\/?[A-Z]{1}?[a-z]{1,}? ?[0-9]{1,2}\.?[0-9]{1,2}?).*/\1 \2/p' /tmp/distro.txt)

if [ "$DISTRO" = 'Debian GNU/Linux 12' -o "$DISTRO" = 'Ubuntu 24.04' ]; then
   echo "Your distribution is $DISTRO"
   echo -e 'Continuing...\n'
   sleep 3

   if [ "$DISTRO" = 'Debian GNU/Linux 12' ]; then
     # Install Zabbix repository on Debian 12
      echo 'Installing Zabbix repository...'
      apt install wget -y
      wget https://repo.zabbix.com/zabbix/7.0/debian/pool/main/z/zabbix-release/zabbix-release_7.0-1+debian12_all.deb
      dpkg -i zabbix-release_7.0-1+debian12_all.deb
      apt update
      echo ' '
      sleep 1
   else
      # Install Zabbix repository on Ubuntu 24.04
      echo 'Installing Zabbix repository...'
      apt install wget -y
      wget https://repo.zabbix.com/zabbix/7.0/ubuntu/pool/main/z/zabbix-release/zabbix-release_7.0-1+ubuntu24.04_all.deb
      dpkg -i zabbix-release_7.0-1+ubuntu24.04_all.deb
      apt update
      echo ' '
      sleep 1
   fi

   # Install Zabbix agent2 on Debian 12 or Ubuntu 24.04
   echo 'Install Zabbix agent2...'
   apt install zabbix-agent2 zabbix-agent2-plugin-*
   echo ' '

   # Remove installation file
   echo 'Remove installation file...'
   rm -f zabbix-release*
   echo ' '

elif [ "$DISTRO" = 'Rocky Linux 9.0' -o "$DISTRO" = 'Oracle Linux Server 9.4' ]; then
   echo "Your distribution is $DISTRO"
   echo -e 'Continuing...\n'
   sleep 3

   # Check if the EPEL repository is enabled
   echo 'Checking if the EPEL repository is enabled...'
   if [ -f '/etc/yum.repos.d/epel.repo' ]; then
      echo 'The EPEL repository is enabled.'
      sleep 2
      echo 'Adding line "excludepkgs=zabbix*" in the file "/etc/yum.repos.d/epel.repo"...'
      sed -i '/excludepkgs=zabbix*'/d /etc/yum.repos.d/epel.repo
      sed -i '/\[epel\]/a\excludepkgs=zabbix*' /etc/yum.repos.d/epel.repo
      echo ' '
   else
      echo 'The EPEl repository is not enabled.'
      echo -e 'Nothing to do.\n'
   fi

   if [ "$DISTRO" = 'Rocky Linux 9.0' ]; then
      # Install Zabbix repository on Rocky Linux 9.0
      echo 'Installing Zabbix repository...'
      rpm -Uvh https://repo.zabbix.com/zabbix/7.0/rocky/9/x86_64/zabbix-release-7.0-2.el9.noarch.rpm
      dnf clean all
      echo ' '
      sleep 1
   else
      # Install Zabbix repository on Oracle Linux 9.4
      echo 'Installing Zabbix repository...'
      rpm -Uvh https://repo.zabbix.com/zabbix/7.0/oracle/9/x86_64/zabbix-release-7.0-2.el9.noarch.rpm
      dnf clean all
      echo ' '
      sleep 1
   fi

   # Install Zabbix agent2 on Rocky Linux 9.0 or Oracle Linux 9.4
   echo 'Install Zabbix agent2...'
   dnf -y install zabbix-agent2 zabbix-agent2-plugin-*
   echo ' '

   # Open the firewall on Rocky Linux 9.0 or Oracle Linux 9.4
   echo 'Opening the firewall...'
   firewall-cmd --permanent --zone=public --add-port=10050/tcp
   firewall-cmd --reload
   echo ' '

else
   echo "Your distribution is $DISTRO"
   echo -e 'This distribution is not supported by this script.\n'
   echo 'The distributions supported are:'
   echo '- Debian 12'
   echo '- Oracle Linux 9.4'
   echo '- Rocky Linux 9.0'
   echo -e '- Ubuntu 24.04\n'
   echo -e 'Aborting...\n'
   sleep 1
   exit 1
fi

# Edit Hostname, Server and ServerActive in the file /etc/zabbix/zabbix_agent2.conf
echo 'Editing Hostname, Server and ServerActive in the file /etc/zabbix/zabbix_agent2.conf...'
sed -ri "s/(Hostname=).*/\1$HOSTNAME/" /etc/zabbix/zabbix_agent2.conf
sed -ri "s/(Server=).*/\1$SERVER_IP/" /etc/zabbix/zabbix_agent2.conf
sed -ri "s/(ServerActive=).*/\1$SERVER_IP/" /etc/zabbix/zabbix_agent2.conf
echo ' '

# Start Zabbix agent2 process
echo 'Start Zabbix agent2 process...'
systemctl restart zabbix-agent2
systemctl enable zabbix-agent2
echo ' '

echo -e 'End of script!\n'
