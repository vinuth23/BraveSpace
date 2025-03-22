package com.example.flutter_application_1

import android.content.Context
import android.view.View
import android.widget.FrameLayout
import androidx.annotation.NonNull
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.StandardMessageCodec
import io.flutter.plugin.platform.PlatformView
import io.flutter.plugin.platform.PlatformViewFactory

class MainActivity: FlutterActivity() {
    private val UNITY_CHANNEL = "com.unity3d.player/unity"
    
    companion object {
        // Static reference to the FlutterEngine for PlatformViews
        @JvmStatic
        var flutterEngineInstance: FlutterEngine? = null
    }
    
    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        // Store the FlutterEngine instance
        flutterEngineInstance = flutterEngine
        
        // Register Unity View Factory
        flutterEngine.platformViewsController.registry.registerViewFactory(
            "com.unity3d.player/unityView", 
            UnityViewFactory()
        )
        
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
                    
                    // Extract session ID from message if it's initialization
                    if (methodName == "ReceiveDataFromFlutter") {
                        // After a short delay, send a mock response back to Flutter
                        android.os.Handler().postDelayed({
                            val mockResponse = mapOf(
                                "type" to "ready",
                                "data" to mapOf<String, Any>()
                            )
                            methodChannel.invokeMethod("onUnityMessage", mockResponse)
                        }, 1500)
                    }
                    
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

// Factory to create Unity views
class UnityViewFactory : PlatformViewFactory(StandardMessageCodec.INSTANCE) {
    override fun create(context: Context, viewId: Int, args: Any?): PlatformView {
        return UnityView(context)
    }
}

// PlatformView implementation that will display Unity content
class UnityView(private val context: Context) : PlatformView {
    private val unityView: FrameLayout

    init {
        unityView = FrameLayout(context).apply {
            // Create a simulated classroom environment
            setBackgroundColor(android.graphics.Color.parseColor("#87CEEB")) // Sky blue background
            
            // Create a classroom floor
            val floorView = View(context).apply {
                setBackgroundColor(android.graphics.Color.parseColor("#8B4513")) // Brown floor
            }
            
            // Add the floor
            addView(floorView, FrameLayout.LayoutParams(
                FrameLayout.LayoutParams.MATCH_PARENT,
                FrameLayout.LayoutParams.MATCH_PARENT / 3
            ).apply {
                gravity = android.view.Gravity.BOTTOM
            })
            
            // Add walls (left and right)
            val leftWallView = View(context).apply {
                setBackgroundColor(android.graphics.Color.parseColor("#F5F5DC")) // Beige wall
            }
            
            addView(leftWallView, FrameLayout.LayoutParams(
                FrameLayout.LayoutParams.MATCH_PARENT / 8,
                FrameLayout.LayoutParams.MATCH_PARENT
            ).apply {
                gravity = android.view.Gravity.LEFT
            })
            
            val rightWallView = View(context).apply {
                setBackgroundColor(android.graphics.Color.parseColor("#F5F5DC")) // Beige wall
            }
            
            addView(rightWallView, FrameLayout.LayoutParams(
                FrameLayout.LayoutParams.MATCH_PARENT / 8,
                FrameLayout.LayoutParams.MATCH_PARENT
            ).apply {
                gravity = android.view.Gravity.RIGHT
            })
            
            // Add a blackboard/whiteboard
            val boardView = View(context).apply {
                setBackgroundColor(android.graphics.Color.parseColor("#2F4F4F")) // Dark slate grey board
            }
            
            addView(boardView, FrameLayout.LayoutParams(
                FrameLayout.LayoutParams.MATCH_PARENT / 2,
                FrameLayout.LayoutParams.MATCH_PARENT / 4
            ).apply {
                gravity = android.view.Gravity.TOP or android.view.Gravity.CENTER_HORIZONTAL
                topMargin = 50
            })
            
            // Add desks (simplified as rectangles)
            for (row in 0..1) {
                for (col in 0..2) {
                    val deskView = View(context).apply {
                        setBackgroundColor(android.graphics.Color.parseColor("#A0522D")) // Brown desk
                    }
                    
                    addView(deskView, FrameLayout.LayoutParams(
                        FrameLayout.LayoutParams.MATCH_PARENT / 5,
                        FrameLayout.LayoutParams.MATCH_PARENT / 8
                    ).apply {
                        gravity = android.view.Gravity.CENTER
                        topMargin = (FrameLayout.LayoutParams.MATCH_PARENT / 10) * (row + 1)
                        leftMargin = ((FrameLayout.LayoutParams.MATCH_PARENT / 5) * col) - 
                                     (FrameLayout.LayoutParams.MATCH_PARENT / 7)
                    })
                }
            }
        }
        
        // Post a delayed event to simulate Unity loading complete
        android.os.Handler().postDelayed({
            try {
                // Get the FlutterEngine from our companion object
                val engine = MainActivity.flutterEngineInstance
                if (engine != null) {
                    val methodChannel = MethodChannel(
                        engine.dartExecutor.binaryMessenger,
                        "com.unity3d.player/unity"
                    )
                    
                    val readyResponse = mapOf(
                        "type" to "ready",
                        "data" to mapOf<String, Any>()
                    )
                    
                    methodChannel.invokeMethod("onUnityMessage", readyResponse)
                } else {
                    println("Could not get FlutterEngine instance to send ready message")
                }
            } catch (e: Exception) {
                println("Error sending ready event: ${e.message}")
            }
        }, 2000)
    }

    override fun getView(): View {
        return unityView
    }

    override fun dispose() {
        // Clean up resources
    }
}
