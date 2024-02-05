#!/bin/bash

echo ' _______            __                __              __       __ __ ________ __
/       \          /  |              /  |            /  |  _  /  /  /        /  |
$$$$$$$  |______  _$$ |_    ______  _$$ |_    ______ $$ | / \ $$ $$/$$$$$$$$/$$/
$$ |__$$ /      \/ $$   |  /      \/ $$   |  /      \$$ |/$  \$$ /  $$ |__   /  |
$$    $$/$$$$$$  $$$$$$/   $$$$$$  $$$$$$/   $$$$$$  $$ /$$$  $$ $$ $$    |  $$ |
$$$$$$$/ /    $$ | $$ | __ /    $$ | $$ | __ /    $$ $$ $$/$$ $$ $$ $$$$$/   $$ |
$$ |    /$$$$$$$ | $$ |/  /$$$$$$$ | $$ |/  /$$$$$$$ $$$$/  $$$$ $$ $$ |     $$ |
$$ |    $$    $$ | $$  $$/$$    $$ | $$  $$/$$    $$ $$$/    $$$ $$ $$ |     $$ |
$$/      $$$$$$$/   $$$$/  $$$$$$$/   $$$$/  $$$$$$$/$$/      $$/$$/$$/      $$/
'

MY_PATH="$(dirname "$0")"
MY_PATH="$(cd "${MY_PATH}" && pwd)"
INSTALL_PATH="/root/patatawifi"
mkdir -v "${INSTALL_PATH}"

apt update
apt -y install tmux libssl1.0-dev macchanger ethtool rfkill

echo -e "\n\033[0;32m[+]\033[0;33m Installing Dnsmasq\033[0m"
apt -y install dnsmasq
systemctl disable dnsmasq.service
systemctl stop dnsmasq
mkdir -v ${INSTALL_PATH}/dnsmasq
cp -v ${MY_PATH}/files/dnsmasq/* ${INSTALL_PATH}/dnsmasq/


echo -e "\n\033[0;32m[+]\033[0;33m Installing Aircrack-ng 1.7\033[0m"
if [[ -n "$(which aircrack-ng)" && -n "$(aircrack-ng | grep '1\.7')" ]]
then
	echo "aircrack-ng is installed ..."
else
	cd ${INSTALL_PATH}
	apt -y install wireless-tools iw ethtool rfkill
	apt -y install autoconf automake libtool shtool pkg-config
	wget https://download.aircrack-ng.org/aircrack-ng-1.7.tar.gz
	tar zxf aircrack-ng-1.7.tar.gz
	cd aircrack-ng-1.7
	./autogen.sh
	make -j4
	make install
	ldconfig
	airodump-ng-oui-update
	cd ${INSTALL_PATH}
	rm -v aircrack-ng-1.7.tar.gz
	rm -r aircrack-ng-1.7
fi


echo -e "\n\033[0;32m[+]\033[0;33m Installing FreeRadius WPE 2.2\033[0m"
if [[ -n "$(which radiusd)" && -n "$(radiusd -v | grep 'FreeRADIUS-WPE Version 2.1.12')"  ]]
then
	echo "FreeRadius WPE is installed ..."
else
	cd ${INSTALL_PATH}
	apt -y install libssl1.0-dev
	wget ftp://ftp.freeradius.org/pub/radius/old/freeradius-server-2.1.12.tar.gz
	tar zxf freeradius-server-2.1.12.tar.gz
	wget https://raw.github.com/jesux/freeradius-wpe/master/freeradius-wpe.patch
	cd freeradius-server-2.1.12
	patch -p1 < ../freeradius-wpe.patch
	./configure
	make
	make install
	ldconfig
	cd ${INSTALL_PATH}
	rm -v freeradius-wpe.patch
	rm -v freeradius-server-2.1.12.tar.gz
	rm -r freeradius-server-2.1.12
	radiusd -v
fi
mkdir -vp ${INSTALL_PATH}/radiuscfg/default
cp -rv /usr/local/etc/raddb/* ${INSTALL_PATH}/radiuscfg/default
cp -rv ${MY_PATH}/files/radiuscfg/* ${INSTALL_PATH}/radiuscfg/default
sed "s#\[PATH\]#${INSTALL_PATH}#g" ${INSTALL_PATH}/radiuscfg/default/radiusd.conf.template > ${INSTALL_PATH}/radiuscfg/default/radiusd.conf
${INSTALL_PATH}/radiuscfg/default/certs/bootstrap
#radiusd -fX -d ${INSTALL_PATH}/radiuscfg/default #Generar certificado y Testing

echo -e "\n\033[0;32m[+]\033[0;33m Installing Hostapd 2.10\033[0m"
if [[ -n "$(ls ${INSTALL_PATH}/hostapd/hostapd)" ]]
then
	echo "Hostapd 2.10 is installed ..."
else
	cd ${INSTALL_PATH}
	apt install -y libnl-3-dev libnl-genl-3-dev pkg-config
	wget https://w1.fi/releases/hostapd-2.10.tar.gz
	tar zxf hostapd-2.10.tar.gz
	cd hostapd-2.10/hostapd
	sed 's/#CONFIG_IEEE80211N=y/CONFIG_IEEE80211N=y/g; s/#CONFIG_LIBNL32=y/CONFIG_LIBNL32=y/' defconfig > .config
	make -j4
	mv -v ${INSTALL_PATH}/hostapd-2.10/hostapd ${INSTALL_PATH}/hostapd
	rm -r ${INSTALL_PATH}/hostapd-2.10/
	rm -v ${INSTALL_PATH}/hostapd-2.10.tar.gz
fi
cp -rv ${MY_PATH}/files/hostapd/* ${INSTALL_PATH}/hostapd/

echo -e "\n\033[0;32m[+]\033[0;33m Installing Hostapd Mana\033[0m"
if [[ -n "$(ls ${INSTALL_PATH}/hostapd-mana/hostapd/hostapd)" ]]
then
	echo "Hostapd Mana is installed ..."
else
	cd ${INSTALL_PATH}
	apt install -y libnl-3-dev libnl-genl-3-dev
	wget https://github.com/sensepost/hostapd-mana/archive/refs/heads/master.zip -O hostapd-mana.zip
	unzip hostapd-mana.zip
	mv -v ${INSTALL_PATH}/hostapd-mana-master ${INSTALL_PATH}/hostapd-mana
	cd ${INSTALL_PATH}/hostapd-mana
	make -j4 -C hostapd
	cd ${INSTALL_PATH}
	rm -v ${INSTALL_PATH}/hostapd-mana.zip
fi
cp -rv ${MY_PATH}/files/hostapd-mana/* ${INSTALL_PATH}/hostapd-mana/

mkdir -v ${INSTALL_PATH}/logs
cp -v ${MY_PATH}/files/*.sh ${INSTALL_PATH}
chmod +x ${INSTALL_PATH}/*.sh

echo -e "\n\033[0;32mPatataWiFi Ready!\033[0m"