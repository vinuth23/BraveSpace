package com.example.flutter_application_1

import android.content.Context
import android.os.Bundle
import android.view.View
import androidx.annotation.NonNull
import com.unity3d.player.UnityPlayer
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.StandardMessageCodec
import io.flutter.plugin.platform.PlatformView
import io.flutter.plugin.platform.PlatformViewFactory

class MainActivity: FlutterActivity() {
    private val UNITY_CHANNEL = "com.unity3d.player/unity"
    
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        hideSystemUi()
    }
    
    private fun hideSystemUi() {
        window.decorView.systemUiVisibility = (View.SYSTEM_UI_FLAG_LAYOUT_STABLE
                or View.SYSTEM_UI_FLAG_LAYOUT_HIDE_NAVIGATION
                or View.SYSTEM_UI_FLAG_LAYOUT_FULLSCREEN
                or View.SYSTEM_UI_FLAG_HIDE_NAVIGATION
                or View.SYSTEM_UI_FLAG_FULLSCREEN
                or View.SYSTEM_UI_FLAG_IMMERSIVE_STICKY)
    }
    
    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        // Register Unity View Factory
        flutterEngine.platformViewsController.registry.registerViewFactory(
            "com.unity3d.player/unityView", 
            UnityViewFactory(this)
        )
        
        val methodChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, UNITY_CHANNEL)
        methodChannel.setMethodCallHandler { call, result ->
            // Handle method calls from Flutter to Unity
            when (call.method) {
                "isUnityAvailable" -> {
                    // Return true since Unity is available
                    result.success(true)
                }
                "sendMessage" -> {
                    // Send message to Unity
                    val gameObject = call.argument<String>("gameObject")
                    val methodName = call.argument<String>("methodName")
                    val message = call.argument<String>("message")
                    
                    if (gameObject != null && methodName != null && message != null) {
                        UnityPlayer.UnitySendMessage(gameObject, methodName, message)
                        result.success(null)
                    } else {
                        result.error("INVALID_ARGUMENTS", "Invalid arguments", null)
                    }
                }
                "initialize" -> {
                    // Unity is already initialized
                    result.success(true)
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
    }
    
    // Safe way to get Flutter engine
    fun getFlutterEngineRef(): FlutterEngine? {
        return flutterEngine
    }
}

// Factory to create Unity views
class UnityViewFactory(private val activity: MainActivity) : PlatformViewFactory(StandardMessageCodec.INSTANCE) {
    companion object {
        // Static reference to the UnityPlayer
        var unityPlayer: UnityPlayer? = null
    }
    
    override fun create(context: Context, viewId: Int, args: Any?): PlatformView {
        return UnityPlayerView(activity)
    }
}

// PlatformView implementation that displays Unity content
class UnityPlayerView(private val activity: MainActivity) : PlatformView {
    init {
        if (UnityViewFactory.unityPlayer == null) {
            UnityViewFactory.unityPlayer = UnityPlayer(activity)
            
            // Set up message handler from Unity to Flutter
            val flutterEngine = activity.getFlutterEngineRef()
            if (flutterEngine != null) {
                val methodChannel = MethodChannel(
                    flutterEngine.dartExecutor.binaryMessenger,
                    "com.unity3d.player/unity"
                )
                
                // Notify Flutter that Unity is ready after a delay to allow Unity to initialize
                activity.runOnUiThread {
                    android.os.Handler().postDelayed({
                        val readyResponse = mapOf(
                            "type" to "ready",
                            "data" to mapOf<String, Any>()
                        )
                        methodChannel.invokeMethod("onUnityMessage", readyResponse)
                    }, 2000)
                }
            }
        }
    }
    
    override fun getView(): View {
        return UnityViewFactory.unityPlayer ?: View(activity)
    }
    
    override fun dispose() {
        // Don't destroy here, let the activity handle it
    }
}
