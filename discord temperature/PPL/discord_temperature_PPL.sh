#!/bin/bash

# Monitor hard drive, CPU, GPU, and additional temperature sensor data, then send output to Discord webhook
WEBHOOK_URL=""

# Updated list of HDDs, SSDs, and NVMe drives to monitor
HDD_DRIVES="/dev/sda /dev/sdb /dev/sdc /dev/sdd /dev/sde /dev/sdg /dev/sdj /dev/sdk /dev/sdl /dev/sdm"
SSD_DRIVES="/dev/sdf /dev/sdh /dev/sdi"
NVME_DRIVES="/dev/nvme1n1 /dev/nvme0n1"

# Initialize the message with a header
MESSAGE="**:thermometer: Server Drive, CPU and GPU Temperature Report**\n"

# Add CPU temperature data (including additional sensor data)
CPU_TEMP=$(sensors | grep -i 'Tctl' | awk '{print $2}')
TCCD3_TEMP=$(sensors | grep -i 'Tccd3' | awk '{print $2}')
TCCD5_TEMP=$(sensors | grep -i 'Tccd5' | awk '{print $2}')

MESSAGE+="\n**CPU and Additional Sensor Temperatures:**\n"
MESSAGE+="\`\`\`"
if [ -n "$CPU_TEMP" ]; then
    MESSAGE+="Tctl:  ${CPU_TEMP}\n"
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

# Add GPU information if NVIDIA GPUs are present
if command -v nvidia-smi &> /dev/null; then
    GPU_INFO=$(nvidia-smi --query-gpu=name,temperature.gpu,fan.speed,utilization.gpu,memory.used,memory.total,power.draw,power.limit --format=csv,noheader,nounits)
    DRIVER_VERSION=$(nvidia-smi --query-gpu=driver_version --format=csv,noheader,nounits | head -n 1)

    MESSAGE+="\n**🔧 NVIDIA GPU Status**\n"
    MESSAGE+="**Driver:** \`$DRIVER_VERSION\`\n\n"
    MESSAGE+="\`\`\`diff\n"

    i=0
    while IFS= read -r LINE; do
        IFS=',' read -r -a ARRAY <<< "$LINE"
        NAME=$(echo "${ARRAY[0]}" | xargs)
        TEMP=$(echo "${ARRAY[1]}" | xargs)
        FAN=$(echo "${ARRAY[2]}" | xargs)
        UTIL=$(echo "${ARRAY[3]}" | xargs)
        MEM_USED=$(echo "${ARRAY[4]}" | xargs)
        MEM_TOTAL=$(echo "${ARRAY[5]}" | xargs)
        POWER_DRAW=$(printf "%.2f" "${ARRAY[6]}")
        POWER_LIMIT=$(printf "%.2f" "${ARRAY[7]}")

        # Temperature color coding
        if [ "$TEMP" -lt 50 ]; then
            TEMP_COLOR="🟢"
        elif [ "$TEMP" -lt 70 ]; then
            TEMP_COLOR="🟡"
        else
            TEMP_COLOR="🔴"
        fi

        # Memory usage percentage
        MEM_PERCENT=$((100*MEM_USED/MEM_TOTAL))

        MESSAGE+="+ GPU $i: $NAME\n"
        MESSAGE+="  ${TEMP_COLOR} Temp: ${TEMP}°C | 🌬️ Fan: ${FAN}%\n"
        MESSAGE+="  ⚡ Load: ${UTIL}% | 🔋 Power: ${POWER_DRAW}W/${POWER_LIMIT}W\n"
        MESSAGE+="  💾 Memory: ${MEM_USED}MB/${MEM_TOTAL}MB (${MEM_PERCENT}%)\n\n"
        ((i++))
    done <<< "$GPU_INFO"

    MESSAGE+="\`\`\`"
fi

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

# Add timestamp
MESSAGE+="\n📊 *Last updated: $(date '+%Y-%m-%d %H:%M:%S')*"

# Send the message to Discord
curl -H "Content-Type: application/json" -X POST -d "{\"content\": \"$MESSAGE\"}" $WEBHOOK_URL