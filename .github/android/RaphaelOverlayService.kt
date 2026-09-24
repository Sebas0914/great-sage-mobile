package com.example.great_sage_mobile

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.Service
import android.content.Intent
import android.content.SharedPreferences
import android.graphics.Color
import android.graphics.drawable.GradientDrawable
import android.os.Build
import android.os.IBinder
import android.view.Gravity
import android.view.MotionEvent
import android.view.View
import android.view.WindowManager
import android.widget.FrameLayout
import android.widget.ImageView

class RaphaelOverlayService : Service() {
    companion object {
        const val ACTION_START_LISTENING = "com.example.great_sage_mobile.START_LISTENING"
        private const val PREFS = "raphael_overlay"
        private const val KEY_X = "x"
        private const val KEY_Y = "y"
    }

    private lateinit var windowManager: WindowManager
    private var overlayView: View? = null
    private var overlayParams: WindowManager.LayoutParams? = null
    private var iconView: ImageView? = null
    private var core: View? = null
    private lateinit var prefs: SharedPreferences

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
        prefs = getSharedPreferences(PREFS, MODE_PRIVATE)

        val density = resources.displayMetrics.density
        val size = (76 * density).toInt()
        val margin = (8 * density).toInt()

        val container = FrameLayout(this).apply {
            background = GradientDrawable().apply {
                shape = GradientDrawable.OVAL
                setColor(Color.argb(238, 7, 10, 16))
                setStroke((1.5f * density).toInt(), Color.rgb(124, 99, 255))
            }
            elevation = 10f
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
                            params.x = (startX + dx).coerceIn(margin, screenWidth() - size - margin)
                            params.y = (startY + dy).coerceIn(margin, screenHeight() - size - margin)
                            windowManager.updateViewLayout(v, params)
                            return true
                        }
                        MotionEvent.ACTION_UP -> {
                            if (moved) {
                                val center = params.x + size / 2
                                val targetX = if (center < screenWidth() / 2) {
                                    margin
                                } else {
                                    screenWidth() - size - margin
                                }
                                params.x = targetX.coerceIn(margin, screenWidth() - size - margin)
                                params.y = params.y.coerceIn(margin, screenHeight() - size - margin)
                                prefs.edit().putInt(KEY_X, params.x).putInt(KEY_Y, params.y).apply()
                                windowManager.updateViewLayout(v, params)
                            } else {
                                val launch = Intent(this@RaphaelOverlayService, MainActivity::class.java).apply {
                                    action = ACTION_START_LISTENING
                                    addFlags(
                                        Intent.FLAG_ACTIVITY_NEW_TASK or
                                            Intent.FLAG_ACTIVITY_SINGLE_TOP or
                                            Intent.FLAG_ACTIVITY_CLEAR_TOP
                                    )
                                }
                                startActivity(launch)
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
                setStroke((1.5f * density).toInt(), Color.rgb(72, 216, 255))
            }
            alpha = 0.5f
        }
        container.addView(
            ring,
            FrameLayout.LayoutParams(
                (58 * density).toInt(),
                (58 * density).toInt(),
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
                (50 * density).toInt(),
                (50 * density).toInt(),
                Gravity.CENTER
            )
        )

        val icon = ImageView(this).apply {
            setImageResource(R.drawable.great_sage_icon)
            scaleType = ImageView.ScaleType.CENTER_INSIDE
            contentDescription = "Raphael"
            setPadding((5 * density).toInt(), (5 * density).toInt(), (5 * density).toInt(), (5 * density).toInt())
        }
        inner.addView(
            icon,
            FrameLayout.LayoutParams(
                FrameLayout.LayoutParams.MATCH_PARENT,
                FrameLayout.LayoutParams.MATCH_PARENT
            )
        )

        iconView = icon
        core = inner

        val type = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY
        } else {
            WindowManager.LayoutParams.TYPE_PHONE
        }

        val screen = resources.displayMetrics
        val defaultX = screen.widthPixels - size - margin
        val savedX = prefs.getInt(KEY_X, defaultX)
        val savedY = prefs.getInt(KEY_Y, (72 * density).toInt())

        val params = WindowManager.LayoutParams(
            size,
            size,
            type,
            WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE,
            android.graphics.PixelFormat.TRANSLUCENT
        ).apply {
            gravity = Gravity.TOP or Gravity.START
            x = savedX.coerceIn(margin, screen.widthPixels - size - margin)
            y = savedY.coerceIn(margin, screen.heightPixels - size - margin)
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
        iconView = null
        core = null
        super.onDestroy()
    }

    override fun onBind(intent: Intent?): IBinder? = null

    private fun screenWidth(): Int = resources.displayMetrics.widthPixels
    private fun screenHeight(): Int = resources.displayMetrics.heightPixels

    private fun updateMood(mood: String) {
        val inner = core ?: return
        val color = when (mood) {
            "listening" -> Color.rgb(72, 216, 255)
            "thinking" -> Color.rgb(156, 140, 255)
            "speaking" -> Color.rgb(124, 255, 178)
            "happy" -> Color.rgb(255, 215, 106)
            else -> Color.rgb(140, 131, 255)
        }

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
            .scaleX(1.08f)
            .scaleY(1.08f)
            .alpha(0.86f)
            .setDuration(280)
            .withEndAction {
                inner.animate()
                    .scaleX(1f)
                    .scaleY(1f)
                    .alpha(1f)
                    .setDuration(280)
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
