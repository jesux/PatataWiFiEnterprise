#!/bin/bash

echo -e "\033[0;32m[+]\033[0;33m Rename internal wlan interface to wlan_rpi\033[0m"
echo 'SUBSYSTEM=="net", ACTION=="add", DRIVERS=="?*", ATTR{address}=="b8:27:eb:*", ATTR{type}=="1", KERNEL=="wlan*", NAME="wlan_rpi"' > /etc/udev/rules.d/70-persistent-net.rules

echo -e "\n\033[0;32m[+]\033[0;33m Disable wpa_supplicant\033[0m"
systemctl status wpa_supplicant.service
systemctl disable wpa_supplicant.service
systemctl stop wpa_supplicant.service
systemctl status wpa_supplicant.service

echo -e "\n\033[0;32m[+]\033[0;33m Auto init (crontab)\033[0m"
crontab -l -u root | cat - <(echo @reboot sleep 30 \&\& /root/patatawifi/init.sh) | crontab -u root -

echo -e "\n\033[0;32m[+]\033[0;33m Change hostname\033[0m"
hostnamectl set-hostname patatawifi

echo -e "\n\033[0;32m[+]\033[0;33m Change motd\033[0m"
echo ' _______            __                __              __       __ __ ________ __
/       \          /  |              /  |            /  |  _  /  /  /        /  |
$$$$$$$  |______  _$$ |_    ______  _$$ |_    ______ $$ | / \ $$ $$/$$$$$$$$/$$/
$$ |__$$ /      \/ $$   |  /      \/ $$   |  /      \$$ |/$  \$$ /  $$ |__   /  |
$$    $$/$$$$$$  $$$$$$/   $$$$$$  $$$$$$/   $$$$$$  $$ /$$$  $$ $$ $$    |  $$ |
$$$$$$$/ /    $$ | $$ | __ /    $$ | $$ | __ /    $$ $$ $$/$$ $$ $$ $$$$$/   $$ |
$$ |    /$$$$$$$ | $$ |/  /$$$$$$$ | $$ |/  /$$$$$$$ $$$$/  $$$$ $$ $$ |     $$ |
$$ |    $$    $$ | $$  $$/$$    $$ | $$  $$/$$    $$ $$$/    $$$ $$ $$ |     $$ |
$$/      $$$$$$$/   $$$$/  $$$$$$$/   $$$$/  $$$$$$$/$$/      $$/$$/$$/      $$/

The programs included with the Debian GNU/Linux system are free software;
the exact distribution terms for each program are described in the
individual files in /usr/share/doc/*/copyright.

Debian GNU/Linux comes with ABSOLUTELY NO WARRANTY, to the extent
permitted by applicable law.
' > /etc/motd

echo -e "\n\033[0;32m[+]\033[0;33m Regenerate SSH Host Keys\033[0m"
systemctl enable regenerate_ssh_host_keys

echo -e "\n\033[0;32mRaspi-Install Finished! \033[0m"