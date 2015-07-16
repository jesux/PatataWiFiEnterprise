#!/bin/bash

MY_PATH="$(dirname "$0")"
MY_PATH="$(cd "${MY_PATH}" && pwd)"

${MY_PATH}/default.sh | tee -a ${MY_PATH}/logs/init.log
#${MY_PATH}/default-mana.sh | tee -a ${MY_PATH}/logs/init.log