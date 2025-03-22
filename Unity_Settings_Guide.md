# Unity Player Settings Guide

To ensure the Flutter app can properly launch your Unity VR application, you need to make sure your Unity Player Settings match the package name used in your Flutter code. Follow these steps:

## Check Current Settings

1. Open your Unity project
2. Go to **Edit > Project Settings > Player**
3. In the Android tab (look for the Android icon), check the current settings:
   - **Package Name**: This should be `com.DefaultCompany.classroomtest`
   - **Minimum API Level**: This should be 24 or higher
   - **Target API Level**: This should be 33 or higher

## If The Package Name Is Different

If your Package Name is different from what's shown in the Flutter code:

1. Either change your Unity Package Name to match the Flutter code:
   - In Unity, go to **Edit > Project Settings > Player**
   - In the Android tab, set **Package Name** to `com.DefaultCompany.classroomtest`

2. OR update your Flutter code to match your Unity Package Name:
   - Open `Frontend/lib/main.dart`
   - Find the `launchUnity()` function
   - Replace all instances of `com.DefaultCompany.classroomtest` with your actual package name

## AndroidManifest.xml Configuration

1. Make sure your custom AndroidManifest.xml is being used:
   - In Unity, go to **Edit > Project Settings > Player > Android**
   - In Publishing Settings, check **Custom Main Manifest**
   - Verify it points to `Assets/Plugins/Android/AndroidManifest.xml`

2. After making changes to AndroidManifest.xml, you need to rebuild the Unity app:
   - In Unity, go to **File > Build Settings**
   - Select Android platform
   - Click **Build**
   - Install the new APK on your device

## Test the Connection

After updating settings and rebuilding:

1. Install the updated Unity app on your device
2. Run one of the verification scripts to check if everything is working:
   - On Windows: Run `.\verify_unity_app.ps1` in PowerShell
   - On macOS/Linux: Run `bash verify_unity_app.sh`

## If Deep Linking Still Doesn't Work

If direct launching works but deep linking still doesn't work:

1. In Unity, verify that the intent filters in AndroidManifest.xml are correctly set up
2. Make sure to enable Custom Main Manifest in Player Settings
3. Consider adding `android:exported="true"` to your activity in AndroidManifest.xml
4. Rebuild the Unity app and reinstall it on your device

## Need More Help?

Refer to the `Unity_Deep_Linking_Troubleshooting.md` document for more detailed troubleshooting steps. 