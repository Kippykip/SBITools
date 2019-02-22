@echo off
%~d0
cd "%~dp0"
sbitools -cue2ccd %1
pause
