@echo off

rmdir /s /q "%USERPROFILE%/zpm-install" 2>NUL

set root=%cd%

mkdir "%USERPROFILE%/zpm-install"
cd "%USERPROFILE%/zpm-install"

if exist "premake5.zip" del /q "premake5.zip"

if defined GH_TOKEN (
    powershell -command "[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; Invoke-WebRequest -Uri https://github.com/Zefiros-Software/premake-core/releases/download/v5.0.0-zpm-alpha12.2-dev/premake-windows.zip -OutFile premake5.zip -Headers @{'Authorization'='token %GH_TOKEN%'}"
) else (
    powershell -command "[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; Invoke-WebRequest -Uri https://github.com/Zefiros-Software/premake-core/releases/download/v5.0.0-zpm-alpha12.2-dev/premake-windows.zip -OutFile premake5.zip"
)
echo Finished downloading premake...

powershell -command "Expand-Archive premake5.zip -DestinationPath ."

git clone https://github.com/Zefiros-Software/ZPM.git ./zpm --depth 1 --quiet -b master
echo Finished cloning ZPM...

if defined GH_TOKEN (
    premake5.exe --github-token=%GH_TOKEN% --file=zpm/zpm.lua install zpm
) else (
    premake5.exe --file=zpm/zpm.lua install zpm
)

cd %root%

rmdir /s /q "%USERPROFILE%/zpm-install"

echo ZPM is installed, however a restart is required!

SET PATH=%PATH%;%USERPROFILE%\zpm\bin\
