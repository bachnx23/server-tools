#!/bin/bash

os=$(cat /etc/*elease | rpm --eval '%{centos_ver}')
systemName=$(awk -F= '/^NAME/{print $2}' /etc/os-release)

RESET_COLOR='\033[0m'
## text color
WARNING='\033[1;33m'
DANGER='\033[1;31m'
SUCCESS='\033[1;32m'
BLACK='\033[1;30m'
WHITE='\033[1;37m'

#echo -e $SUCCESS"CentOS version: $OS"$RESET_COLOR

if [[ -f /etc/centos-release && $(grep -c "CentOS Linux release 7" /etc/centos-release) -eq 1 ]]; then
    firewallVer="firewalld"
elif [[ -f /etc/lsb-release && $(grep -c "DISTRIB_ID=Ubuntu" /etc/lsb-release) -eq 1 ]]; then
    firewallVer="firewalld"
else
    firewallVer="iptable"
fi

if [[ "$firewallVer" == "firewalld" ]];then
    echo -e $WHITE"***\nCheck FIREWALLD"$RESET_COLOR
    checkFirewalld=$(yum list installed | grep firewalld)
    
    if [[ ! $checkFirewalld ]];then
        echo -e $WARNING"Start install Firewalld. "$RESET_COLOR
        yum -y install firewalld
        systemctl enable firewalld
        systemctl start firewalld
    else 
        systemctl enable firewalld
        systemctl start firewalld
    fi
    
    firewall-cmd --permanent --add-service=http
    firewall-cmd --permanent --add-service=https
    firewall-cmd --reload

    firewall-cmd --zone=work --add-source=118.70.126.121/24 --permanent # Megaads Office
    firewall-cmd --zone=work --add-source=95.111.200.151/24 --permanent # CI Jenkins
    firewall-cmd --zone=work --add-source=128.199.228.58/24 --permanent # hamster.megaads.vn -- auto let's encrypt
    firewall-cmd --zone=work --add-source=188.166.226.120/24 --permanent # monitor.megaads.vn
    firewall-cmd --reload
    firewall-cmd --zone=work --add-service=ssh --permanent
    firewall-cmd --reload
    firewall-cmd --zone=public --remove-service=ssh --permanent
    firewall-cmd --zone=public --remove-port=22/tcp --permanent
    firewall-cmd --zone=public --remove-port=22/udp --permanent
    firewall-cmd --reload
else
    iptables -A INPUT -p tcp --dport 22 -s 118.70.126.121 -j ACCEPT
    iptables -A INPUT -p tcp --dport 22 -s 95.111.200.151 -j ACCEPT
    iptables -A INPUT -p tcp --dport 22 -s 128.199.228.58 -j ACCEPT
    iptables -A INPUT -p tcp --dport 22 -s 188.166.226.120 -j ACCEPT
    iptables -A INPUT -p tcp --dport 22 -j DROP
    iptables-save > /etc/sysconfig/iptables
    service iptables restart
fi
