@echo off
REM Lance PsyAvocat sur le telephone branche en USB, quel que soit le reseau Wi-Fi.
REM Le port 8080 du telephone est redirige vers Spring Boot sur le PC (adb reverse).
set ADB="C:\Users\kanou\AppData\Local\Microsoft\WinGet\Packages\Genymobile.scrcpy_Microsoft.Winget.Source_8wekyb3d8bbwe\scrcpy-win64-v5.0.1\adb.exe"
if exist "%LOCALAPPDATA%\Android\Sdk\platform-tools\adb.exe" set ADB="%LOCALAPPDATA%\Android\Sdk\platform-tools\adb.exe"

%ADB% reverse tcp:8080 tcp:8080
if errorlevel 1 (
  echo [ERREUR] Telephone non detecte en USB. Verifiez le cable et le debogage USB.
  exit /b 1
)
echo [OK] Port 8080 redirige vers le PC.
cd /d "%~dp0"
flutter run --dart-define=ip=localhost

