# Thread usage and dump analyzing script

This shell script will sort the native OS threads by the CPU percentage and map them with the corresponding java thread. 
This script will help to debug java high CPU issues. it provides the java thread names and the thread states which are 
consuming the high percentage of the server CPU. 

## How to analyze ?

copy the script [thread-usage-analyzer.sh](thread-usage-analyzer.sh) to the same directory which contains the thread usage and thread dumps that has been collected using the
[Script to get thread dumps](../../scripts-and-commands/thread-dump/).

## Instruction to run


```sh ThreadDumpUsageAnalyzer.sh <PID> <RESULTCOUNT>```
  
Available parameters

- PID for java process ID
- RESULTCOUNT for limiting the result sets in the out-put 

## Sample output
```
 sh thread-usage-analyzer.sh 28969 5
 
 *****  START ***** 
thread_usage_2021-05-24-10:17:45.txt ./thread_dump_2021-05-24-10:17:45.txt
  PID   TID %CPU     TIME NLWP  C | JAVAThread 
28969 28975  0.9 00:00:01  233  0 | "VM Thread" os_prio=0 tid=0x00007fb7f4096800 nid=0x712f runnable 
28969 28991  3.0 00:00:03  233  3 | "Start Level Event Dispatcher" #17 daemon prio=5 os_prio=0 tid=0x00007fb7f4560800 nid=0x713f in Object.wait() [0x00007fb7dd8c7000]
28969 28981  5.8 00:00:06  233  5 | "C1 CompilerThread2" #7 daemon prio=9 os_prio=0 tid=0x00007fb7f40dc800 nid=0x7135 waiting on condition [0x0000000000000000]
28969 28980 18.0 00:00:19  233 18 | "C2 CompilerThread1" #6 daemon prio=9 os_prio=0 tid=0x00007fb7f40db000 nid=0x7134 waiting on condition [0x0000000000000000]
28969 28979 19.3 00:00:21  233 19 | "C2 CompilerThread0" #5 daemon prio=9 os_prio=0 tid=0x00007fb7f40d8000 nid=0x7133 waiting on condition [0x0000000000000000]
*****  END ***** 

thread_usage_2021-05-24-10:17:47.txt ./thread_dump_2021-05-24-10:17:47.txt
  PID   TID %CPU     TIME NLWP  C | JAVAThread 
28969 28975  1.0 00:00:01  234  1 | "VM Thread" os_prio=0 tid=0x00007fb7f4096800 nid=0x712f runnable 
28969 28991  3.0 00:00:03  234  3 | "Start Level Event Dispatcher" #17 daemon prio=5 os_prio=0 tid=0x00007fb7f4560800 nid=0x713f in Object.wait() [0x00007fb7dd8c7000]
28969 28981  5.7 00:00:06  234  5 | "C1 CompilerThread2" #7 daemon prio=9 os_prio=0 tid=0x00007fb7f40dc800 nid=0x7135 waiting on condition [0x0000000000000000]
28969 28980 17.6 00:00:19  234 17 | "C2 CompilerThread1" #6 daemon prio=9 os_prio=0 tid=0x00007fb7f40db000 nid=0x7134 waiting on condition [0x0000000000000000]
28969 28979 19.0 00:00:21  234 19 | "C2 CompilerThread0" #5 daemon prio=9 os_prio=0 tid=0x00007fb7f40d8000 nid=0x7133 waiting on condition [0x0000000000000000]
*****  END ***** 

```
