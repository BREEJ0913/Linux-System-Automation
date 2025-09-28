!/bin/bash

#Yum Server Installation

echo "Welcome to Yumserver Installation"

mkdir /mnt/yumserver 2> /dev/null
#ISO PATH FINDING
iso_path=$(lsblk -nr -o NAME,MOUNTPOINT | grep sr1 | awk '{print $2}')
Dest_path="/mnt/yumserver"
echo -n "Copying files"
while true; do
    echo -n "."
    sleep 0.5
done &
dot_pid=$!

cp -r "$iso_path/BaseOS" "$Dest_path"
cp -r "$iso_path/AppStream" "$Dest_path"

kill $dot_pid
echo " Copying file done!"

#Creating repo
echo -n "Creating repos"
while true; do
    echo -n "."
    sleep 0.5
done &
dot_pid=$!

cat <<EOF >/etc/yum.repos.d/local.repo
[AppStream]
name=AppStream.repo
baseurl=file:///mnt/yumserver/AppStream
enabled=1
gpgcheck=0

[BaseOS]
name=BaseOS.repo
baseurl=file:///mnt/yumserver/BaseOS
enabled=1
gpgcheck=0
EOF

kill $dot_pid
echo "Repo creation done!"

yum update all 2> /dev/null

echo -e "Yum Server Created Successfully \n Thanks for your Patience!"
