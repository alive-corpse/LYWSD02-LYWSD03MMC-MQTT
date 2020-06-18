# LYWSD02/LYWSD03MMC to MQTT

## What is it?

It's simple script for getting values of temperature, humidity and battary level from Xiaomi LYWSD03MMC and LYWSD02 sensors and sending them to the MQTT topics.

## Why it was made?

* I dislike heavy dependencies and this script make me able to run it on my routers with OpenWRT, cause router is situated closer to the most of sensors than other devices
* I made it as practice in working with BLE devices with gatttool
* Building bluepy takes a lot of dependencies like as build-essentials, python3-dev and so on.

## How it works?

After you run script and pass list of mac addresses to it, script will make this actions for each of addresses from list:
1. Try to detect if device is exists and available
2. Trying to get UUID of handle that leads to temperature and humidity data
3. Compare this handle shifting with hardcoded from constants
4. If handle shifts are equal with one of them scripts print what device is it (LYWSD03MMC or LYWSD02)
5. For each version of devices it has number of handles to operate with, so it tried to get battery level data with one of handles, decode it, print it and send it to mqtt topic
6. With another handle it makes request to subscribe for notifications
7. It waiting of message from device with temperature and humidity data, decode it, print it and send it to mqtt topic

## Dependencies

Obliviously, you shoud have bluetooth adapter supported by you operating system. Also you need to install this packets (example for debian-based operating systems):
```
sudo apt-get install bluez-tools mosquitto-clients
```

## Installation
```
wget https://github.com/alive-corpse/LYWSD02-LYWSD03MMC-MQTT/archive/master.zip
unzip master.zip
cd LYWSD02-LYWSD03MMC-MQTT-master/
```
Then edit mqtt.conf file to fill it up with your MQTT credentials. Do not use spaces between equal sign and values/parameters names.

## Finding mac addresses of devices

Run this
```
sudo hcitool lescan
```
to catch mac addresses of devices with names starts with _LYWSD_. You can't just grep output cause *hchitool lecan* does not flash stdout buffer during work. Lines can be duplicated, collect and save uniq mac addresses of devices for using with script.

## Running

You can run it manually for test like 
```
./lyw.sh AA:AA:AA:AA:AA:AA BB:BB:BB:BB:BB:BB
``` 
Where AA:AA:AA:AA:AA:AA and BB:BB:BB:BB:BB:BB are mac addresses of your LYSD02 and LYSD03MMC devices. You can append so much addresses as you have collected.

### Output
```
# ./lyw.sh AA:AA:AA:AA:AA:AA BB:BB:BB:BB:BB:BB
============ 2020-06-18 02:53:50 =============
DEVICE FOUND: LYWSD03MMC (AA:AA:AA:AA:AA:AA)
Battery: 99
Temp: 25.63
Hum: 59
============ 2020-06-18 02:54:05 =============
DEVICE FOUND: LYWSD02 (BB:BB:BB:BB:BB:BB)
Battery: 49
Temp: 26.39
Hum: 56
```
### MQTT topics 
```
/LYWSD03MMC/AA:AA:AA:AA:AA:AA/battery 99
/LYWSD03MMC/AA:AA:AA:AA:AA:AA/temp 25.46
/LYWSD03MMC/AA:AA:AA:AA:AA:AA/hum 58
/LYWSD02/BB:BB:BB:BB:BB:BB/battery 49
/LYWSD02/BB:BB:BB:BB:BB:BB/temp 26.31
/LYWSD02/BB:BB:BB:BB:BB:BB/hum 55
```

## Appending cron job
You can add this script to the crontab by running
```
crontab -e
```
under user that have permissions for working with bluetooth. My version looks like this
```
*/2 * * * * timeout 59 /opt/ble/lyw.sh A4:C1:38:0C:3D:B3 E7:2E:01:11:A0:2F > /dev/null 2>&1
```
I'm also recommend to use timeout limit for pervent of stucking script work with low bt signal level.
