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
apt -y install tmux iptables macchanger libnl-3-dev libnl-genl-3-dev pkg-config
apt -y install wireless-tools iw ethtool rfkill autoconf automake libtool shtool

# LIBSSL-DEV 1.0
#apt -y install libssl1.0-dev
wget https://archive.debian.org/debian-archive/debian/pool/main/o/openssl1.0/libssl1.0.2_1.0.2u-1~deb9u1_arm64.deb
wget https://archive.debian.org/debian-archive/debian/pool/main/o/openssl1.0/libssl1.0-dev_1.0.2u-1~deb9u1_arm64.deb
dpkg -i libssl1.0.2_1.0.2u-1~deb9u1_arm64.deb
dpkg -i libssl1.0-dev_1.0.2u-1~deb9u1_arm64.deb

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
if [[ -n "$(which radiusd)" && -n "$(radiusd -v | grep 'FreeRADIUS-WPE Version 2.1.12')" ]]
then
	echo "FreeRadius WPE is installed ..."
else
	cd ${INSTALL_PATH}
	wget ftp://ftp.freeradius.org/pub/radius/old/freeradius-server-2.1.12.tar.gz
	tar zxf freeradius-server-2.1.12.tar.gz
	wget https://raw.github.com/jesux/freeradius-wpe/master/freeradius-wpe.patch
	cd freeradius-server-2.1.12
	patch -p1 < ../freeradius-wpe.patch
	./configure --build=aarch64-unknown-linux-gnu
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

echo -e "\n\033[0;32m[+]\033[0;33m Installing Hostapd 2.10\033[0m"
if [[ -n "$(ls ${INSTALL_PATH}/hostapd/hostapd)" ]]
then
	echo "Hostapd 2.10 is installed ..."
else
	cd ${INSTALL_PATH}
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
	wget https://github.com/sensepost/hostapd-mana/archive/refs/heads/master.zip -O hostapd-mana.zip
	unzip hostapd-mana.zip
	mv -v ${INSTALL_PATH}/hostapd-mana-master ${INSTALL_PATH}/hostapd-mana
	cd ${INSTALL_PATH}/hostapd-mana
	make -j4 -C hostapd
	cd ${INSTALL_PATH}
	rm -v ${INSTALL_PATH}/hostapd-mana.zip
fi
cp -rv ${MY_PATH}/files/hostapd-mana/* ${INSTALL_PATH}/hostapd-mana/

echo -e "\n\033[0;32m[+]\033[0;33m Installing hcxdumptool\033[0m"
if [[ -n "$(ls ${INSTALL_PATH}/hcxdumptool/)" ]]
then
	echo "hcxdumptool is installed ..."
else
	cd ${INSTALL_PATH}
	wget https://github.com/ZerBea/hcxdumptool/releases/download/6.3.2/hcxdumptool-6.3.2.tar.gz
	tar zxf hcxdumptool-6.3.2.tar.gz
	mv -v ${INSTALL_PATH}/hcxdumptool-6.3.2 ${INSTALL_PATH}/hcxdumptool
	cd ${INSTALL_PATH}/hcxdumptool
	make -j4
	make install
	hcxdumptool -v
	rm -v ${INSTALL_PATH}/hcxdumptool-6.3.2.tar.gz
fi

echo -e "\n\033[0;32m[+]\033[0;33m Installing hostapd-wpe\033[0m"
if [[ -n "$(ls ${INSTALL_PATH}/hostapd-wpe/)" ]]
then
	echo "hostapd-wpe is installed ..."
else
	cd ${INSTALL_PATH}
	git clone https://github.com/OpenSecurityResearch/hostapd-wpe
	wget https://w1.fi/releases/hostapd-2.6.tar.gz
	tar zxf hostapd-2.6.tar.gz
	cd hostapd-2.6
	patch -p1 < ../hostapd-wpe/hostapd-wpe.patch
	cd hostapd
	sed 's/#CONFIG_IEEE80211N=y/CONFIG_IEEE80211N=y/g; s/#CONFIG_LIBNL32=y/CONFIG_LIBNL32=y/' defconfig > .config
	make -j4
	${INSTALL_PATH}/hostapd-wpe/certs/bootstrap
	mv -v ${INSTALL_PATH}/hostapd-wpe/certs ${INSTALL_PATH}/hostapd-2.6/hostapd/
	rm -rf ${INSTALL_PATH}/hostapd-wpe/
	mv -v ${INSTALL_PATH}/hostapd-2.6/hostapd/ ${INSTALL_PATH}/hostapd-wpe
	rm -rf ${INSTALL_PATH}/hostapd-2.6/
	rm -v ${INSTALL_PATH}/hostapd-2.6.tar.gz
fi

# LIBSSL-DEV

echo -e "\n\033[0;32m[+]\033[0;33m Installing hcxtools\033[0m"
if [[ -n "$(ls ${INSTALL_PATH}/hcxtools/)" ]]
then
	echo "hcxtools is installed ..."
else
	cd ${INSTALL_PATH}
	apt -y install pkg-config libcurl4-openssl-dev libssl-dev zlib1g-dev make gcc
	wget https://github.com/ZerBea/hcxtools/releases/download/6.3.2/hcxtools-6.3.2.tar.gz
	tar zxf hcxtools-6.3.2.tar.gz
	mv -v ${INSTALL_PATH}/hcxtools-6.3.2 ${INSTALL_PATH}/hcxtools
	cd ${INSTALL_PATH}/hcxtools
	make -j4
	make install
	rm -v ${INSTALL_PATH}/hcxtools-6.3.2.tar.gz
fi

echo -e "\n\033[0;32m[+]\033[0;33m Installing Responder\033[0m"
if [[ -n "$(ls ${INSTALL_PATH}/responder/)" ]]
then
	echo "responder is installed ..."
else
	cd ${INSTALL_PATH}
	apt -y install python3 python3-netifaces
	wget https://github.com/lgandx/Responder/archive/refs/tags/v3.1.4.0.tar.gz
	tar zxf v3.1.4.0.tar.gz
	mv -v ${INSTALL_PATH}/Responder-3.1.4.0 ${INSTALL_PATH}/responder
	cd ${INSTALL_PATH}/responder
	make -j4
	make install
	rm -v ${INSTALL_PATH}/v3.1.4.0.tar.gz
fi

echo -e "\n\033[0;32m[+]\033[0;33m Installing eaphammer\033[0m"
if [[ -n "$(ls ${INSTALL_PATH}/eaphammer/)" ]]
then
	echo "eaphammer is installed ..."
else
	cd ${INSTALL_PATH}
	git clone https://github.com/s0lst1c3/eaphammer.git
	cd eaphammer
	yes | ./raspbian-setup
	python3 -m venv venv
	venv/bin/pip install -r pip.req
	cp -v ${INSTALL_PATH}/eaphammer/eaphammer ${INSTALL_PATH}/eaphammer/eaphammer.bak
	sed -i "s#\#\!/usr/bin/env python3#\#\!${INSTALL_PATH}/eaphammer/venv/bin/python3#g" ${INSTALL_PATH}/eaphammer/eaphammer
	./eaphammer --cert-wizard
fi

mkdir -v ${INSTALL_PATH}/logs
cp -v ${MY_PATH}/files/*.sh ${INSTALL_PATH}
chmod +x ${INSTALL_PATH}/*.sh

echo -e "\n\033[0;32mPatataWiFi Ready!\033[0m"