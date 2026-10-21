package com.shabeeb.spendwise

import android.content.Context
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.android.FlutterActivityLaunchConfigs.BackgroundMode
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class QuickAddActivity : FlutterFragmentActivity() {

    private val WIDGET_CHANNEL = "com.shabeeb.spendwise/widget"

    override fun getBackgroundMode(): BackgroundMode {
        return BackgroundMode.transparent
    }

    override fun getInitialRoute(): String {
        return "/quick_add"
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        val widgetChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, WIDGET_CHANNEL)
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
                    result.success("/quick_add")
                }
                else -> result.notImplemented()
            }
        }
    }
}
