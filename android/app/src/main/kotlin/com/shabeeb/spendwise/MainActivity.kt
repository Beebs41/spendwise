package com.shabeeb.spendwise

import android.content.Context
import android.content.Intent
import android.os.Bundle
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterFragmentActivity() {
    private val APK_CHANNEL = "com.shabeeb.spendwise/apk"
    private val WIDGET_CHANNEL = "com.shabeeb.spendwise/widget"

    private var widgetMethodChannel: MethodChannel? = null
    private var initialWidgetRoute: String? = null

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        extractRouteFromIntent(intent)?.let {
            initialWidgetRoute = it
        }
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        extractRouteFromIntent(intent)?.let { route ->
            widgetMethodChannel?.invokeMethod("onWidgetAction", route)
        }
    }

    private fun extractRouteFromIntent(intent: Intent?): String? {
        if (intent == null) return null
        val uri = intent.data
        if (uri != null && uri.scheme == "spendwise") {
            return when (uri.host) {
                "add_transaction" -> "/add_transaction"
                "dashboard" -> "/dashboard"
                else -> "/${uri.host}"
            }
        }
        return intent.getStringExtra("route")
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // APK sharing channel
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, APK_CHANNEL).setMethodCallHandler { call, result ->
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

        // Home screen widget channel
        val widgetChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, WIDGET_CHANNEL)
        widgetMethodChannel = widgetChannel

        widgetChannel.setMethodCallHandler { call, result ->
            when (call.method) {
                "updateWidget" -> {
                    try {
                        val args = call.arguments as? Map<*, *>
                        val prefs = applicationContext.getSharedPreferences(
                            SpendWiseWidgetProvider.PREFS_NAME,
                            Context.MODE_PRIVATE
                        )
                        val editor = prefs.edit()

                        args?.get("todaySpend")?.let { editor.putString(SpendWiseWidgetProvider.KEY_TODAY_SPEND, it.toString()) }
                        args?.get("budgetRemaining")?.let { editor.putString(SpendWiseWidgetProvider.KEY_BUDGET_REMAINING, it.toString()) }
                        args?.get("budgetStatus")?.let { editor.putString(SpendWiseWidgetProvider.KEY_BUDGET_STATUS, it.toString()) }
                        args?.get("statusColor")?.let { editor.putString(SpendWiseWidgetProvider.KEY_STATUS_COLOR, it.toString()) }
                        args?.get("lastUpdated")?.let { editor.putString(SpendWiseWidgetProvider.KEY_LAST_UPDATED, it.toString()) }
                        args?.get("footerText")?.let { editor.putString(SpendWiseWidgetProvider.KEY_FOOTER_TEXT, it.toString()) }

                        editor.apply()

                        // Push update to all home screen widget instances
                        SpendWiseWidgetProvider.updateAllWidgets(applicationContext)
                        result.success(true)
                    } catch (e: Exception) {
                        result.error("UPDATE_ERROR", e.message, null)
                    }
                }
                "getInitialRoute" -> {
                    val route = initialWidgetRoute
                    initialWidgetRoute = null
                    result.success(route)
                }
                else -> result.notImplemented()
            }
        }
    }
}
