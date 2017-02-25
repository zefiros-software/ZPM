@echo off

rmdir /s /q "%USERPROFILE%/zpm-cache" 2>NUL
rmdir /s /q "%USERPROFILE%/zpm-install" 2>NUL

set root=%cd%

mkdir "%USERPROFILE%/zpm-install"
cd "%USERPROFILE%/zpm-install"

if exist "premake5.zip" del /q "premake5.zip"

if defined GH_TOKEN (
    powershell -command "Invoke-WebRequest -Uri https://github.com/premake/premake-core/releases/download/v5.0.0-alpha11/premake-5.0.0-alpha11-windows.zip -OutFile premake5.zip -Headers @{'Authorization'='token %GH_TOKEN%'}"
) else (
    powershell -command "Invoke-WebRequest -Uri https://github.com/premake/premake-core/releases/download/v5.0.0-alpha11/premake-5.0.0-alpha11-windows.zip -OutFile premake5.zip"
)
echo Finished downloading premake...

powershell -command "Expand-Archive premake5.zip -DestinationPath ."

git clone https://github.com/Zefiros-Software/ZPM.git ./zpm -b features/refactor

echo Finished cloning ZPM...

if defined GH_TOKEN (
    premake5.exe --github-token=%GH_TOKEN% --file=zpm/zpm.lua install-zpm
) else (
    premake5.exe --file=zpm/zpm.lua install-zpm
)

cd %root%

rmdir /s /q "%USERPROFILE%/zpm-install"

echo ZPM is installed, however a restart is required!

SET PATH=%PATH%;%USERPROFILE%\zpm\bin\