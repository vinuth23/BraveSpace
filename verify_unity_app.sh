#!/bin/bash
# A script to verify Unity app installation and test deep links

echo "==== Unity App Installation Verification ===="
echo "Checking if the Unity app is installed..."

# Check if adb is available
if ! command -v adb &> /dev/null; then
    echo "Error: adb is not installed or not in PATH"
    echo "Please install Android Debug Bridge (adb) to use this script"
    exit 1
fi

# Check for connected devices
DEVICES=$(adb devices | grep -v "List" | grep device)
if [ -z "$DEVICES" ]; then
    echo "Error: No connected Android device found"
    echo "Please connect an Android device and enable USB debugging"
    exit 1
fi

echo "Device(s) found:"
adb devices | grep -v "List"
echo ""

# Check if the Unity app is installed
echo "Checking for BraveSpace VR app..."
PACKAGE_EXISTS=$(adb shell pm list packages | grep -i "BraveSpace")

if [ -z "$PACKAGE_EXISTS" ]; then
    echo "❌ BraveSpace VR app NOT found on the device"
    echo "   Please make sure you've built and installed the Unity app correctly"
else
    echo "✅ BraveSpace VR app found: $PACKAGE_EXISTS"
fi

# Find the exact package name
echo ""
echo "Searching for all packages containing 'brave'..."
BRAVE_PACKAGES=$(adb shell pm list packages | grep -i "brave")
echo "$BRAVE_PACKAGES"

echo ""
echo "==== Testing Deep Links ===="
echo "1. Testing original deep link (unityapp://open)"
adb shell am start -a android.intent.action.VIEW -d "unityapp://open"
echo ""

echo "2. Testing alternative deep link (bravespace://vr/launch)"
adb shell am start -a android.intent.action.VIEW -d "bravespace://vr/launch"
echo ""

echo "3. Testing direct package launch"
# Extract first package from list
if [ ! -z "$BRAVE_PACKAGES" ]; then
    FIRST_PACKAGE=$(echo "$BRAVE_PACKAGES" | head -n 1 | sed 's/package://g')
    echo "Attempting to launch: $FIRST_PACKAGE"
    adb shell monkey -p $FIRST_PACKAGE -c android.intent.category.LAUNCHER 1
else
    echo "❌ Cannot test direct package launch - no package found"
fi

echo ""
echo "==== Unity App Manifest Information ===="
if [ ! -z "$BRAVE_PACKAGES" ]; then
    FIRST_PACKAGE=$(echo "$BRAVE_PACKAGES" | head -n 1 | sed 's/package://g')
    echo "Getting manifest information for: $FIRST_PACKAGE"
    adb shell dumpsys package $FIRST_PACKAGE | grep -A 10 "intent filter"
else
    echo "❌ Cannot get manifest information - no package found"
fi

echo ""
echo "Tests completed. Check the output above for any errors or issues."
echo "If deep linking is not working, verify that your AndroidManifest.xml has the correct intent filters." 