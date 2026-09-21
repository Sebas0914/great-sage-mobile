package com.example.great_sage_mobile

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.Service
import android.content.Intent
import android.graphics.Color
import android.graphics.drawable.GradientDrawable
import android.os.Build
import android.os.IBinder
import android.view.Gravity
import android.view.MotionEvent
import android.view.View
import android.view.WindowManager
import android.widget.FrameLayout
import android.widget.TextView

class RaphaelOverlayService : Service() {
    private lateinit var windowManager: WindowManager
    private var overlayView: View? = null
    private var overlayParams: WindowManager.LayoutParams? = null
    private var label: TextView? = null
    private var core: View? = null

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

        val density = resources.displayMetrics.density
        val size = (104 * density).toInt()

        val container = FrameLayout(this).apply {
            background = GradientDrawable().apply {
                shape = GradientDrawable.OVAL
                setColor(Color.argb(235, 8, 12, 24))
                setStroke((2 * density).toInt(), Color.rgb(124, 99, 255))
            }
            elevation = 16f
            setOnTouchListener(object : View.OnTouchListener {
                private var downX = 0f
                private var downY = 0f
                private var startX = 0
                private var startY = 0
                private var moved = false

                override fun onTouch(v: View, event: MotionEvent): Boolean {
                    val params = overlayParams ?: return false
                    when (event.actionMasked) {
                        MotionEvent.ACTION_DOWN -> {
                            downX = event.rawX
                            downY = event.rawY
                            startX = params.x
                            startY = params.y
                            moved = false
                            return true
                        }
                        MotionEvent.ACTION_MOVE -> {
                            val dx = (event.rawX - downX).toInt()
                            val dy = (event.rawY - downY).toInt()
                            if (kotlin.math.abs(dx) > 8 || kotlin.math.abs(dy) > 8) moved = true
                            params.x = startX - dx
                            params.y = startY + dy
                            windowManager.updateViewLayout(v, params)
                            return true
                        }
                        MotionEvent.ACTION_UP -> {
                            if (!moved) {
                                val launch = packageManager.getLaunchIntentForPackage(packageName)
                                launch?.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                                if (launch != null) startActivity(launch)
                            }
                            return true
                        }
                    }
                    return false
                }
            })
        }

        val ring = View(this).apply {
            background = GradientDrawable().apply {
                shape = GradientDrawable.OVAL
                setColor(Color.TRANSPARENT)
                setStroke((2 * density).toInt(), Color.rgb(72, 216, 255))
            }
            alpha = 0.55f
        }
        container.addView(
            ring,
            FrameLayout.LayoutParams(
                (78 * density).toInt(),
                (78 * density).toInt(),
                Gravity.CENTER
            )
        )

        val inner = FrameLayout(this).apply {
            background = GradientDrawable().apply {
                shape = GradientDrawable.OVAL
                setColor(Color.rgb(16, 20, 38))
                setStroke((1 * density).toInt(), Color.rgb(156, 140, 255))
            }
        }
        container.addView(
            inner,
            FrameLayout.LayoutParams(
                (60 * density).toInt(),
                (60 * density).toInt(),
                Gravity.CENTER
            )
        )

        val labelView = TextView(this).apply {
            text = "✦"
            textSize = 27f
            setTextColor(Color.WHITE)
            gravity = Gravity.CENTER
            contentDescription = "Raphael"
        }
        inner.addView(
            labelView,
            FrameLayout.LayoutParams(
                FrameLayout.LayoutParams.MATCH_PARENT,
                FrameLayout.LayoutParams.MATCH_PARENT
            )
        )

        label = labelView
        core = inner

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
            x = (12 * density).toInt()
            y = (72 * density).toInt()
        }

        overlayParams = params
        windowManager.addView(container, params)
        overlayView = container
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        intent?.getStringExtra("mood")?.let { updateMood(it) }
        return START_STICKY
    }

    override fun onDestroy() {
        overlayView?.let { windowManager.removeView(it) }
        overlayView = null
        overlayParams = null
        label = null
        core = null
        super.onDestroy()
    }

    override fun onBind(intent: Intent?): IBinder? = null

    private fun updateMood(mood: String) {
        val view = label ?: return
        val inner = core ?: return

        val (symbol, color) = when (mood) {
            "listening" -> "◉" to Color.rgb(72, 216, 255)
            "thinking" -> "…" to Color.rgb(156, 140, 255)
            "speaking" -> "≈" to Color.rgb(124, 255, 178)
            "happy" -> "✦" to Color.rgb(255, 215, 106)
            else -> "✦" to Color.rgb(140, 131, 255)
        }

        view.text = symbol
        view.setTextColor(color)

        (inner.background as? GradientDrawable)?.setStroke(
            (1 * resources.displayMetrics.density).toInt(),
            color
        )

        inner.animate().cancel()
        if (mood == "neutral") {
            inner.scaleX = 1f
            inner.scaleY = 1f
            inner.alpha = 1f
            return
        }

        inner.animate()
            .scaleX(1.12f)
            .scaleY(1.12f)
            .alpha(0.82f)
            .setDuration(320)
            .withEndAction {
                inner.animate()
                    .scaleX(1f)
                    .scaleY(1f)
                    .alpha(1f)
                    .setDuration(320)
                    .start()
            }
            .start()
    }

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
