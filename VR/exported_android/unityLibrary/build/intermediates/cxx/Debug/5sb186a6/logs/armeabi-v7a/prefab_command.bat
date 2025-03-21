@echo off
"C:\\Program Files\\Android\\Android Studio\\jbr\\bin\\java" ^
  --class-path ^
  "C:\\Users\\vinut\\.gradle\\caches\\modules-2\\files-2.1\\com.google.prefab\\cli\\2.0.0\\f2702b5ca13df54e3ca92f29d6b403fb6285d8df\\cli-2.0.0-all.jar" ^
  com.google.prefab.cli.AppKt ^
  --build-system ^
  cmake ^
  --platform ^
  android ^
  --abi ^
  armeabi-v7a ^
  --os-version ^
  23 ^
  --stl ^
  c++_shared ^
  --ndk-version ^
  23 ^
  --output ^
  "C:\\Users\\vinut\\Desktop\\Bravespace\\BraveSpace\\VR\\exported_android\\unityLibrary\\.cxx\\Debug\\5sb186a6\\prefab\\armeabi-v7a\\prefab-configure" ^
  "C:\\Users\\vinut\\.gradle\\caches\\8.9\\transforms\\0922550b6600bb0f72f745390be97dda\\transformed\\jetified-games-frame-pacing-1.10.0\\prefab"
