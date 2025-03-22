# Troubleshooting Unity Deep Linking Issues

If you're experiencing issues with deep linking from Flutter to your Unity VR application, follow this troubleshooting guide to identify and resolve the problem.

## Verify Unity App Installation

First, ensure the Unity VR application is properly installed on your device:

1. Connect your device and run one of the verification scripts:
   - On Windows: Run `.\verify_unity_app.ps1` in PowerShell
   - On macOS/Linux: Run `bash verify_unity_app.sh`

   These scripts will check if your app is installed and test all the deep linking methods.

2. If the scripts show that your app is not installed, follow the Unity build instructions to correctly build and install the app.

## Common Deep Linking Issues and Solutions

### Issue 1: Unity app is installed but deep linking fails

**Possible causes:**
- Incorrect package name in the Unity build
- Missing or incorrect intent filters in AndroidManifest.xml
- Incorrect deep link scheme used in Flutter

**Solutions:**

1. **Verify the package name:**
   ```bash
   adb shell pm list packages | grep -i "brave"
   ```
   Ensure the output shows `package:com.BraveSpace.VR` or your expected package name.

2. **Test the deep link manually:**
   ```bash
   adb shell am start -a android.intent.action.VIEW -d "unityapp://open"
   ```
   If this fails, the intent filter is likely missing or incorrect.

3. **Check the AndroidManifest.xml in Unity:**
   Make sure your AndroidManifest.xml contains proper intent filters:

   ```xml
   <intent-filter>
     <action android:name="android.intent.action.VIEW" />
     <category android:name="android.intent.category.DEFAULT" />
     <category android:name="android.intent.category.BROWSABLE" />
     <data android:scheme="unityapp" android:host="open" />
   </intent-filter>
   ```

4. **Try alternative launch methods in Flutter:**
   Update your Flutter code to try multiple methods of launching:

   ```dart
   // Try with package name and activity
   try {
     await launchUrl(
       Uri.parse("android-app://com.BraveSpace.VR/com.unity3d.player.UnityPlayerActivity"),
       mode: LaunchMode.externalApplication,
     );
     return;
   } catch (e) {
     print('Error: $e');
   }
   
   // Try with package name only
   try {
     await launchUrl(
       Uri.parse("android-app://com.BraveSpace.VR"),
       mode: LaunchMode.externalApplication,
     );
     return;
   } catch (e) {
     print('Error: $e');
   }
   
   // Try with deep link
   try {
     await launchUrl(
       Uri.parse("unityapp://open"),
       mode: LaunchMode.externalApplication,
     );
     return;
   } catch (e) {
     print('Error: $e');
   }
   ```

### Issue 2: Incorrect Unity AndroidManifest.xml is being used

Unity may not be using your custom AndroidManifest.xml file.

**Solutions:**

1. **Ensure your custom manifest is in the correct location:**
   - It should be in `Assets/Plugins/Android/AndroidManifest.xml`

2. **Check Unity Player Settings:**
   - In Unity, go to Edit > Project Settings > Player > Android
   - Under "Publishing Settings", ensure "Custom Main Manifest" is enabled

3. **Rebuild the Unity app:**
   - After making changes to the AndroidManifest.xml, perform a clean build of your Unity app

### Issue 3: Deep linking works in testing but not in production builds

**Solutions:**

1. **Use Development Build in Unity:**
   - In Unity Build Settings, check "Development Build" option

2. **Enable Intent Debugging:**
   Add this to your AndroidManifest.xml:
   ```xml
   <application
       android:debuggable="true"
       ... >
   ```

3. **Use Intent Intercept app:**
   Install [Intent Intercept](https://play.google.com/store/apps/details?id=uk.co.ashtonbrsc.android.intentintercept) to debug intents on your device

## Potential Workarounds

If deep linking continues to fail, try these alternatives:

1. **Direct launch by package name:**
   ```dart
   final AndroidIntent intent = AndroidIntent(
     action: 'android.intent.action.MAIN',
     package: 'com.BraveSpace.VR',
     componentName: 'com.unity3d.player.UnityPlayerActivity',
   );
   await intent.launch();
   ```
   Note: This requires adding the [android_intent_plus](https://pub.dev/packages/android_intent_plus) package.

2. **Use a different URI scheme:**
   Try a different scheme like `bravespace://vr/launch` in both Unity and Flutter.

3. **Consider an alternative integration approach:**
   - Use Firebase Dynamic Links
   - Use Flutter's MethodChannel to communicate with a native plugin that launches Unity

## Reporting Problems

If you continue to experience issues, gather the following information:

1. Output from the verification scripts
2. Your Unity AndroidManifest.xml content
3. Unity Player Settings (especially package name and minimum API level)
4. Flutter code used to launch the Unity app
5. Details of your device and Android version

With this information, you can more effectively debug the issue or request assistance. 