# PatataWiFiEnterprise

PatataWiFi is a tool to perform WiFi attacks. The Enterprise version implements attacks to impersonate WPA Enterprise access points in order to obtain credentials from the clients of these networks.


Installation
----
The installation script installs
- macchanger
- dnsmaq
- aircrack-ng
- FreeRadius WPE 2.2
- Hostapd
- Hostapd-mana


Usage
----
Copy and personalize default scripts for hostapd and hostapd-mana.


Troubleshooting
----
`nl80211: Could not configure driver mode`

Stop wpa-supplicant before start hostapd.


Links
----
https://github.com/sensepost/hostapd-mana

https://github.com/brad-anton/freeradius-wpe

https://github.com/jesux/freeradius-wpe
