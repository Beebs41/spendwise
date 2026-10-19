package com.shabeeb.spendwise

import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterFragmentActivity() {
    private val CHANNEL = "com.shabeeb.spendwise/apk"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            if (call.method == "getApkPath") {
                try {
                    val apkPath = applicationContext.packageCodePath
                    result.success(apkPath)
                } catch (e: Exception) {
                    result.error("UNAVAILABLE", "APK path not available.", null)
                }
            } else {
                result.notImplemented()
            }
        }
    }
}


