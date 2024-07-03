#!/bin/bash

# Function to get the number of GPUs
get_gpu_count() {
    nvidia-smi -L | wc -l
}

# Function to get GPU temperature
get_gpu_temp() {
    local gpu_id=$1
    nvidia-smi --query-gpu=temperature.gpu --format=csv,noheader,nounits -i $gpu_id
}

# Function to set GPU fan speed
set_gpu_fan_speed() {
    local gpu_id=$1
    local speed=$2
    nvidia-settings -a "[gpu:$gpu_id]/GPUFanControlState=1" -a "[fan:$gpu_id]/GPUTargetFanSpeed=$speed"
}

# Function to calculate fan speed based on temperature
calculate_fan_speed() {
    local temp=$1
    local speed=30

    if [ "$temp" -ge 75 ]; then
        speed=100
    elif [ "$temp" -gt 40 ]; then
        speed=$((30 + (temp - 40) * (100 - 30) / (75 - 40)))
    fi

    echo $speed
}

# Adjust fan speed based on temperature
adjust_fan_speed() {
    local gpu_id=$1
    local temp=$(get_gpu_temp $gpu_id)
    local speed=$(calculate_fan_speed $temp)

    set_gpu_fan_speed $gpu_id $speed

    echo "GPU $gpu_id: Temp=$temp, Fan Speed=$speed" >> /tmp/gpu-fan-speed.log
}

# Main loop
while true; do
    gpu_count=$(get_gpu_count)
    for (( gpu_id=0; gpu_id<gpu_count; gpu_id++ ))
    do
        adjust_fan_speed $gpu_id
    done
    sleep 5
done

