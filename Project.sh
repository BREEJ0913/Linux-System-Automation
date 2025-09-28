#!/bin/bash

#This Script should be run after the Installation of Rhel Machine
#This Script is made for System Hardening and Basic User utilities
#Author : Breej b Bagadia
if [ $(whoami) = "root" ]; then
	echo "Script is running by root user"
else
	echo "Please Make sure script is running by a root user"
	exit
fi

echo "======================================================================================================================================================="
echo  "                                                                ""Greetings $(whoami)"
echo "======================================================================================================================================================="
read -p "Let's Create User you want to:" name
useradd $name
read -s -p "Password for $name:" pass
echo "$name:$pass" | chpasswd
echo -e "\nUser $name Created"
if grep -qiE "red hat|rhel|centos|rocky|almalinux" /etc/*release 2>/dev/null; then
    echo "✅ This system is RHEL-based."
else
    echo "❌ This system is NOT RHEL-based."
fi


#=========================================================================================================================================================
								#User and Password Configurations
#=========================================================================================================================================================
sed -i '/auth        required                                     pam_env.so/i auth        required      pam_faillock.so preauth silent deny=3 unlock_time=600' /etc/pam.d/system-auth
sed -i '/auth        required      pam_faillock.so preauth silent deny=3 unlock_time=600/a  auth        [success=1 default=bad] pam_unix.so' /etc/pam.d/system-auth
sed -i '/auth        \[success=1 default=bad\] pam_unix.so/a auth        [default=die] pam_faillock.so authfail deny=3 unlock_time=600' /etc/pam.d/system-auth
sed -i '/account     required                                     pam_unix.so/i account     required      pam_faillock.so' /etc/pam.d/system-auth
sed -i '/auth        required                                     pam_env.so/i auth        required      pam_faillock.so preauth silent deny=3 unlock_time=600' /etc/pam.d/password-auth
sed -i '/auth        required      pam_faillock.so preauth silent deny=3 unlock_time=600/a  auth        [success=1 default=bad] pam_unix.so' /etc/pam.d/password-auth
sed -i '/auth        \[success=1 default=bad\] pam_unix.so/a auth        [default=die] pam_faillock.so authfail deny=3 unlock_time=600' /etc/pam.d/password-auth
sed -i '/account     required                                     pam_unix.so/i account     required      pam_faillock.so' /etc/pam.d/password-auth
sed -i '11s/8/12/' /etc/security/pwquality.conf
sed -i '11s/#//' /etc/security/pwquality.conf
sed -i '15s/0/-1/' /etc/security/pwquality.conf
sed -i '15s/#//' /etc/security/pwquality.conf
sed -i '20s/0/-1/' /etc/security/pwquality.conf
sed -i '20s/#//' /etc/security/pwquality.conf
sed -i '25s/0/-1/' /etc/security/pwquality.conf
sed -i '25s/#//' /etc/security/pwquality.conf
sed -i '30s/0/-1/' /etc/security/pwquality.conf
sed -i '30s/#//' /etc/security/pwquality.conf
sed -i '1s/\/bin\/bash/\/sbin\/nologin/' /etc/passwd
sed -i '40s/prohibit-password/no/' /etc/ssh/sshd_config
chage -m 1 -M 90 -W 14 -I 30 $name
echo -n -e "\nConfiguring User Account and Password Complexity"
for i in {1..5}; do
    echo -n "."
    sleep 1
done
echo |

echo "Completed!"

#=============================================================================================================================================================
									#File Permissions
#=============================================================================================================================================================

chmod 644 /etc/passwd /etc/group
chmod 600 /etc/shadow /etc/gshadow
chown root:root /etc/passwd /etc/shadow /etc/group /etc/gshadow
usermod -aG wheel $name
sed -i '81i Defaults    logfile="/var/log/sudo.log"\nDefaults    log_input,log_output' /etc/sudoers
echo -n -e "\nConfiguring File Permissions!"
for i in {1..5}; do
    echo -n "."
    sleep 1
done
echo |

echo "Completed!"
#=============================================================================================================================================================									#Firewall Configuration
#============================================================================================================================================================

rpm -q firewalld &> /dev/null |
systemctl enable firewalld &> /dev/null |
systemctl start firewalld &> /dev/null |
firewall-cmd --permanent --add-port=22/tcp &> /dev/null |
firewall-cmd --permanent --add-port=80/tcp &> /dev/null |
firewall-cmd --permanent --add-port=443/tcp &> /dev/null |
firewall-cmd --reload &> /dev/null |
firewall-cmd --set-default-zone=drop &> /dev/null |
firewall-cmd --reload &> /dev/null |

echo -n -e "\nFirewall Configuration"
for i in {1..5}; do
    echo -n "."
    sleep 1
done
echo |

echo "Completed!"

#=============================================================================================================================================================
							         #Yum Server Installation
#=============================================================================================================================================================

#Yum Server Installation

echo "Yum Server Installation"

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

yum update all &> /dev/null

echo -e "Yum Server Created Successfully \n Thanks for your Patience!"
#=============================================================================================================================================================
									#System Restore point
#=============================================================================================================================================================
echo "Initiating Restore point Creation"

# Spinner function
spinner() {
    local pid=$1
    local delay=0.1
    local spinstr='|/-\'
    while kill -0 $pid 2>/dev/null; do
        for i in $(seq 0 3); do
            printf "\r[%c] Loading..." "${spinstr:i:1}"
            sleep $delay
        done
    done
    printf "\r[✔] Done!           \n"
}

# 1. Install ReaR quietly
(sudo yum install rear gnupg -y &> /dev/null) &
pid=$!
spinner $pid
wait $pid

# 2. Check for removable media
check=$(cat /sys/block/sd*/removable 2>/dev/null | grep -q "1"; echo $?)

if [ $check -eq 0 ]; then
    echo "Removable media detected. Starting restore point creation..."

    # Mount removable media
    MOUNT_POINT="/mnt/usb"
    DEVICE=$(lsblk -dpno NAME,RM | grep "1$" | awk '{print $1}' | head -n1)
    PART=$(lsblk -lnp $DEVICE | awk 'NR>1 {print $1; exit}')
    [ -z "$PART" ] && PART=$DEVICE

    if ! mountpoint -q $MOUNT_POINT; then
        mkdir -p $MOUNT_POINT
        mount $PART $MOUNT_POINT || { echo "Mount failed! Skipping restore point."; exit 1; }
    fi

    # Ensure backup directory exists
    [ ! -d "$MOUNT_POINT/localhost" ] && mkdir -p "$MOUNT_POINT/localhost"

    # Check free space (min 1GB)
    avail=$(df --output=avail -k "$MOUNT_POINT" | tail -1)
    if [ $avail -lt 1048576 ]; then
        echo "Not enough free space (need >1GB). Aborting."
        exit 1
    fi

    # Create ReaR config
    rear_config="/tmp/rear-temp"
    mkdir -p "$rear_config"
    cat <<EOF > "$rear_config/local.conf"
BACKUP=NETFS
BACKUP_URL=file://$MOUNT_POINT
CREATE_RESCUE=YES
OUTPUT=BACKUP
COMPRESS=gzip
ENCRYPT_BACKUP=YES
EOF

    # 3. Run ReaR backup with spinner
    (rear -v mkbackup -c "$rear_config" &> /dev/null) &
    pid=$!
    spinner $pid
    wait $pid
    status=$?

    # Check backup result
    if [ $status -eq 0 ] && ls "$MOUNT_POINT/localhost/"backup* >/dev/null 2>&1; then
        echo "Restore point created successfully at $MOUNT_POINT/localhost/"
    else
        echo "Restore point creation FAILED. Check /var/log/rear/rear-localhost.log"
    fi

    rm -rf "$rear_config"

else
    echo "No removable media found. Skipping restore point..."
fi

# Continue with other tasks
echo "Executing further tasks...."
#=============================================================================================================================================================							       	#Tuned Profile setup and Managing SElinux Policies
#=============================================================================================================================================================
echo -n "Applying Tuned Profile"
while true; do
    echo -n "."
    sleep 0.5
done &
dot_pid=$!

systemctl enable tuned
systemctl start tuned
recommend=$(tuned-adm recommend)
tuned-adm  profile $recommend


sed -i '22s/Permissive/Enforcing/' /etc/sysconfig/selinux &> /dev/null
setsebool -P httpd_enable_homedirs off &> /dev/null
setsebool -P ftpd_full_access off &> /dev/null
setsebool -P ssh_sysadm_login off &> /dev/null
setsebool -P mysql_connect_any off &> /dev/null
kill $dot_pid

echo -e "\nThanks For using this script!"
echo -n -e "\nSystem will restart in 5 seconds"
for i in {1..5}; do
    echo -n "."
    sleep 1
done
echo |
echo "Restarting"
init 6
