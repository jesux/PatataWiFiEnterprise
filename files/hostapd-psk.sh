#!/bin/bash

MY_PATH="$(dirname "$0")"
MY_PATH="$(cd "${MY_PATH}" && pwd)"

iwconfig=/sbin/iwconfig
ifconfig=/sbin/ifconfig
macchanger=/usr/bin/macchanger
dnsmasq=/usr/sbin/dnsmasq

SESSION='PatataWifi_Hostapd_PSK'

wlan_list=("wlan_rpi")
#wlan_list=("wlan0" "wlan1")
mac='4c:77:6d:9e:00:00' # Change me, must end in 0 to use virtual interfaces
channel=6

# WPA-PSK Main network
main_ssid='PatataWiFi'
main_password='patatas333'
main_ip=172.16.0.1
main_netmask=255.255.255.0

# WPA-PSK Virtual networks
# Comment to disable
# Check AP capabilities of your wlan interface, max virutal AP: iw list | grep -A 2 'valid interface combinations'
#ssid_list=("WiFi" "🍟")
#wlan_ip_list=("10.0.0.1" "10.0.1.1")
#password_list=("patatas444" "patatas555")

hostapdconf="${SESSION}.conf"
dnsmasqconf="${SESSION}.conf"
logdir="${MY_PATH}/logs/${SESSION}"

echo -e "\033[0;32m\033[0;33m[PatataWiFi: Hostapd PSK]\033[0m"

# CHECK IF TMUX SESSION IS ACTIVE
if [[ -n "$(tmux list-sessions -F \"#{session_name}\" 2>/dev/null | grep \"${SESSION}\")" ]] then
  echo -e "\033[0;31mAlready running\033[0m"
  echo "tmux attach -t ${SESSION}"
  exit
fi

# Wait for wlan interface
for wlan_ap in "${wlan_list[@]}"; do
    c=0
    echo -en "\033[0;35m ${wlan_ap}\033[0m "
    while [ -z "${wlan_ap_active}" ]; do
      ((c++)) && ((c>5)) && echo -e "\033[0;31m not found\033[0m" && break
      echo -n "."
      sleep 1
      wlan_ap_active=$(${iwconfig} ${wlan_ap} 2>/dev/null)
    done
    if [ -n "${wlan_ap_active}" ]; then
        echo -e "\033[0;32m OK\033[0m"
        break
    fi
done

if [ -z "${wlan_ap_active}" ]; then
    echo -e "\033[0;31m Failed, wlan interfaces not found\033[0m"
    exit
fi

# create log directory
mkdir -p -v ${logdir}
rm ${MY_PATH}/logs/current
ln -s ${logdir} ${MY_PATH}/logs/current

echo -e "\n\033[0;32m[+]\033[0;33m MAC change\033[0m"
${ifconfig} ${wlan_ap} down
sleep 1
${macchanger} -m ${mac} ${wlan_ap}
sleep 1

# HOSTAPD CONFIG
echo -e "\n\033[0;32m[+]\033[0;33m HOSTAPD CONFIG\033[0m"
sed "s/\[INTERFACE\]/${wlan_ap}/; s/\[SSID\]/${main_ssid}/; s/\[PASSWORD\]/${main_password}/; s/\[CHANNEL\]/${channel}/;" ${MY_PATH}/hostapd/patatawifi-psk.conf > ${MY_PATH}/hostapd/${hostapdconf}

# DNSMASQ CONFIG
sed "s#\[PATH\]#${MY_PATH}#g" ${MY_PATH}/dnsmasq/PatataWiFi_template.conf > ${MY_PATH}/dnsmasq/${dnsmasqconf}
dnsmasq_ip=${main_ip}
echo "dhcp-range=interface:${wlan_ap},${main_ip}0,${main_ip}00,12h" >> ${MY_PATH}/dnsmasq/${dnsmasqconf}

# Multiple SSID
for ((i = 0; i < ${#ssid_list[@]}; i++))
do
    echo -e "\033[0;35m * ${ssid_list[$i]} \033[0;33m[${wlan_ip_list[$i]}]\033[0m"
    sed "s/\[VIRTUALINTERFACE\]/${wlan_ap}_$((i+1))/; s/\[SSID\]/${ssid_list[$i]}/; s/\[PASSWORD\]/${password_list[$i]}/;" ${MY_PATH}/hostapd/patatawifi-psk-virtual.conf >> ${MY_PATH}/hostapd/${hostapdconf}

    network=$(echo "${wlan_ip_list[$i]}" | cut -d '.' -f 1,2,3)
    echo "dhcp-range=interface:${wlan_ap}_$((i+1)),${network}.10,${network}.200,12h" >> ${MY_PATH}/dnsmasq/${dnsmasqconf}
    dnsmasq_ip="${dnsmasq_ip},${wlan_ip_list[$i]}"
done

echo "listen-address=${dnsmasq_ip}" >> ${MY_PATH}/dnsmasq/${dnsmasqconf}

# IP Forward - Internet
#echo 1 > /proc/sys/net/ipv4/ip_forward
#sysctl -w net.ipv4.ip_forward=1
#iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
#TODO: Block access to LAN address (192.168.0.0/16, 10.0.0.0/8, 172.16.0.0/12)

# TMUX
tmux -2 new-session -d -s $SESSION
tmux split-window -h

tmux select-pane -t 0
tmux send-keys "cd ${MY_PATH}/hostapd/" C-m
tmux send-keys "./hostapd ${hostapdconf}" C-m

# Wait for virtual wlan interfaces
for ((i = 0; i < ${#ssid_list[@]}; i++)); do
    c=0
    virtualwlan_active=$(${iwconfig} ${wlan_ap}_$((i+1)) 2>/dev/null)
    echo -en "\033[0;35m ${wlan_ap}_$((i+1))\033[0m "
    while [ -z "${virtualwlan_active}" ]; do
      ((c++)) && ((c>20)) && echo -e "\033[0;31m not found\033[0m" && exit
      echo -n "."
      sleep 1
      virtualwlan_active=$(${iwconfig} ${wlan_ap}_$((i+1)) 2>/dev/null)
    done
    if [ -n "${virtualwlan_active}" ]; then
        echo -e "\033[0;32m OK\033[0m"
    fi
done

echo -e "\n\033[0;32m[+]\033[0;33m Setting IP  ${main_ip}  ${main_netmask}\033[0m"
${ifconfig} ${wlan_ap} ${main_ip} netmask ${main_netmask}
for ((i = 0; i < ${#wlan_ip_list[@]}; i++)); do
  ${ifconfig} ${wlan_ap}_$((i+1)) ${wlan_ip_list[$i]} netmask 255.255.255.0
done

tmux select-pane -t 1
tmux send-keys "${dnsmasq} -d -C ${MY_PATH}/dnsmasq/${dnsmasqconf}" C-m

echo "Finished!"
echo "tmux attach -t ${SESSION}"
exit 0
