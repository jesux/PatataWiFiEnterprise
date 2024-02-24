#!/bin/bash

export SHELL=/bin/bash

MY_PATH="$(dirname "$0")"
MY_PATH="$(cd "${MY_PATH}" && pwd)"

# Internal RaspberryPi WiFi
${MY_PATH}/hostapd-psk.sh | tee -a ${MY_PATH}/logs/init.log

# External WiFi adapter
${MY_PATH}/hostapd-freeradius.sh | tee -a ${MY_PATH}/logs/init.log
#${MY_PATH}/hostapd-mana-freeradius.sh | tee -a ${MY_PATH}/logs/init.log