package com.example.flutter_application_1

import androidx.annotation.NonNull
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterActivity() {
    private val UNITY_CHANNEL = "com.unity3d.player/unity"
    
    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        val methodChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, UNITY_CHANNEL)
        methodChannel.setMethodCallHandler { call, result ->
            // Handle method calls from Flutter to Unity
            when (call.method) {
                "isUnityAvailable" -> {
                    // Return true to indicate Unity is available
                    result.success(true)
                }
                "sendMessage" -> {
                    // Mock Unity message sending
                    val gameObject = call.argument<String>("gameObject")
                    val methodName = call.argument<String>("methodName")
                    val message = call.argument<String>("message")
                    
                    println("Mock sending message to Unity: $gameObject.$methodName($message)")
                    
                    // After a short delay, send a mock response back to Flutter
                    android.os.Handler().postDelayed({
                        val mockResponse = mapOf(
                            "type" to "ready",
                            "data" to mapOf<String, Any>()
                        )
                        methodChannel.invokeMethod("onUnityMessage", mockResponse)
                    }, 1500)
                    
                    result.success(null)
                }
                "initialize" -> {
                    // Mock initialization
                    result.success(true)
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
    }
}
