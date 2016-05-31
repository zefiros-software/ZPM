@echo off

rmdir /s /q "%TEMP%/zpm_cache"
rmdir /s /q "%TEMP%/zpm-install"

mkdir "%TEMP%/zpm-install"
cd "%TEMP%/zpm-install"

if exist "premake5.zip" del /q "premake5.zip"

powershell -command "Invoke-WebRequest -Uri https://github.com/premake/premake-core/releases/download/v5.0.0-alpha8/premake-5.0.0-alpha8-windows.zip -OutFile premake5.zip"
powershell -command Add-Type -AssemblyName System.IO.Compression.FileSystem ^

[System.IO.Compression.ZipFile]::ExtractToDirectory('premake5.zip', '.')"

git clone https://zefiros.eu/stash/scm/zpm/zpm.git
premake5.exe --file=zpm/zpm.lua install-zpm

rmdir /s /q "%TEMP%/zpm-install"

echo ZPM is installed, however a restart is required!