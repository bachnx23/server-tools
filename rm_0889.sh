#!/bin/bash

echo "127.0.0.1 dl.0889.org" >> /etc/hosts
kill -9 $(cat /usr/sbin/.conf)
#loại bỏ các thuộc tính bảo vệ file
sudo chattr -ia /usr/sbin/kernel
#xóa file thực thi độc hại
sudo rm -f /usr/sbin/kernel
sudo rm -f /usr/sbin/.conf

echo "remove on crontab"
crontab -l > crontab_backup.txt
crontab -l | grep -v "curl -fsSL dl.0889.org/install.sh" | crontab -