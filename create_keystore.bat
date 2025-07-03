@echo off
echo ===============================================
echo      MoneyTrail Keystore Creator
echo ===============================================
echo.
echo This will create a keystore file to sign your app for Play Store.
echo.

REM Try to find Java installation
set JAVA_PATH=
set KEYTOOL_PATH=

REM Check if java is in PATH
java -version >nul 2>&1
if not errorlevel 1 (
    set JAVA_PATH=java
    set KEYTOOL_PATH=keytool
    goto :java_found
)

echo Java not found in PATH. Searching in common locations...

REM Check user's specific Java installation
if exist "C:\Program Files\Java\jre1.8.0_451\bin\keytool.exe" (
    set KEYTOOL_PATH=C:\Program Files\Java\jre1.8.0_451\bin\keytool.exe
    goto :java_found
)

REM Check other Java versions in Program Files
for /d %%i in ("%PROGRAMFILES%\Java\*") do (
    if exist "%%i\bin\keytool.exe" (
        set KEYTOOL_PATH=%%i\bin\keytool.exe
        goto :java_found
    )
)

REM Check Android Studio Java locations
for /d %%i in ("%LOCALAPPDATA%\Android\Sdk\*") do (
    if exist "%%i\bin\java.exe" (
        set JAVA_PATH=%%i\bin\java.exe
        set KEYTOOL_PATH=%%i\bin\keytool.exe
        goto :java_found
    )
)

REM Check Program Files Android Studio
for /d %%i in ("%PROGRAMFILES%\Android\Android Studio\jbr\*") do (
    if exist "%%i\bin\java.exe" (
        set JAVA_PATH=%%i\bin\java.exe
        set KEYTOOL_PATH=%%i\bin\keytool.exe
        goto :java_found
    )
)

REM Check embedded JDK in Android Studio
if exist "%PROGRAMFILES%\Android\Android Studio\jbr\bin\keytool.exe" (
    set KEYTOOL_PATH=%PROGRAMFILES%\Android\Android Studio\jbr\bin\keytool.exe
    goto :java_found
)

REM Check user profile Android Studio
if exist "%USERPROFILE%\AppData\Local\Android\Sdk\build-tools" (
    for /d %%i in ("%USERPROFILE%\AppData\Local\Android\Sdk\build-tools\*") do (
        if exist "%%i\lib\dx.jar" (
            REM Android SDK found, try to find bundled Java
            if exist "%PROGRAMFILES%\Android\Android Studio\jbr\bin\keytool.exe" (
                set KEYTOOL_PATH=%PROGRAMFILES%\Android\Android Studio\jbr\bin\keytool.exe
                goto :java_found
            )
        )
    )
)

echo ERROR: Java/Keytool not found!
echo.
echo SOLUTIONS:
echo 1. Open Android Studio Terminal and run: keytool -genkey -v -keystore money-trail-key.jks -keyalg RSA -keysize 2048 -validity 10000 -alias money-trail-key
echo 2. Or install Java JDK manually
echo 3. Or add Android Studio's Java to your PATH
echo.
pause
exit /b 1

:java_found
echo Found Java/Keytool at: %KEYTOOL_PATH%

echo IMPORTANT INFORMATION:
echo - Keep this keystore file SAFE - you'll need it for all future updates
echo - Remember your passwords - you cannot recover them
echo - Store keystore in a secure location (backup recommended)
echo.

set /p APP_NAME="Enter your app name (MoneyTrail): "
if "%APP_NAME%"=="" set APP_NAME=MoneyTrail

set /p DEVELOPER_NAME="Enter your name (Zulfiqar Akram): "
if "%DEVELOPER_NAME%"=="" set DEVELOPER_NAME=Zulfiqar Akram

set /p ORG_NAME="Enter organization (ZulfiqarDev): "
if "%ORG_NAME%"=="" set ORG_NAME=ZulfiqarDev

echo.
echo Creating keystore for %APP_NAME%...
echo.

"%KEYTOOL_PATH%" -genkey -v -keystore money-trail-key.jks -keyalg RSA -keysize 2048 -validity 10000 -alias money-trail-key -dname "CN=%DEVELOPER_NAME%, OU=%ORG_NAME%, O=%ORG_NAME%, L=Pakistan, S=Punjab, C=PK"

if exist "money-trail-key.jks" (
    echo.
    echo ===============================================
    echo       KEYSTORE CREATED SUCCESSFULLY! 🎉
    echo ===============================================
    echo.
    echo Keystore file: money-trail-key.jks
    echo Alias: money-trail-key
    echo.
    echo IMPORTANT:
    echo 1. BACKUP this keystore file immediately!
    echo 2. Remember your keystore password
    echo 3. Never lose this file - you need it for updates
    echo.
    echo Next step: Configure gradle for signing
    explorer .
) else (
    echo.
    echo ===============================================
    echo       KEYSTORE CREATION FAILED! ❌
    echo ===============================================
    echo Please try again or create manually.
)

echo.
pause 