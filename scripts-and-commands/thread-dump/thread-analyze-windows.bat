@echo off
REM Usage: thread-analyze-windows.bat <PID> <timeout-in-seconds> <number-of-iterations>

IF "%~3"=="" (
  echo Usage: %0 ^<PID^> ^<timeout-in-seconds^> ^<number-of-iterations^>
  exit /b 1
)

SET PID=%1
SET TIMEOUT_INTERVAL=%2
SET ITERATIONS=%3

FOR /L %%i IN (1,1,%ITERATIONS%) DO (

  
  REM Append the current date and time to the thread dump file
  jstack -l %PID% > thread-dump-%%i.txt
  if %%i lss %ITERATIONS% timeout /T %TIMEOUT_INTERVAL% /NOBREAK >nul
  echo sleeping for %TIMEOUT_INTERVAL% [%%i/%ITERATIONS%]
)

echo Done taking thread dumps.
