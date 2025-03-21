package com.example.flutter_application_1;

import android.os.Bundle;
import androidx.annotation.NonNull;

import com.unity3d.player.UnityMessageManager;

import io.flutter.embedding.android.FlutterActivity;
import io.flutter.embedding.engine.FlutterEngine;
import io.flutter.plugin.common.MethodChannel;

public class MainActivity extends FlutterActivity {
    private static final String UNITY_CHANNEL = "com.bravespace.unity/communication";
    private MethodChannel unityMethodChannel;
    
    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
    }
    
    @Override
    public void configureFlutterEngine(@NonNull FlutterEngine flutterEngine) {
        super.configureFlutterEngine(flutterEngine);
        
        unityMethodChannel = new MethodChannel(flutterEngine.getDartExecutor().getBinaryMessenger(), UNITY_CHANNEL);
        unityMethodChannel.setMethodCallHandler((call, result) -> {
            // Handle method calls from Flutter
            UnityPlayerUtils.handleMethodCall(call, result);
        });
        
        // Initialize Unity player
        UnityPlayerUtils.createUnityPlayer(this, unityMethodChannel);
    }
    
    @Override
    protected void onResume() {
        super.onResume();
        UnityPlayerUtils.resume();
    }
    
    @Override
    protected void onPause() {
        super.onPause();
        UnityPlayerUtils.pause();
    }
    
    @Override
    protected void onDestroy() {
        super.onDestroy();
        UnityPlayerUtils.destroy();
    }
} 