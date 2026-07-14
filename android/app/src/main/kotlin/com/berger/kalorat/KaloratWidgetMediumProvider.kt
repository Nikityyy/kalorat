package com.berger.kalorat

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetProvider
import org.json.JSONArray

class KaloratWidgetMediumProvider : HomeWidgetProvider() {

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences
    ) {
        appWidgetIds.forEach { widgetId ->
            val streak = widgetData.getInt("streak_count", 0)
            val isTrackedToday = widgetData.getBoolean("is_tracked_today", false)
            
            val views = RemoteViews(context.packageName, R.layout.widget_medium)
            
            // Update Medium Widget
            views.setTextViewText(R.id.widget_medium_streak_text, streak.toString())
            
            if (isTrackedToday) {
                views.setImageViewResource(R.id.widget_medium_status_icon, R.drawable.ic_lucide_flame)
                views.setTextViewText(R.id.widget_medium_title_text, "Flame lit!")
                views.setTextViewText(R.id.widget_medium_subtitle_text, "Streak protected for today.")
            } else {
                views.setImageViewResource(R.id.widget_medium_status_icon, R.drawable.ic_lucide_flame_off)
                views.setTextViewText(R.id.widget_medium_title_text, "Streak in danger!")
                views.setTextViewText(R.id.widget_medium_subtitle_text, "Log a meal to save it!")
            }

            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }
}
