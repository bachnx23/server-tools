#!/bin/bash

RESET_COLOR='\033[0m'
## text color
WARNING='\033[1;33m'
DANGER='\033[1;31m'
SUCCESS='\033[1;32m'
BLACK='\033[1;30m'
WHITE='\033[1;37m'


executeInstall() {

    ## Add repo
    echo -e $WHITE"***\nCheck HTTPD"$RESET_COLOR
    check_httpd=$(yum list installed | grep httpd)
    if [[ ! $check_httpd ]];then
        echo -e $WARNING"Start install Apache 2.4 webserver. "$RESET_COLOR
        yum install http://rpms.remirepo.net/enterprise/remi-release-7.rpm
        yum -y install httpd rsync htop screen wget nano telnet
        yum -y install certbot python2-certbot-apache mod_ssl
        systemctl enable httpd
        systemctl start httpd
    else
        http_version=$(httpd -v | awk '/Server version: / {print $3;}')
        echo -e $WARNING"Installed version ${http_version}"$RESET_COLOR
    fi

    echo -e $WHITE"***\nCheck MySQL"$RESET_COLOR
    check_mysql=$(yum list installed | grep mysql)
    if [[ ! $check_mysql ]]; then
        echo -e $WARNING"Start install MySQL server version 5.7 "$RESET_COLOR
        ## Add Repo mysql 5.7 
        rpm --import https://repo.mysql.com/RPM-GPG-KEY-mysql-2022 
        yum localinstall https://dev.mysql.com/get/mysql57-community-release-el7-11.noarch.rpm 
        
        yum -y install mysql-community-server
        systemctl enable mysqld
        systemctl start mysqld 
        mysql_password=$(sudo grep 'temporary password' /var/log/mysqld.log 2>&1)
        echo -e "MySQL new install password: "$mysql_password""$RESET_COLOR
    else 
        mysql_version=$(mysql -V | awk '/Distrib/ {print $5;}' | sed -e 's/,//g')
        echo -e $WARNING"Installed version ${mysql_version}"$RESET_COLOR
    fi

    echo -e $WHITE"***\nCheck PHP"$RESET_COLOR
    check_php=$(yum list installed | grep php)
    if [[ ! $check_php ]];then
        sudo yum install epel-release yum-utils
        read -p $WHITE"What version php want install? (70,71,72,73,74,80) "$RESET_COLOR phpVersion
        echo -e "\033[0;34mPHP version $phpVersion will be install in this server\033[\r";
        echo "#################################################################";
        echo "Start install PHP ${phpVersion}"

        yum-config-manager --enable remi-php"${phpVersion}"
        yum -y install php
        yum -y install unzip php-cli php-xml php-pecl-zip php-mbstring php-pdo php-pdo_mysql php-gd php-mcrypt php-redis php-bcmath php-soap php-devel 

        php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');"
        php composer-setup.php --install-dir=/usr/local/bin --filename=composer
    else       
        php_version=$(php -v | awk '/PHP / {print $2;}' | sed -e 's/(c)//g')
        echo -e $WARNING"Installed version ${php_version}"$RESET_COLOR
    fi      
    
    echo -e $WHITE"***\nCheck JAVA"$RESET_COLOR
    check_java=$(yum list installed | grep java)
    if [[ ! $check_java ]];then
        echo -e $WARNING"Install Java."$RESET_COLOR
        yum -y install java-1.8.0-openjdk.x86_64
        java_version=$(java -version 2>&1)
        echo -e $WARNING"${java_version}"$RESET_COLOR
    fi

    echo -e $WHITE"***\nCheck Elastichsearh"$RESET_COLOR
    check_els=$(yum list installed | grep elasticsearch)
    if [[ ! $check_els ]];then
        echo -e $WARNING"Install Elastichsearch. "$RESET_COLOR
        echo -e $WHITE"What version of Elastichearch want to install: "$RESET_COLOR
        read -p "" elasticsearch_version
        if [[ $elasticsearch_version == "1.5.2" ]];then
                elasticsearch_url="https://download.elastic.co/elasticsearch/elasticsearch/elasticsearch-1.5.2.noarch.rpm"
        elif [[ $elastichearch_version == "5.4.0" ]];then
                elasticsearch_url="https://artifacts.elastic.co/downloads/elasticsearch/elasticsearch-5.4.0.rpm"
        fi

        if [[ $elasticsearch_url ]];then 
                curl "${elasticsearch_url}" -o "elasticsearch-${elasticsearch_version}.rpm"
                if [[ -f "elasticsearch-${elasticsearch_version}.rpm" ]];then
                    sudo rpm -ivh "elasticsearch-${elasticsearch_version}.rpm"
                fi
        fi
    else 
        els_version=$(curl  -s http://localhost:9200 | awk '/number/ {print $3;}' | sed -e 's/"//g' | sed -e 's/,//')
        echo -e $WARNING"Installed version ${els_version}"$RESET_COLOR
    fi

    echo -e $WHITE"***\nCheck NODEJS"$RESET_COLOR
    check_nodejs=$(yum list installed | grep node)
    if [[ ! $check_nodejs ]];then
        echo -e $WARNING"What version node you want to install? "$RESET_COLOR
        read -p "" nodeVersion
    
        curl -sL https://rpm.nodesource.com/setup_"${nodeVersion}".x | sudo bash -
        yum -y install nodejs
        sudo npm install --global cross-env
    else
        node_version=$(node --version | sed -e 's/v//g')
        echo -e $WARNING"Installed version ${node_version}"$RESET_COLOR
    fi

    echo -e $WHITE"***\nCheck GIT"$RESET_COLOR
    check_git=$(yum list installed | grep git)
    if [[ ! $check_git ]];then
        echo -e $WARNING"Start install Git"$RESET_COLOR
        yum -y install git
    else 
        git_version=$(git --version | sed -e 's/git version //g')
        echo -e $WARNING"Installed version ${git_version}"$RESET_COLOR
    fi

    echo -e $WHITE"***\nCheck REDIS"$RESET_COLOR
    check_redis=$(yum list installed | grep redis)
    if [[ ! $check_redis ]];then
        echo -e $WARNING"Start install Redis. "$RESET_COLOR
        yum -y install epel-release
        yum -y install redis
        systemctl start redis.service
        systemctl enable redis
    else 
        redis_version=$(redis-server --version | awk '/v=/ {print $3;}' | sed -e 's/v=//g')
        echo -e $WARNING"Installed version ${redis_version}"$RESET_COLOR
    fi

    echo -e $WHITE"***\nCheck Maven"$RESET_COLOR
    check_maven=$(yum list installed | grep mvn)
    if [[ ! $check_maven ]];then
        echo -e $WARNING"Start install Maven. ".$RESET_COLOR
        yum -y install maven
    else 
        maven_version=$(mvn --version | awk '/Apache/ {print $3;}')
        echo -e $WARNING"Installed version ${maven_version}"$RESET_COLOR
    fi      

}
echo -e $WARNING"Do you want to new install? (yes/no) " $RESET_COLOR
read -p "" yn

case $yn in
        yes ) executeInstall ;;
        no ) echo bye bye...;
                exit;;
        * ) echo invalid response;
                exit 1;;
esac
