package com.shabeeb.spendwise

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.graphics.Color
import android.net.Uri
import android.widget.RemoteViews

class SpendWiseBudgetWidgetProvider : AppWidgetProvider() {

    companion object {
        fun updateAllWidgets(context: Context) {
            val appWidgetManager = AppWidgetManager.getInstance(context)
            val componentName = ComponentName(context, SpendWiseBudgetWidgetProvider::class.java)
            val appWidgetIds = appWidgetManager.getAppWidgetIds(componentName)
            if (appWidgetIds != null && appWidgetIds.isNotEmpty()) {
                val provider = SpendWiseBudgetWidgetProvider()
                for (id in appWidgetIds) {
                    provider.updateSingleWidget(context, appWidgetManager, id)
                }
            }
        }
    }

    override fun onUpdate(context: Context, appWidgetManager: AppWidgetManager, appWidgetIds: IntArray) {
        for (appWidgetId in appWidgetIds) {
            updateSingleWidget(context, appWidgetManager, appWidgetId)
        }
    }

    private fun updateSingleWidget(context: Context, appWidgetManager: AppWidgetManager, appWidgetId: Int) {
        try {
            val prefs = context.getSharedPreferences(SpendWiseWidgetProvider.PREFS_NAME, Context.MODE_PRIVATE)
            val budgetRemaining = prefs.getString(SpendWiseWidgetProvider.KEY_BUDGET_REMAINING, "₹ 0.00") ?: "₹ 0.00"
            val budgetSpent = prefs.getString(SpendWiseWidgetProvider.KEY_BUDGET_SPENT, "₹ 0.00") ?: "₹ 0.00"
            val budgetTotal = prefs.getString(SpendWiseWidgetProvider.KEY_BUDGET_TOTAL, "₹ 0.00") ?: "₹ 0.00"
            val budgetPercent = prefs.getInt(SpendWiseWidgetProvider.KEY_BUDGET_PERCENT, 0)
            val budgetStatus = prefs.getString(SpendWiseWidgetProvider.KEY_BUDGET_STATUS, "On Track") ?: "On Track"
            val statusColorStr = prefs.getString(SpendWiseWidgetProvider.KEY_STATUS_COLOR, "#10B981") ?: "#10B981"

            val views = RemoteViews(context.packageName, R.layout.spendwise_budget_widget)

            // Status Badge Text & Color
            views.setTextViewText(R.id.widget_budget_status_badge, budgetStatus)
            try {
                val color = Color.parseColor(statusColorStr)
                views.setTextColor(R.id.widget_budget_status_badge, color)
            } catch (_: Exception) {
                views.setTextColor(R.id.widget_budget_status_badge, Color.parseColor("#10B981"))
            }

            // Progress Bar (Clamped between 0 and 100)
            val clampedProgress = budgetPercent.coerceIn(0, 100)
            views.setProgressBar(R.id.widget_budget_progress_bar, 100, clampedProgress, false)

            // Left amount and Spent vs Total ratio text
            val leftText = if (budgetRemaining.contains("Left", ignoreCase = true) || budgetRemaining == "Not Set") {
                budgetRemaining
            } else {
                "$budgetRemaining Left"
            }
            views.setTextViewText(R.id.widget_budget_left_text, leftText)
            views.setTextViewText(R.id.widget_budget_ratio_text, "Spent $budgetSpent of $budgetTotal")

            // Tap on Budget widget -> opens Budget screen in MainActivity
            val budgetIntent = Intent(context, MainActivity::class.java).apply {
                action = Intent.ACTION_VIEW
                data = Uri.parse("spendwise://budget")
                flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
                putExtra("route", "/budget")
            }
            val pendingIntent = PendingIntent.getActivity(
                context,
                201,
                budgetIntent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
            views.setOnClickPendingIntent(R.id.budget_widget_root, pendingIntent)

            appWidgetManager.updateAppWidget(appWidgetId, views)
        } catch (e: Exception) {
            android.util.Log.e("SpendWiseBudgetWidget", "Error updating widget ID: $appWidgetId", e)
        }
    }
}
