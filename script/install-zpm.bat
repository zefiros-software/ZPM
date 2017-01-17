@echo off

rmdir /s /q "%TEMP%/zpm-cache"
rmdir /s /q "%TEMP%/zpm-install"

mkdir "%TEMP%/zpm-install"
cd "%TEMP%/zpm-install"

if exist "premake5.zip" del /q "premake5.zip"

if defined GH_TOKEN (
    powershell -command "Invoke-WebRequest -Uri https://github.com/premake/premake-core/releases/download/v5.0.0-alpha11/premake-5.0.0-alpha11-windows.zip -OutFile premake5.zip -Headers @{'Authorization'='token %GH_TOKEN%'}"
) else (
    powershell -command "Invoke-WebRequest -Uri https://github.com/premake/premake-core/releases/download/v5.0.0-alpha11/premake-5.0.0-alpha11-windows.zip -OutFile premake5.zip"
)
dir
echo Finished downloading premake...

powershell -command Add-Type -AssemblyName System.IO.Compression.FileSystem ^

[System.IO.Compression.ZipFile]::ExtractToDirectory('premake5.zip', '.')"

git clone https://github.com/Zefiros-Software/ZPM.git ./zpm

echo Finished cloning ZPM...

if defined GH_TOKEN (
    .\premake5.exe --github-token=%GH_TOKEN% --file=zpm/zpm.lua install-zpm;
) else (
    .\premake5.exr --file=zpm/zpm.lua install-zpm;
)

rmdir /s /q "%TEMP%/zpm-install"

echo ZPM is installed, however a restart is required!

if defined APPVEYOR (
    @powershell -NoProfile -ExecutionPolicy Bypass -Command "iex ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))" && SET "PATH=%PATH%;%ALLUSERSPROFILE%\chocolatey\bin"
    choco install git.install
) 