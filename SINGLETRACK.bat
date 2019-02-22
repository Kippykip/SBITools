@echo off
%~d0
cd "%~dp0"
sbitools -singletrack %1
pause
