#!/bin/bash

# Check number of arguments
if [ "$#" -ne 3 ]; then
    echo "usage: sh thread-analyze.sh <pid> <number-of-dumps> <interval>[s|m|h|d]"
    exit 1
fi

count=$2
interval_input=$3

# Function to convert interval to seconds
convert_to_seconds() {
    local value=${1%[smhd]}
    local unit=${1: -1}

    case "$unit" in
        s) echo $value ;;
        m) echo $((value * 60)) ;;
        h) echo $((value * 3600)) ;;
        d) echo $((value * 86400)) ;;
        *) echo $value ;;  # Default to seconds if no unit is provided
    esac
}

for i in $(seq 1 $count); do
    jstack -l $1 > "thread_dump_$(date "+%F-%T").txt" &
    ps -p $1 -M > "thread_usage_$(date "+%F-%T").txt" &
    if [ $i -ne $count ]; then
        interval_seconds=$(convert_to_seconds $interval_input)
        echo "sleeping for $interval_input [$i]"
        sleep $interval_seconds
    fi
done
