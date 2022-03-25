## Thread dump script

This shell script facilitate to get multiple thread dumps within a specified time period

### How to get ?

Taking 4 thread dumps in one minute interval for java process with pid 1234.
```
sh thread-analyze.sh 1234 4 1m
```

Available time units

- s for seconds (the default)
- m for minutes.
- h for hours.
- d for days.
- 
## Thread dump script for windows

You can use this windows script thread-analyze-windows.bat to get 4 thread dumps with one minute (60 seconds ) interval.

### How to get ?

Execute the script using below command
```
thread-analyze-windows.bat <PID>
```

