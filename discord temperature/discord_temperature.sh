#!/bin/bash

# Monitor hard drive, CPU, and additional temperature sensor data, then send output to Discord webhook
WEBHOOK_URL="<put it here>"

# Updated list of HDDs, SSDs, and NVMe drives to monitor
HDD_DRIVES="/dev/sdl /dev/sdk /dev/sde /dev/sdm /dev/sdb /dev/sdn /dev/sdf /dev/sda /dev/sdd /dev/sdg"
SSD_DRIVES="/dev/sdh /dev/sdi /dev/sdj"
NVME_DRIVES="/dev/nvme1n1 /dev/nvme0n1"

# Initialize the message with a header
MESSAGE="**:thermometer: Server Drive and CPU Temperature Report**\n"

# Add CPU temperature data (including additional sensor data)
CPU_TEMP=$(sensors | grep -i 'Tctl' | awk '{print $2}')
TCCD3_TEMP=$(sensors | grep -i 'Tccd3' | awk '{print $2}')
TCCD5_TEMP=$(sensors | grep -i 'Tccd5' | awk '{print $2}')

MESSAGE+="\n**CPU and Additional Sensor Temperatures:**\n"
MESSAGE+="\`\`\`"
if [ -n "$CPU_TEMP" ]; then
    MESSAGE+="Tctl: ${CPU_TEMP}\n"
else
    MESSAGE+="Tctl Temperature data not available\n"
fi

if [ -n "$TCCD3_TEMP" ]; then
    MESSAGE+="Tccd3: ${TCCD3_TEMP}\n"
else
    MESSAGE+="Tccd3 Temperature data not available\n"
fi

if [ -n "$TCCD5_TEMP" ]; then
    MESSAGE+="Tccd5: ${TCCD5_TEMP}\n"
else
    MESSAGE+="Tccd5 Temperature data not available\n"
fi
MESSAGE+="\`\`\`"

# Add HDD temperatures
MESSAGE+="\n**HDD Temperatures:**\n"
MESSAGE+="\`\`\`"
for DRIVE in $HDD_DRIVES
do
    TEMP=$(sudo smartctl -A $DRIVE | grep "Current Drive Temperature" | awk '{print $4}')
    if [ -z "$TEMP" ]; then
        TEMP=$(sudo smartctl -A $DRIVE | grep -i "Temperature_Celsius" | awk '{print $10}')
    fi
    if [ -n "$TEMP" ]; then
        MESSAGE+="$DRIVE: ${TEMP}°C\n"
    else
        MESSAGE+="$DRIVE: Temperature data not available\n"
    fi
done
MESSAGE+="\`\`\`"

# Add SSD temperatures
MESSAGE+="\n**SSD Temperatures:**\n"
MESSAGE+="\`\`\`"
for DRIVE in $SSD_DRIVES
do
    TEMP=$(sudo smartctl -A $DRIVE | grep "Current Drive Temperature" | awk '{print $4}')
    if [ -z "$TEMP" ]; then
        TEMP=$(sudo smartctl -A $DRIVE | grep -i "Temperature_Celsius" | awk '{print $10}')
    fi
    if [ -n "$TEMP" ]; then
        MESSAGE+="$DRIVE: ${TEMP}°C\n"
    else
        MESSAGE+="$DRIVE: Temperature data not available\n"
    fi
done
MESSAGE+="\`\`\`"

# Add NVMe temperatures using the nvme command
MESSAGE+="\n**NVMe Temperatures:**\n"
MESSAGE+="\`\`\`"
for DRIVE in $NVME_DRIVES
do
    TEMP=$(sudo nvme smart-log $DRIVE | grep -i "temperature" | awk '{print $3}' | head -n 1)
    TEMP=$(echo $TEMP | sed 's/°C//g')
    if [ -n "$TEMP" ]; then
        MESSAGE+="$DRIVE: ${TEMP}°C\n"
    else
        MESSAGE+="$DRIVE: Temperature data not available\n"
    fi
done
MESSAGE+="\`\`\`"

# Send the message to Discord
curl -H "Content-Type: application/json" -X POST -d "{\"content\": \"$MESSAGE\"}" $WEBHOOK_URL