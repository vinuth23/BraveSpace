package com.unity3d.player;

import android.content.Context;

/**
 * Stub for MultiWindowSupport to make the integration compile.
 * This will be replaced with the real Unity implementation later.
 */
public class MultiWindowSupport {
    
    public static boolean getAllowResizableWindow(Context context) {
        return false;
    }
    
    public static void saveMultiWindowMode(Context context) {
        // Stub implementation
    }
    
    public static boolean isMultiWindowModeChangedToTrue(Context context) {
        return false;
    }
} 