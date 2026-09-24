package com.example.great_sage_mobile

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.Service
import android.content.Intent
import android.graphics.Color
import android.graphics.drawable.GradientDrawable
import android.os.Build
import android.os.Handler
import android.os.IBinder
import android.os.Looper
import android.view.Gravity
import android.view.MotionEvent
import android.view.View
import android.view.WindowManager
import android.widget.FrameLayout
import android.widget.ImageView
import android.widget.TextView
import kotlin.math.abs

class RaphaelOverlayService : Service() {
    private lateinit var windowManager: WindowManager
    private var overlayView: View? = null
    private var overlayParams: WindowManager.LayoutParams? = null
    private var iconView: ImageView? = null
    private var core: View? = null
    private var subtitle: TextView? = null
    private val handler = Handler(Looper.getMainLooper())
    private var longPressRunnable: Runnable? = null

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
                private var lastTime = 0L
                private var lastX = 0f
                private var lastY = 0f

                override fun onTouch(v: View, event: MotionEvent): Boolean {
                    val params = overlayParams ?: return false
                    when (event.actionMasked) {
                        MotionEvent.ACTION_DOWN -> {
                            downX = event.rawX
                            downY = event.rawY
                            startX = params.x
                            startY = params.y
                            lastX = event.rawX
                            lastY = event.rawY
                            lastTime = System.currentTimeMillis()
                            moved = false
                            longPressRunnable?.let(handler::removeCallbacks)
                            longPressRunnable = Runnable {
                                updateMood("happy")
                                MainActivity.notifyOverlayTap()
                            }.also { handler.postDelayed(it, 650) }
                            return true
                        }
                        MotionEvent.ACTION_MOVE -> {
                            val now = System.currentTimeMillis()
                            val dx = event.rawX - downX
                            val dy = event.rawY - downY
                            val dt = (now - lastTime).coerceAtLeast(1L)
                            val speed = (abs(event.rawX - lastX) + abs(event.rawY - lastY)) / dt
                            if (abs(dx) > 8 || abs(dy) > 8) {
                                moved = true
                                longPressRunnable?.let(handler::removeCallbacks)
                                if (speed > 2.5f) {
                                    updateMood("thinking")
                                } else if (speed > 0.15f) {
                                    updateMood("happy")
                                }
                            }
                            params.x = startX - dx.toInt()
                            params.y = startY + dy.toInt()
                            windowManager.updateViewLayout(v, params)
                            lastTime = now
                            lastX = event.rawX
                            lastY = event.rawY
                            return true
                        }
                        MotionEvent.ACTION_UP, MotionEvent.ACTION_CANCEL -> {
                            longPressRunnable?.let(handler::removeCallbacks)
                            longPressRunnable = null
                            if (!moved && event.actionMasked == MotionEvent.ACTION_UP) {
                                MainActivity.notifyOverlayTap()
                            } else {
                                handler.postDelayed({ updateMood("neutral") }, 700)
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
        container.addView(ring, FrameLayout.LayoutParams(
            (78 * density).toInt(), (78 * density).toInt(), Gravity.CENTER
        ))

        val inner = FrameLayout(this).apply {
            background = GradientDrawable().apply {
                shape = GradientDrawable.OVAL
                setColor(Color.rgb(16, 20, 38))
                setStroke((1 * density).toInt(), Color.rgb(156, 140, 255))
            }
        }
        container.addView(inner, FrameLayout.LayoutParams(
            (60 * density).toInt(), (60 * density).toInt(), Gravity.CENTER
        ))

        val icon = ImageView(this).apply {
            setImageResource(R.drawable.great_sage_icon)
            scaleType = ImageView.ScaleType.CENTER_INSIDE
            contentDescription = "Raphael"
            setPadding((7 * density).toInt(), (7 * density).toInt(), (7 * density).toInt(), (7 * density).toInt())
        }
        inner.addView(icon, FrameLayout.LayoutParams(
            FrameLayout.LayoutParams.MATCH_PARENT,
            FrameLayout.LayoutParams.MATCH_PARENT
        ))

        iconView = icon
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

        val subtitleView = TextView(this).apply {
            textSize = 17f
            setTextColor(Color.WHITE)
            gravity = Gravity.CENTER
            setPadding((16 * density).toInt(), (10 * density).toInt(), (16 * density).toInt(), (10 * density).toInt())
            background = GradientDrawable().apply {
                cornerRadius = 14f * density
                setColor(Color.argb(205, 35, 37, 42))
            }
            visibility = View.GONE
        }
        val subtitleParams = WindowManager.LayoutParams(
            WindowManager.LayoutParams.MATCH_PARENT,
            WindowManager.LayoutParams.WRAP_CONTENT,
            type,
            WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE or
                WindowManager.LayoutParams.FLAG_LAYOUT_NO_LIMITS,
            android.graphics.PixelFormat.TRANSLUCENT
        ).apply {
            gravity = Gravity.BOTTOM
            x = (18 * density).toInt()
            y = (28 * density).toInt()
        }
        windowManager.addView(subtitleView, subtitleParams)
        subtitle = subtitleView
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        intent?.getStringExtra("mood")?.let { updateMood(it) }
        intent?.getStringExtra("subtitle")?.let { updateSubtitle(it) }
        return START_STICKY
    }

    override fun onDestroy() {
        longPressRunnable?.let(handler::removeCallbacks)
        overlayView?.let { windowManager.removeView(it) }
        subtitle?.let { windowManager.removeView(it) }
        overlayView = null
        overlayParams = null
        subtitle = null
        iconView = null
        core = null
        super.onDestroy()
    }

    override fun onBind(intent: Intent?): IBinder? = null

    private fun updateSubtitle(text: String) {
        val view = subtitle ?: return
        view.text = text
        view.visibility = if (text.isBlank()) View.GONE else View.VISIBLE
    }

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
            (1 * resources.displayMetrics.density).toInt(), color
        )
        inner.animate().cancel()
        if (mood == "neutral") {
            inner.scaleX = 1f
            inner.scaleY = 1f
            inner.alpha = 1f
            return
        }
        inner.animate()
            .scaleX(if (mood == "happy") 1.16f else 1.10f)
            .scaleY(if (mood == "happy") 1.16f else 1.10f)
            .alpha(0.86f)
            .setDuration(220)
            .withEndAction {
                inner.animate().scaleX(1f).scaleY(1f).alpha(1f).setDuration(220).start()
            }.start()
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                "raphael_overlay", "Raphael", NotificationManager.IMPORTANCE_LOW
            )
            getSystemService(NotificationManager::class.java).createNotificationChannel(channel)
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
