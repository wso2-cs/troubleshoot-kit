REM The following batch script generates 6 thread dumps at a preset interval of 20 secs
REM script can be executed as
REM thread-analyze-windows.bat 2120
REM where 2120 is the java process id

for /L %%i in (1,1,4) do (
  echo Taking Thread Dump %i
  jstack -l %1 > thread-dump-%%i.txt

   timeout 60
)
