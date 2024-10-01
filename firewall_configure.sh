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

echo -e $WARNING"Current system is $systemName"$RESET_COLOR
echo -e $WHITE"***\nCheck FIREWALL"$RESET_COLOR

if [[ -f /etc/centos-release && $(grep -c "CentOS Linux release 7" /etc/centos-release) -eq 1 ]]; then
    firewallVer="firewalld"
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
elif [[ -f /etc/lsb-release && $(grep -c "DISTRIB_ID=Ubuntu" /etc/lsb-release) -eq 1 ]]; then
    firewallVer="ufw"
    echo -e $WHITE"***\nCheck UFW"$RESET_COLOR
    checkUfw=$(apt list --installed | grep ufw)
    
    if [[ ! $checkUfw ]];then
        echo -e $WARNING"Start install UFW. "$RESET_COLOR
        sudo apt -y install ufw
        yes | sudo ufw enable
    else 
        yes | sudo ufw enable
    fi
elif [[ -f /etc/centos-release && $(grep -c "CentOS release 6" /etc/centos-release) -eq 1 ]]; then
    firewallVer="iptables"
    echo -e $WHITE"***\nCheck IPTABLES"$RESET_COLOR
    checkIptables=$(yum list installed | grep iptables)
    
    if [[ ! $checkIptables ]];then
        echo -e $WARNING"Start install IPTABLES. "$RESET_COLOR
        yum -y install iptables-services
        systemctl enable iptables
        systemctl start iptables
    else 
        systemctl enable iptables
        systemctl start iptables
    fi
else
    echo -e $DANGER"Unsupported OS"$RESET_COLOR
    exit 1
fi

echo -e $WHITE"***\nStarting Configure FIREWALL..."$RESET_COLOR

if [[ "$firewallVer" == "firewalld" ]]; then 
    echo -e $WHITE"***\nAllow Webserver"$RESET_COLOR
    firewall-cmd --permanent --add-service=http
    firewall-cmd --permanent --add-service=https
    firewall-cmd --reload

    echo -e $WHITE"***\nAllow Remote IP"$RESET_COLOR
    firewall-cmd --zone=work --add-source=210.245.49.63/24 --permanent # Megaads Office
    firewall-cmd --zone=work --add-source=95.111.195.231/24 --permanent # CI Jenkins
    firewall-cmd --zone=work --add-source=128.199.228.58/24 --permanent # hamster.megaads.vn -- auto let's encrypt
    firewall-cmd --zone=work --add-source=188.166.226.120/24 --permanent # monitor.megaads.vn
    firewall-cmd --reload
    echo -e $WHITE"***\nAllow SSH TO WORK ZONE"$RESET_COLOR
    firewall-cmd --zone=work --add-service=ssh --permanent
    firewall-cmd --reload
    echo -e $WHITE"***\n REMOVE SERVICES (ssh.) TO PUBLIC ZONE"$RESET_COLOR
    firewall-cmd --zone=public --remove-service=ssh --permanent
    firewall-cmd --zone=public --remove-port=22/tcp --permanent
    firewall-cmd --zone=public --remove-port=22/udp --permanent
    firewall-cmd --zone=public --add-port=4730/tcp --permanent
    firewall-cmd --zone=public --add-port=6379/tcp --permanent
    firewall-cmd --zone=public --add-port=9200/tcp --permanent
    firewall-cmd --zone=public --add-port=3000/tcp --permanent
    firewall-cmd --reload
elif [[ "$firewallVer" == "ufw" ]]; then
    echo -e $WHITE"***\nAllow Webserver"$RESET_COLOR
    yes | sudo ufw allow http
    yes | sudo ufw allow https

    echo -e $WHITE"***\nAllow Remote IP"$RESET_COLOR
    yes | sudo ufw allow from 210.245.49.63 to any # Megaads Office
    yes | sudo ufw allow from 95.111.195.231/24 to any # CI Jenkins
    yes | sudo ufw allow from 128.199.228.58/24 to any # hamster.megaads.vn -- auto let's encrypt
    yes | sudo ufw allow from 188.166.226.120/24 to any # monitor.megaads.vn

    echo -e $WHITE"***\nAllow SSH TO WORK ZONE"$RESET_COLOR
    yes | sudo ufw allow ssh

    echo -e $WHITE"***\n REMOVE SERVICES (ssh.) TO PUBLIC ZONE"$RESET_COLOR
    yes | sudo ufw delete allow 22/tcp
    yes | sudo ufw delete allow 22/udp
    yes | sudo ufw allow 4730/tcp
    yes | sudo ufw allow 6379/tcp
    yes | sudo ufw allow 9200/tcp
    yes | sudo ufw allow 3000/tcp
    yes | sudo ufw enable
    sudo ufw reload

elif [[ "$firewallVer" == "iptables" ]]; then
    iptables -A INPUT -p tcp --dport 80 -j ACCEPT
    iptables -A INPUT -p tcp --dport 443 -j ACCEPT

    iptables -A INPUT -s 210.245.49.63 -j ACCEPT # Megaads Office
    iptables -A INPUT -s 95.111.195.231/24 -j ACCEPT # CI Jenkins
    iptables -A INPUT -s 128.199.228.58/24 -j ACCEPT # hamster.megaads.vn -- auto let's encrypt
    iptables -A INPUT -s 188.166.226.120/24 -j ACCEPT # monitor.megaads.vn

    iptables -A INPUT -p tcp --dport 22 -j ACCEPT
    iptables -D INPUT -p tcp --dport 22 -j ACCEPT
    iptables -D INPUT -p udp --dport 22 -j ACCEPT
    iptables -A INPUT -p tcp --dport 4730 -j ACCEPT
    iptables -A INPUT -p tcp --dport 6379 -j ACCEPT
    iptables -A INPUT -p tcp --dport 9200 -j ACCEPT
    iptables -A INPUT -p tcp --dport 3000 -j ACCEPT
    service iptables save
    service iptables reload
fi

echo -e $SUCCESS"***\nConfigure FIREWALL SUCCESSFULLY"$RESET_COLOR