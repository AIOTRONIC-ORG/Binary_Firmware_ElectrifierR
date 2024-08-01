@echo off
setlocal enabledelayedexpansion

:: Define versions and tools
set "python_version=3.12.4"
set "python_installer=python-%python_version%-amd64.exe"
set "tool=esptool"

:: Function to check if Python is installed
:check_python
python --version >nul 2>&1
if %errorlevel% neq 0 (
    echo Python is not installed. Installing Python %python_version%...
    powershell -Command "Invoke-WebRequest -Uri https://www.python.org/ftp/python/%python_version%/%python_installer% -OutFile %python_installer%"
    start /wait "" "%python_installer%" /quiet InstallAllUsers=1 PrependPath=1
    del %python_installer%
) else (
    echo Python is already installed.
)

echo Downloading Latest Firmware
powershell -Command "Invoke-WebRequest -Uri https://github.com/AIOTRONIC-ORG/Binary_Firmware_ElectrifierR/raw/master/bootloader.bin -OutFile bootloader.bin"
powershell -Command "Invoke-WebRequest -Uri https://github.com/AIOTRONIC-ORG/Binary_Firmware_ElectrifierR/raw/master/partitions.bin -OutFile partitions.bin"
powershell -Command "Invoke-WebRequest -Uri https://github.com/AIOTRONIC-ORG/Binary_Firmware_ElectrifierR/raw/master/firmware.bin -OutFile firmware.bin"
@REM powershell -Command "Invoke-WebRequest -Uri https://github.com/AIOTRONIC-ORG/Binary_Firmware_ElectrifierR/blob/esp32s3/bootloader.bin -OutFile bootloader.bin"
@REM powershell -Command "Invoke-WebRequest -Uri https://github.com/AIOTRONIC-ORG/Binary_Firmware_ElectrifierR/blob/esp32s3/partitions.bin -OutFile partitions.bin"
@REM powershell -Command "Invoke-WebRequest -Uri https://github.com/AIOTRONIC-ORG/Binary_Firmware_ElectrifierR/blob/esp32s3/firmware.bin -OutFile firmware.bin"

:: Function to check if esptool is installed
:check_esptool
python -m pip show %tool% >nul 2>&1
if %errorlevel% neq 0 (
    echo The tool %tool% is not installed. Installing %tool%...
    python -m pip install %tool%
) else (
    echo The tool %tool% is already installed.
)

:: Update esptool path
for /f "tokens=*" %%i in ('where python') do set python_path=%%i
set path=!python_path!\..\Scripts;!path!

:: Main Menu
:menu
cls
echo ==============================================
echo             ESP32 Tools Menu
echo ==============================================
echo 1. Flash
echo 2. Update Firmware
echo 3. Exit
echo ==============================================
set /p choice="Select an option: "

if "%choice%"=="1" goto flash
if "%choice%"=="2" goto update_firmware
if "%choice%"=="3" exit

:: If the option is invalid, return to menu
goto menu

:: Option 1: Flash
:flash
cls
setlocal enabledelayedexpansion

REM Prompt the user for the port
set /p port="PORT (e.g., COM3): "

REM Try running the command with Python
python -m esptool --chip esp32c3 --port COM%port% erase_flash
if %errorlevel% neq 0 (
    echo Error: Failed to run the command with Python.
)

pause
goto menu

:: Option 2: Update Firmware
:update_firmware
@REM cls
setlocal enabledelayedexpansion

REM Prompt the user for the port
set /p port="PORT (e.g., COM3): "

REM Try running the command with Python
python -m esptool -p COM%port% -b 460800 --before default_reset --after hard_reset --chip esp32c3 write_flash --flash_mode dio --flash_size detect --flash_freq 40m 0x1000 bootloader.bin 0x8000 partitions.bin 0x10000 firmware.bin
if %errorlevel% neq 0 (
    echo Error: Failed to run the command with Python.
)

pause
goto menu
