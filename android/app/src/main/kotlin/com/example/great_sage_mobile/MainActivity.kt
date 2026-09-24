package com.example.great_sage_mobile

import android.content.Intent
import android.net.Uri
import android.os.Build
import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val channelName = "great_sage_mobile/overlay"

    companion object {
        private var overlayChannel: MethodChannel? = null

        fun notifyOverlayTap() {
            overlayChannel?.invokeMethod("overlayStartListening", null)
        }
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        val channel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName)
        overlayChannel = channel
        channel.setMethodCallHandler { call, result ->
                when (call.method) {
                    "isSupported" -> result.success(true)
                    "hasPermission" -> result.success(
                        Build.VERSION.SDK_INT < Build.VERSION_CODES.M || Settings.canDrawOverlays(this)
                    )
                    "requestPermission" -> {
                        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.M) {
                            result.success(true)
                        } else {
                            startActivity(
                                Intent(
                                    Settings.ACTION_MANAGE_OVERLAY_PERMISSION,
                                    Uri.parse("package:$packageName")
                                )
                            )
                            result.success(true)
                        }
                    }
                    "setSubtitle" -> {
                        val subtitle = call.arguments as? String ?: ""
                        val intent = Intent(this, RaphaelOverlayService::class.java)
                        intent.putExtra("subtitle", subtitle)
                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) startForegroundService(intent) else startService(intent)
                        result.success(true)
                    }
                    "setMood" -> {
                        val mood = call.arguments as? String ?: "neutral"
                        val intent = Intent(this, RaphaelOverlayService::class.java)
                        intent.putExtra("mood", mood)
                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                            startForegroundService(intent)
                        } else {
                            startService(intent)
                        }
                        result.success(true)
                    }
                    "show" -> {
                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M &&
                            !Settings.canDrawOverlays(this)
                        ) {
                            result.error("NO_PERMISSION", "Permiso de superposición no concedido.", null)
                        } else {
                            val intent = Intent(this, RaphaelOverlayService::class.java)
                            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                                startForegroundService(intent)
                            } else {
                                startService(intent)
                            }
                            result.success(true)
                        }
                    }
                    "hide" -> {
                        stopService(Intent(this, RaphaelOverlayService::class.java))
                        result.success(true)
                    }
                    else -> result.notImplemented()
                }
            }
    }

    override fun onDestroy() {
        overlayChannel = null
        super.onDestroy()
    }
}
