package com.unity3d.player;

import android.content.Context;
import android.content.Intent;
import android.content.res.Configuration;
import android.view.KeyEvent;
import android.view.MotionEvent;
import android.widget.FrameLayout;

/**
 * Extended UnityPlayer with additional methods required by UnityPlayerActivity.
 * This is a stub implementation to make the integration compile.
 */
public class UnityPlayerForActivityOrService extends UnityPlayer {
    
    public UnityPlayerForActivityOrService(Context context, IUnityPlayerSupport support) {
        super(context);
    }
    
    public FrameLayout getFrameLayout() {
        return this; // UnityPlayer extends FrameLayout, so return self
    }
    
    public void newIntent(Intent intent) {
        // Stub implementation
    }
    
    public void configurationChanged(Configuration newConfig) {
        // Stub implementation
    }
    
    public void windowFocusChanged(boolean hasFocus) {
        // Stub implementation
    }
    
    public boolean injectEvent(KeyEvent event) {
        return false; // Stub implementation
    }
    
    public int addPermissionRequest(PermissionRequest request) {
        return 1; // Stub implementation
    }
    
    public void permissionResponse(UnityPlayerActivity activity, int requestCode, String[] permissions, int[] grantResults) {
        // Stub implementation
    }
} 