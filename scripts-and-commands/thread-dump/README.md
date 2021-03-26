## Thread dump script

This shell script facilitate to get multiple thread dumps within a specified time period

###How to get ?

Taking 4 thread dumps in one minute interval for java process with pid 1234.
```
sh thread-analyze.sh 1234 4 1m
```

Available time units

- s for seconds (the default)
- m for minutes.
- h for hours.
- d for days.