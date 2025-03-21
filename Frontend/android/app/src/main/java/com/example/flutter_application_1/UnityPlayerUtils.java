package com.example.flutter_application_1;

import android.app.Activity;
import android.content.Context;
import android.content.ContextWrapper;
import android.content.Intent;
import android.graphics.PixelFormat;
import android.os.Bundle;
import android.view.ViewGroup;
import android.widget.FrameLayout;

import com.unity3d.player.UnityMessageManager;
import com.unity3d.player.UnityPlayer;
import com.unity3d.player.UnityPlayerActivity;

import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;

public class UnityPlayerUtils {
    
    private static UnityPlayer unityPlayer;
    private static Activity activity;
    private static MethodChannel flutterMethodChannel;
    
    public static void createUnityPlayer(Activity activity, MethodChannel flutterChannel) {
        UnityPlayerUtils.activity = activity;
        UnityPlayerUtils.flutterMethodChannel = flutterChannel;
        
        if (unityPlayer == null) {
            unityPlayer = new UnityPlayer(activity);
            UnityMessageManager.getInstance().setFlutterMethodChannel(flutterChannel);
        }
    }
    
    public static UnityPlayer getUnityPlayer() {
        return unityPlayer;
    }
    
    public static void addUnityViewToGroup(ViewGroup group) {
        if (unityPlayer != null && unityPlayer.getParent() == null) {
            group.addView(unityPlayer.getView(), 
                new ViewGroup.LayoutParams(
                    ViewGroup.LayoutParams.MATCH_PARENT, 
                    ViewGroup.LayoutParams.MATCH_PARENT
                )
            );
            unityPlayer.requestFocus();
            unityPlayer.resume();
        }
    }
    
    public static void sendMessageToUnity(String gameObject, String methodName, String message) {
        UnityMessageManager.getInstance().sendMessageToUnity(gameObject, methodName, message);
    }
    
    public static void pause() {
        if (unityPlayer != null) {
            unityPlayer.pause();
        }
    }
    
    public static void resume() {
        if (unityPlayer != null) {
            unityPlayer.resume();
        }
    }
    
    public static void destroy() {
        if (unityPlayer != null) {
            unityPlayer.destroy();
            unityPlayer = null;
        }
    }
    
    public static void handleMethodCall(MethodCall call, MethodChannel.Result result) {
        switch (call.method) {
            case "createUnityPlayer":
                if (activity != null) {
                    createUnityPlayer(activity, flutterMethodChannel);
                    result.success(true);
                } else {
                    result.error("NO_ACTIVITY", "Activity is null", null);
                }
                break;
            case "sendMessageToUnity":
                try {
                    String gameObject = call.argument("gameObject");
                    String methodName = call.argument("methodName");
                    String message = call.argument("message");
                    
                    if (gameObject != null && methodName != null) {
                        sendMessageToUnity(gameObject, methodName, message != null ? message : "");
                        result.success(true);
                    } else {
                        result.error("INVALID_ARGUMENTS", "gameObject or methodName is null", null);
                    }
                } catch (Exception e) {
                    result.error("EXCEPTION", e.getMessage(), null);
                }
                break;
            case "pauseUnity":
                pause();
                result.success(true);
                break;
            case "resumeUnity":
                resume();
                result.success(true);
                break;
            default:
                result.notImplemented();
                break;
        }
    }
} 