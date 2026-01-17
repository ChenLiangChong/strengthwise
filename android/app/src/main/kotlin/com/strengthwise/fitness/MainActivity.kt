package com.strengthwise.fitness

import android.content.Intent
import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        
        // ⭐ v3.9: 處理從通知啟動的 Intent
        handleIntent(intent)
    }
    
    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        
        // ⭐ v3.9: 處理通知點擊的 Intent
        handleIntent(intent)
    }
    
    private fun handleIntent(intent: Intent?) {
        // 記錄 Intent 信息（Debug 用）
        android.util.Log.d("MainActivity", "handleIntent: action=${intent?.action}, extras=${intent?.extras}")
        
        // FCM 通知點擊會帶有特定的 extras
        intent?.extras?.let { extras ->
            for (key in extras.keySet()) {
                android.util.Log.d("MainActivity", "  extra: $key = ${extras.get(key)}")
            }
        }
    }
}
