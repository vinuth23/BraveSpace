package com.unity3d.player;

import android.content.Context;
import android.graphics.Canvas;
import android.graphics.Color;
import android.graphics.Paint;
import android.graphics.Rect;
import android.view.View;
import android.widget.FrameLayout;

/**
 * Stub UnityPlayer class to make the integration compile.
 * This will be replaced with the real Unity player when the full Unity integration is completed.
 */
public class UnityPlayer extends FrameLayout {
    private TestPatternView testView;
    
    public UnityPlayer(Context context) {
        super(context);
        setBackgroundColor(Color.BLACK);
        
        // Add a test pattern view to show it's working
        testView = new TestPatternView(context);
        addView(testView);
    }
    
    /**
     * Static method to send messages to Unity
     */
    public static void UnitySendMessage(String gameObject, String methodName, String message) {
        // Stub implementation - will be replaced with real Unity integration
        android.util.Log.d("UnityPlayer", "Message to Unity: " + gameObject + "." + methodName + "(" + message + ")");
    }
    
    /**
     * Resume Unity player
     */
    public void resume() {
        // Stub implementation
        testView.invalidate();
    }
    
    /**
     * Pause Unity player
     */
    public void pause() {
        // Stub implementation
    }
    
    /**
     * Destroy Unity player
     */
    public void destroy() {
        // Stub implementation
        removeAllViews();
    }
    
    /**
     * Test pattern view to display something visual
     */
    private static class TestPatternView extends View {
        private Paint paint = new Paint();
        private long startTime;
        
        public TestPatternView(Context context) {
            super(context);
            startTime = System.currentTimeMillis();
            
            // Start animation
            post(new Runnable() {
                @Override
                public void run() {
                    invalidate();
                    postDelayed(this, 16); // ~60fps
                }
            });
        }
        
        @Override
        protected void onDraw(Canvas canvas) {
            super.onDraw(canvas);
            
            int width = getWidth();
            int height = getHeight();
            
            // Draw grid pattern
            paint.setColor(Color.DKGRAY);
            for (int i = 0; i < width; i += 50) {
                canvas.drawLine(i, 0, i, height, paint);
            }
            for (int i = 0; i < height; i += 50) {
                canvas.drawLine(0, i, width, i, paint);
            }
            
            // Draw animated circle
            float time = (System.currentTimeMillis() - startTime) / 1000f;
            float radius = width * 0.2f;
            float x = width * 0.5f + (float)Math.cos(time) * (width * 0.3f);
            float y = height * 0.5f + (float)Math.sin(time) * (height * 0.3f);
            
            paint.setColor(Color.BLUE);
            canvas.drawCircle(x, y, radius, paint);
            
            // Draw text
            paint.setColor(Color.WHITE);
            paint.setTextSize(40);
            String text = "Unity Integration Placeholder";
            Rect bounds = new Rect();
            paint.getTextBounds(text, 0, text.length(), bounds);
            canvas.drawText(text, (width - bounds.width()) / 2, height / 2, paint);
            
            paint.setTextSize(30);
            String subtext = "Your VR classroom will appear here";
            Rect subBounds = new Rect();
            paint.getTextBounds(subtext, 0, subtext.length(), subBounds);
            canvas.drawText(subtext, (width - subBounds.width()) / 2, height / 2 + 50, paint);
        }
    }
} 