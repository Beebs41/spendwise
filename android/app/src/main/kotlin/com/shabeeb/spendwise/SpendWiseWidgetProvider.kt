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

class SpendWiseWidgetProvider : AppWidgetProvider() {

    companion object {
        const val PREFS_NAME = "SpendWiseWidgetPrefs"
        const val KEY_TODAY_SPEND = "today_spend"
        const val KEY_BUDGET_REMAINING = "budget_remaining"
        const val KEY_BUDGET_STATUS = "budget_status"
        const val KEY_STATUS_COLOR = "status_color"
        const val KEY_LAST_UPDATED = "last_updated"
        const val KEY_FOOTER_TEXT = "footer_text"
        const val KEY_BUDGET_SPENT = "budget_spent"
        const val KEY_BUDGET_TOTAL = "budget_total"
        const val KEY_BUDGET_PERCENT = "budget_percent"

        fun updateAllWidgets(context: Context) {
            val appWidgetManager = AppWidgetManager.getInstance(context)
            val componentName = ComponentName(context, SpendWiseWidgetProvider::class.java)
            val appWidgetIds = appWidgetManager.getAppWidgetIds(componentName)
            if (appWidgetIds != null && appWidgetIds.isNotEmpty()) {
                val provider = SpendWiseWidgetProvider()
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
            val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
            val todaySpend = prefs.getString(KEY_TODAY_SPEND, "₹ 0.00") ?: "₹ 0.00"
            val budgetRemaining = prefs.getString(KEY_BUDGET_REMAINING, "₹ 0.00") ?: "₹ 0.00"
            val budgetStatus = prefs.getString(KEY_BUDGET_STATUS, "On Track") ?: "On Track"
            val statusColorStr = prefs.getString(KEY_STATUS_COLOR, "#10B981") ?: "#10B981"
            var lastUpdated = prefs.getString(KEY_LAST_UPDATED, "") ?: ""
            if (lastUpdated.isEmpty()) {
                lastUpdated = "Just now"
            }
            val footerText = prefs.getString(KEY_FOOTER_TEXT, "Tap to view breakdown") ?: "Tap to view breakdown"

            val views = RemoteViews(context.packageName, R.layout.spendwise_widget)

            // Safe icon
            views.setImageViewResource(R.id.widget_logo, R.mipmap.ic_launcher)

            // Set metrics text
            views.setTextViewText(R.id.widget_today_amount, todaySpend)
            views.setTextViewText(R.id.widget_budget_remaining, budgetRemaining)
            views.setTextViewText(R.id.widget_status_badge, budgetStatus)
            views.setTextViewText(R.id.widget_updated_time, lastUpdated)
            views.setTextViewText(R.id.widget_footer_text, footerText)

            // Apply status color
            try {
                val color = Color.parseColor(statusColorStr)
                views.setTextColor(R.id.widget_status_badge, color)
            } catch (_: Exception) {
                views.setTextColor(R.id.widget_status_badge, Color.parseColor("#10B981"))
            }

            // 1. PendingIntent for main widget / header click (Open Dashboard)
            val openDashboardIntent = Intent(context, MainActivity::class.java).apply {
                action = Intent.ACTION_VIEW
                data = Uri.parse("spendwise://dashboard")
                flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
                putExtra("route", "/dashboard")
            }
            val openDashboardPendingIntent = PendingIntent.getActivity(
                context,
                0,
                openDashboardIntent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
            views.setOnClickPendingIntent(R.id.widget_root, openDashboardPendingIntent)
            views.setOnClickPendingIntent(R.id.widget_header, openDashboardPendingIntent)
            views.setOnClickPendingIntent(R.id.widget_logo, openDashboardPendingIntent)
            views.setOnClickPendingIntent(R.id.widget_title, openDashboardPendingIntent)
            views.setOnClickPendingIntent(R.id.widget_footer, openDashboardPendingIntent)

            // 2. PendingIntent for "Today's Spend" Card click (Open Transactions filtered to Today)
            val openTodayIntent = Intent(context, MainActivity::class.java).apply {
                action = Intent.ACTION_VIEW
                data = Uri.parse("spendwise://transactions?filter=today")
                flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
                putExtra("route", "/transactions?filter=today")
            }
            val openTodayPendingIntent = PendingIntent.getActivity(
                context,
                2,
                openTodayIntent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
            views.setOnClickPendingIntent(R.id.widget_card_today, openTodayPendingIntent)

            // 3. PendingIntent for "Budget Left" Card click (Open Budget screen)
            val openBudgetIntent = Intent(context, MainActivity::class.java).apply {
                action = Intent.ACTION_VIEW
                data = Uri.parse("spendwise://budget")
                flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
                putExtra("route", "/budget")
            }
            val openBudgetPendingIntent = PendingIntent.getActivity(
                context,
                3,
                openBudgetIntent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
            views.setOnClickPendingIntent(R.id.widget_card_budget, openBudgetPendingIntent)

            // 4. PendingIntent for Quick Add Expense click (+ button) -> Launches Floating QuickAddActivity
            val quickAddIntent = Intent(context, QuickAddActivity::class.java).apply {
                action = Intent.ACTION_VIEW
                data = Uri.parse("spendwise://quick_add")
                flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
                putExtra("route", "/quick_add")
            }
            val quickAddPendingIntent = PendingIntent.getActivity(
                context,
                4,
                quickAddIntent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
            views.setOnClickPendingIntent(R.id.widget_btn_add_expense, quickAddPendingIntent)

            appWidgetManager.updateAppWidget(appWidgetId, views)
        } catch (e: Exception) {
            android.util.Log.e("SpendWiseWidget", "Error updating widget ID: $appWidgetId", e)
        }
    }
}
