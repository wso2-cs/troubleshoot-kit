#!/bin/bash
if [ "$#" -ne 3 ]; then
        echo "usage: sh thread-analyze.sh <pid> <number-of-dumps> <interval>"
        exit
fi

count=$2
for i in `seq 1 $count`;
do
        jstack -l $1 > thread_dump_`date "+%F-%T"`.txt &
        ps --pid $1 -Lo pid,tid,%cpu,time,nlwp,c > thread_usage_`date "+%F-%T"`.txt &
if [ $i -ne $count ]; then
        echo "sleeping for $3 [$i]"
        sleep $3
fi
done