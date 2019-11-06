#!/bin/bash

MY_PATH="$(dirname "$0")"
MY_PATH="$(cd "${MY_PATH}" && pwd)"
INSTALL_PATH="/root/patatawifi"
mkdir -v "${INSTALL_PATH}"

apt update
apt -y install tmux libssl1.0-dev macchanger ethtool rfkill

echo "[+] Installing Dnsmasq"
cd ${INSTALL_PATH}
apt -y install dnsmasq
systemctl disable dnsmasq.service
systemctl stop dnsmasq
mkdir -v ${INSTALL_PATH}/dnsmasq
cp -v ${MY_PATH}/files/dnsmasq/* ${INSTALL_PATH}/dnsmasq/


echo "[+] Installing Aircrack-ng 1.2"
if [[ -n "$(which aircrack-ng)" && -n "$(aircrack-ng | grep '1\.2')" ]]
then
	echo "aircrack-ng is installed ..."
else
	cd ${INSTALL_PATH}
	apt -y install wireless-tools iw ethtool rfkill
	apt -y install autoconf automake libtool shtool pkg-config
	wget https://download.aircrack-ng.org/aircrack-ng-1.2.tar.gz
	tar zxf aircrack-ng-1.2.tar.gz
	cd aircrack-ng-1.2
	./autogen.sh
	make -j4
	make install
	airodump-ng-oui-update
	cd ${INSTALL_PATH}
	rm -v aircrack-ng-1.2.tar.gz
	rm -r aircrack-ng-1.2
fi


echo "[+] Installing FreeRadius WPE 2.2"
if [[ -n "$(which radiusd)" && -n "$(radiusd -v | grep 'FreeRADIUS-WPE Version 2.1.12')"  ]]
then
	echo "FreeRadius WPE 2.2 is installed ..."
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
	ldconfig -v
	cd ${INSTALL_PATH}
	rm -v freeradius-wpe.patch
	rm -v freeradius-server-2.1.12.tar.gz
	rm -r freeradius-server-2.1.12
fi
mkdir -vp ${INSTALL_PATH}/radiuscfg/default
cp -rv /usr/local/etc/raddb/* ${INSTALL_PATH}/radiuscfg/default
cp -rv ${MY_PATH}/files/radiuscfg/* ${INSTALL_PATH}/radiuscfg/default
sed "s#\[PATH\]#${INSTALL_PATH}#g" ${INSTALL_PATH}/radiuscfg/default/radiusd.conf.template > ${INSTALL_PATH}/radiuscfg/default/radiusd.conf
${INSTALL_PATH}/radiuscfg/default/certs/bootstrap
#radiusd -fX -d ${INSTALL_PATH}/radiuscfg/default #Generar certificado y Testing

echo "[+] Installing Hostapd 2.6"
if [[ -n "$(ls ${INSTALL_PATH}/hostapd/hostapd)" ]]
then
	echo "Hostapd 2.6 is installed ..."
else
	cd ${INSTALL_PATH}
	apt install -y libnl-3-dev libnl-genl-3-dev pkg-config
	wget https://w1.fi/releases/hostapd-2.6.tar.gz
	tar zxf hostapd-2.6.tar.gz
	cd hostapd-2.6/hostapd
	sed 's/#CONFIG_IEEE80211N=y/CONFIG_IEEE80211N=y/g; s/#CONFIG_LIBNL32=y/CONFIG_LIBNL32=y/' defconfig > .config
	make -j4
	cd ${INSTALL_PATH}
	mv -v hostapd-2.6/hostapd hostapd
	rm -r hostapd-2.6/
	rm -v hostapd-2.6.tar.gz
fi
cp -rv ${MY_PATH}/files/hostapd/* ${INSTALL_PATH}/hostapd/

echo "[+] Installing Hostapd Mana"
if [[ -n "$(ls ${INSTALL_PATH}/hostapd-mana/hostapd/hostapd)" ]]
then
	echo "Hostapd Mana is installed ..."
else
	cd ${INSTALL_PATH}
	apt install -y libnl-3-dev libnl-genl-3-dev
	#wget https://github.com/sensepost/hostapd-mana/archive/master.zip -O hostapd-mana.zip
	wget https://github.com/sensepost/hostapd-mana/archive/2.6.5.zip -O hostapd-mana.zip
	unzip hostapd-mana.zip
	mv -v hostapd-mana-master hostapd-mana
	cd hostapd-mana/hostapd
	make -j4
	cd ${INSTALL_PATH}
	rm -v hostapd-mana.zip
fi
cp -rv ${MY_PATH}/files/hostapd-mana/* ${INSTALL_PATH}/hostapd-mana/

mkdir -v ${INSTALL_PATH}/logs
cp -v ${MY_PATH}/files/*.sh ${INSTALL_PATH}
chmod +x ${INSTALL_PATH}/*.sh

echo "PatataWiFi Ready!"