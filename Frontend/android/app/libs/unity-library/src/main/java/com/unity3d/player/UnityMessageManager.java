package com.unity3d.player;

import android.os.Handler;
import android.os.Looper;
import android.util.Log;

import org.json.JSONException;
import org.json.JSONObject;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

import io.flutter.plugin.common.MethodChannel;

public class UnityMessageManager {
    private static final String TAG = "UnityMessageManager";
    private static UnityMessageManager instance;
    private final Map<String, List<MethodChannel.Result>> unityMethodCallbackMap = new HashMap<>();
    private final Map<String, UnityMessageListener> messageListenerMap = new HashMap<>();
    private MethodChannel flutterMethodChannel;

    private UnityMessageManager() {
    }

    public static UnityMessageManager getInstance() {
        if (instance == null) {
            instance = new UnityMessageManager();
        }
        return instance;
    }

    public void setFlutterMethodChannel(MethodChannel flutterMethodChannel) {
        this.flutterMethodChannel = flutterMethodChannel;
    }

    public void sendMessageToFlutter(final String message) {
        if (flutterMethodChannel == null) {
            Log.e(TAG, "Flutter method channel is null. Cannot send message to Flutter.");
            return;
        }
        
        new Handler(Looper.getMainLooper()).post(() -> {
            flutterMethodChannel.invokeMethod("onUnityMessage", message);
        });
    }

    public void sendMessageToUnity(final String gameObject, final String methodName, final String message) {
        try {
            UnityPlayer.UnitySendMessage(gameObject, methodName, message);
        } catch (Exception e) {
            Log.e(TAG, "Failed to send message to Unity: " + e.getMessage());
        }
    }

    public void onMessage(String message) {
        try {
            JSONObject jsonObject = new JSONObject(message);
            String id = jsonObject.optString("id");
            String data = jsonObject.optString("data");

            if (id != null && !id.isEmpty()) {
                List<MethodChannel.Result> results = unityMethodCallbackMap.get(id);
                if (results != null) {
                    for (MethodChannel.Result result : results) {
                        try {
                            result.success(data);
                        } catch (Exception e) {
                            Log.e(TAG, "Error handling Unity message result: " + e.getMessage());
                        }
                    }
                    unityMethodCallbackMap.remove(id);
                }
            }

            for (Map.Entry<String, UnityMessageListener> entry : messageListenerMap.entrySet()) {
                try {
                    entry.getValue().onMessage(message);
                } catch (Exception e) {
                    Log.e(TAG, "Error delivering message to listener: " + e.getMessage());
                }
            }
        } catch (JSONException e) {
            Log.e(TAG, "Invalid JSON message received from Unity: " + e.getMessage());
        }
    }

    public void registerListener(String key, UnityMessageListener listener) {
        messageListenerMap.put(key, listener);
    }

    public void unregisterListener(String key) {
        messageListenerMap.remove(key);
    }

    public void addMethodCallbackToMap(String id, MethodChannel.Result result) {
        List<MethodChannel.Result> resultList = unityMethodCallbackMap.get(id);
        if (resultList == null) {
            resultList = new ArrayList<>();
            unityMethodCallbackMap.put(id, resultList);
        }
        resultList.add(result);
    }

    public interface UnityMessageListener {
        void onMessage(String message);
    }
} 