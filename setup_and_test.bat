@echo off
echo ========================================
echo BEACON Network - Setup and Test Script
echo ========================================
echo.

echo Step 1: Cleaning previous build...
call flutter clean
echo.

echo Step 2: Getting dependencies...
call flutter pub get
echo.

echo Step 3: Checking connected devices...
call flutter devices
echo.

echo ========================================
echo Setup complete!
echo ========================================
echo.
echo NEXT STEPS:
echo 1. Connect TWO Android devices via USB
echo 2. Enable USB debugging on both devices
echo 3. Run: flutter devices (to see device IDs)
echo 4. For Device 1: flutter run -d [device-1-id]
echo 5. For Device 2: flutter run -d [device-2-id]
echo.
echo OR build APK and install on both:
echo    flutter build apk --release
echo    (APK will be in: build\app\outputs\flutter-apk\)
echo.
echo See TESTING_GUIDE.md for detailed instructions
echo ========================================
pause

