package com.example.great_sage_mobile

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.Service
import android.content.Intent
import android.graphics.Color
import android.graphics.drawable.GradientDrawable
import android.view.MotionEvent
import android.view.animation.AlphaAnimation
import android.view.animation.Animation
import android.os.Build
import android.os.IBinder
import android.view.Gravity
import android.view.View
import android.view.WindowManager
import android.widget.FrameLayout
import android.widget.TextView

class RaphaelOverlayService : Service() {
    private lateinit var windowManager: WindowManager
    private var overlayView: View? = null
    private var overlayParams: WindowManager.LayoutParams? = null
    private var label: TextView? = null

    override fun onCreate() {
        super.onCreate()
        createNotificationChannel()
        val notification = buildNotification()

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            startForeground(
                1001,
                notification,
                android.content.pm.ServiceInfo.FOREGROUND_SERVICE_TYPE_SPECIAL_USE
            )
        } else {
            startForeground(1001, notification)
        }

        windowManager = getSystemService(WINDOW_SERVICE) as WindowManager

        val size = (96 * resources.displayMetrics.density).toInt()
        val container = FrameLayout(this).apply {
            background = GradientDrawable().apply {
                shape = GradientDrawable.OVAL
                setColor(Color.argb(220, 20, 24, 38))
                setStroke(
                    (2 * resources.displayMetrics.density).toInt(),
                    Color.rgb(124, 99, 255)
                )
            }
            elevation = 12f
            setOnTouchListener(object : View.OnTouchListener {\n                private var downX = 0f\n                private var downY = 0f\n                private var startX = 0\n                private var startY = 0\n                private var moved = false\n\n                override fun onTouch(v: View, event: MotionEvent): Boolean {\n                    val params = overlayParams ?: return false\n                    when (event.actionMasked) {\n                        MotionEvent.ACTION_DOWN -> {\n                            downX = event.rawX\n                            downY = event.rawY\n                            startX = params.x\n                            startY = params.y\n                            moved = false\n                            return true\n                        }\n                        MotionEvent.ACTION_MOVE -> {\n                            val dx = (event.rawX - downX).toInt()\n                            val dy = (event.rawY - downY).toInt()\n                            if (kotlin.math.abs(dx) > 8 || kotlin.math.abs(dy) > 8) moved = true\n                            params.x = startX - dx\n                            params.y = startY + dy\n                            windowManager.updateViewLayout(v, params)\n                            return true\n                        }\n                        MotionEvent.ACTION_UP -> {\n                            if (!moved) {\n                                val launch = packageManager.getLaunchIntentForPackage(packageName)\n                                launch?.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)\n                                if (launch != null) startActivity(launch)\n                            }\n                            return true\n                        }\n                    }\n                    return false\n                }\n            })\n            /* setOnClickListener kept as fallback for accessibility-capable click dispatch. */\n            setOnClickListener {
                val launch = packageManager.getLaunchIntentForPackage(packageName)
                launch?.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                if (launch != null) startActivity(launch)
            }
        }

        val label = TextView(this).apply {
            text = "✦"
            textSize = 34f
            setTextColor(Color.WHITE)
            gravity = Gravity.CENTER
            contentDescription = "Raphael"
        }
        container.addView(
            label,
            FrameLayout.LayoutParams(
                FrameLayout.LayoutParams.MATCH_PARENT,
                FrameLayout.LayoutParams.MATCH_PARENT
            )
        )

        val type = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY
        } else {
            WindowManager.LayoutParams.TYPE_PHONE
        }

        val params = WindowManager.LayoutParams(
            size,
            size,
            type,
            WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE or
                WindowManager.LayoutParams.FLAG_LAYOUT_NO_LIMITS,
            android.graphics.PixelFormat.TRANSLUCENT
        ).apply {
            gravity = Gravity.TOP or Gravity.END
            x = (12 * resources.displayMetrics.density).toInt()
            y = (72 * resources.displayMetrics.density).toInt()
        }

        windowManager.addView(container, params)
        overlayView = container
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {\n        intent?.getStringExtra("mood")?.let { updateMood(it) }\n        return START_STICKY\n    }\n\n    override fun onDestroy() {
        overlayView?.let { windowManager.removeView(it) }
        overlayView = null
        super.onDestroy()
    }

    override fun onBind(intent: Intent?): IBinder? = null\n\n    private fun updateMood(mood: String) {\n        val view = label ?: return\n        val text = when (mood) {\n            "listening" -> "◉"\n            "thinking" -> "…"\n            "speaking" -> "♪"\n            "happy" -> "✦"\n            else -> "✦"\n        }\n        view.text = text\n        view.animate().cancel()\n        if (mood == "thinking" || mood == "speaking" || mood == "listening") {\n            view.animate().scaleX(1.12f).scaleY(1.12f).setDuration(350).withEndAction {\n                view.animate().scaleX(1f).scaleY(1f).setDuration(350).start()\n            }.start()\n        } else {\n            view.scaleX = 1f\n            view.scaleY = 1f\n        }\n    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                "raphael_overlay",
                "Raphael",
                NotificationManager.IMPORTANCE_LOW
            )
            getSystemService(NotificationManager::class.java)
                .createNotificationChannel(channel)
        }
    }

    private fun buildNotification(): Notification {
        val builder = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            Notification.Builder(this, "raphael_overlay")
        } else {
            Notification.Builder(this)
        }
        return builder
            .setContentTitle("GREAT SAGE")
            .setContentText("Raphael está activo")
            .setSmallIcon(android.R.drawable.ic_dialog_info)
            .setOngoing(true)
            .build()
    }
}
