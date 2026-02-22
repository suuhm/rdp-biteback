@echo off

REM start_RDP_BITEBACK.bat
REM ----------------------
REM
echo "Running RDP-Biteback patcher..."
echo\
REM cd "C:\Users\"
Powershell.exe -executionpolicy remotesigned -File .\rdp-biteback.ps1
REM exit
pause
