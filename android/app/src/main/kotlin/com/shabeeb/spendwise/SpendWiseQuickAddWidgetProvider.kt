package com.shabeeb.spendwise

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.widget.RemoteViews

class SpendWiseQuickAddWidgetProvider : AppWidgetProvider() {

    companion object {
        fun updateAllWidgets(context: Context) {
            val appWidgetManager = AppWidgetManager.getInstance(context)
            val componentName = ComponentName(context, SpendWiseQuickAddWidgetProvider::class.java)
            val appWidgetIds = appWidgetManager.getAppWidgetIds(componentName)
            if (appWidgetIds != null && appWidgetIds.isNotEmpty()) {
                val provider = SpendWiseQuickAddWidgetProvider()
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
            val views = RemoteViews(context.packageName, R.layout.spendwise_quick_add_widget)

            // 1. PendingIntent for Quick Expense
            val expenseIntent = Intent(context, QuickAddActivity::class.java).apply {
                action = Intent.ACTION_VIEW
                data = Uri.parse("spendwise://quick_add?type=expense")
                flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
                putExtra("route", "/quick_add?type=expense")
            }
            val expensePendingIntent = PendingIntent.getActivity(
                context,
                101,
                expenseIntent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
            views.setOnClickPendingIntent(R.id.btn_quick_expense, expensePendingIntent)

            // 2. PendingIntent for Quick Income
            val incomeIntent = Intent(context, QuickAddActivity::class.java).apply {
                action = Intent.ACTION_VIEW
                data = Uri.parse("spendwise://quick_add?type=income")
                flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
                putExtra("route", "/quick_add?type=income")
            }
            val incomePendingIntent = PendingIntent.getActivity(
                context,
                102,
                incomeIntent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
            views.setOnClickPendingIntent(R.id.btn_quick_income, incomePendingIntent)

            appWidgetManager.updateAppWidget(appWidgetId, views)
        } catch (e: Exception) {
            android.util.Log.e("SpendWiseQuickAddWidget", "Error updating widget ID: $appWidgetId", e)
        }
    }
}
