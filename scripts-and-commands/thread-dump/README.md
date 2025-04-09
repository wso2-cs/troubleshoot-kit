## Thread dump script

This shell script facilitate to get multiple thread dumps within a specified time period

### How to get ?

Taking 4 thread dumps with one minute delay for java process with pid 1234.
```
sh thread-analyze.sh 1234 4 1m
```

Available time units

- s for seconds (the default)
- m for minutes.
- h for hours.
- d for days.

## Thread dump script for windows

This script facilitates to get multiple thread dumps within a specified time period

### How to get ?

Taking 4 thread dumps with one minute delay for java process with pid 1234.
```
thread-analyze-windows.bat 1234 60 4
```

## Thread dump script for Mac

This script is designed for a Mac system.

### How to get ?

Execute the script using below command
```
sh thread-analyze-mac.sh <PID> <number-of-dumps> <interval>[s|m|h|d]
```

### Note
In case of any error, you will need to execute the below command. This part of the command allows you to run the script as the specified user.
```
sudo -u <user> sh thread-analyze-mac.sh <PID> <number-of-dumps> <interval>[s|m|h|d]
```
