#!/bin/bash

# Discord Webhook URL
WEBHOOK_URL=""

# Get comprehensive NVIDIA SMI information
GPU_INFO=$(nvidia-smi --query-gpu=name,temperature.gpu,fan.speed,utilization.gpu,memory.used,memory.total,power.draw,power.limit --format=csv,noheader,nounits)
DRIVER_VERSION=$(nvidia-smi --query-gpu=driver_version --format=csv,noheader,nounits | head -n 1)

# Format the message with rich formatting
MESSAGE_CONTENT="**🔧 NVIDIA GPU Status**\n"
MESSAGE_CONTENT+="**Driver:** \`$DRIVER_VERSION\`\n\n"
MESSAGE_CONTENT+="\`\`\`diff\n"

# Add each GPU's info with color coding
i=0
while IFS= read -r LINE; do
    # Split the line into parts
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

    MESSAGE_CONTENT+="+ GPU $i: $NAME\n"
    MESSAGE_CONTENT+="  ${TEMP_COLOR} Temp: ${TEMP}°C | 🌬️ Fan: ${FAN}%\n"
    MESSAGE_CONTENT+="  ⚡ Load: ${UTIL}% | 🔋 Power: ${POWER_DRAW}W/${POWER_LIMIT}W\n"
    MESSAGE_CONTENT+="  💾 Memory: ${MEM_USED}MB/${MEM_TOTAL}MB (${MEM_PERCENT}%)\n\n"
    ((i++))
done <<< "$GPU_INFO"

MESSAGE_CONTENT+="\`\`\`"
MESSAGE_CONTENT+="\n📊 *Last updated: $(date '+%Y-%m-%d %H:%M:%S')*"

# Send to Discord with error handling
if ! curl -H "Content-Type: application/json" \
     -X POST \
     -d "{\"content\": \"$MESSAGE_CONTENT\"}" \
     "$WEBHOOK_URL" >/dev/null 2>&1; then
    echo "Failed to send to Discord webhook"
    exit 1
fi