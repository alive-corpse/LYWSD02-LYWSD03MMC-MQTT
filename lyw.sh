#!/bin/sh
cd `dirname "$0"`

devices='LYWSD03MMC 0x001b 0x0038 0x0036
LYWSD02 0x0052 0x004c 0x004b'

! [ -f mqtt.conf ] && echo "Fail to find mqtt.conf file" && exit 1
. ./mqtt.conf
mqtt="mosquitto_pub -h $host -p $port"
[ -n "$user$pass" ] && mqtt="$mqtt -u $user -P $pass"
[ -n "$topicpref" ] && mqtt="$mqtt -t $topicpref" || mqtt="$mqtt -t "

for mac in $*; do
    echo "============ $(date +'%F %T') ============="
    if handle=`gatttool -b "$mac" --characteristics | sed '/ebe0ccc1/!d;s/^.*char value handle = //;s/, .*//'` 2>/dev/null; then
        if [ -z "$handle" ]; then
            echo "Device with mac $mac doesn't have needed handle or connection is failed, skipping"
        else
            device="$(echo "$devices" | sed '/ '"$handle"'$/!d')"
            if [ -n "$device" ]; then
                echo "DEVICE FOUND: ${device%% *} ($mac)"
                mqttc="$mqtt/${device%% *}/$mac"
                chkhnd="${device##* }"
                nothnd=`echo "$device" | cut -d " " -f 3`
                battery=`echo "$mac $device" | awk '{print "gatttool -b "$1" --char-read -a "$3}' | sh | awk '{ print "ibase=16; "toupper($NF) }' | bc`
                echo "Battery: $battery"
                $mqttc/battery -m "$battery"
                gatttool -b "$mac" --char-write-req --handle="$nothnd" --value 0100 --listen |
                    while IFS= read -r line; do
                        res=`echo "$line" | awk '{
                            if ($0~/Notification handle = '"$chkhnd"' value/) {print "ibase=16; "toupper($7$6)"\nibase=16; "toupper($8)}
                        }' | bc`
                        if [ -n "$res" ]; then
                            temphum=`echo $res | awk '{print "echo Temp: "$1/100"\necho Hum: "$2"\n'"$mqttc"'/temp -m "$1/100"\n'"$mqttc"'/hum -m "$2}'`
                            echo "$temphum" | sh
                            exit 0
                        fi
                    done
            else
                echo "Device with mac $mac does not supported, skipping"
            fi
        fi
     else
         echo "Fail to connect to device with mac $mac"
     fi
done

