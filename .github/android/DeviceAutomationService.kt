package com.example.great_sage_mobile

import android.accessibilityservice.AccessibilityService
import android.accessibilityservice.GestureDescription
import android.content.Intent
import android.graphics.Path
import android.os.Handler
import android.os.Looper
import android.view.accessibility.AccessibilityNodeInfo
import org.json.JSONArray
import org.json.JSONObject

class DeviceAutomationService : AccessibilityService() {
    companion object {
        var instance: DeviceAutomationService? = null
    }

    private val handler = Handler(Looper.getMainLooper())

    override fun onServiceConnected() {
        super.onServiceConnected()
        instance = this
    }

    override fun onDestroy() {
        instance = null
        super.onDestroy()
    }

    override fun onAccessibilityEvent(event: android.view.accessibility.AccessibilityEvent?) {}
    override fun onInterrupt() {}

    fun executePlan(json: String, callback: (Boolean) -> Unit) {
        try {
            val actions = JSONObject(json).getJSONArray("actions")
            executeAt(actions, 0, callback)
        } catch (_: Exception) {
            callback(false)
        }
    }

    private fun executeAt(actions: JSONArray, index: Int, callback: (Boolean) -> Unit) {
        if (index >= actions.length()) {
            callback(true)
            return
        }
        val action = actions.optJSONObject(index) ?: run {
            callback(false)
            return
        }
        val type = action.optString("type")
        val ok = when (type) {
            "open_app" -> openApp(action.optString("package"))
            "tap_text" -> findByText(action.optString("text"))?.performAction(AccessibilityNodeInfo.ACTION_CLICK) == true
            "tap_description" -> findByDescription(action.optString("text"))?.performAction(AccessibilityNodeInfo.ACTION_CLICK) == true
            "type_text" -> {
                val node = rootInActiveWindow?.findFocus(AccessibilityNodeInfo.FOCUS_INPUT)
                    ?: findEditable(rootInActiveWindow)
                node?.performAction(
                    AccessibilityNodeInfo.ACTION_SET_TEXT,
                    android.os.Bundle().apply {
                        putCharSequence(
                            AccessibilityNodeInfo.ACTION_ARGUMENT_SET_TEXT_CHARSEQUENCE,
                            action.optString("text")
                        )
                    }
                ) == true
            }
            "back" -> performGlobalAction(GLOBAL_ACTION_BACK)
            "home" -> performGlobalAction(GLOBAL_ACTION_HOME)
            "swipe" -> swipe(action.optString("direction"))
            else -> false
        }
        if (!ok) {
            callback(false)
            return
        }
        handler.postDelayed({ executeAt(actions, index + 1, callback) }, 450)
    }

    private fun openApp(packageName: String): Boolean {
        if (packageName.isBlank()) return false
        val intent = packageManager.getLaunchIntentForPackage(packageName) ?: return false
        intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        startActivity(intent)
        return true
    }

    private fun findByText(text: String): AccessibilityNodeInfo? =
        rootInActiveWindow?.findAccessibilityNodeInfosByText(text)?.firstOrNull { it.isVisibleToUser }

    private fun findByDescription(text: String): AccessibilityNodeInfo? =
        findNode(rootInActiveWindow) { it.contentDescription?.toString()?.equals(text, ignoreCase = true) == true }

    private fun findEditable(node: AccessibilityNodeInfo?): AccessibilityNodeInfo? =
        findNode(node) { it.isEditable }

    private fun findNode(node: AccessibilityNodeInfo?, predicate: (AccessibilityNodeInfo) -> Boolean): AccessibilityNodeInfo? {
        if (node == null) return null
        if (predicate(node)) return node
        for (i in 0 until node.childCount) {
            findNode(node.getChild(i), predicate)?.let { return it }
        }
        return null
    }

    private fun swipe(direction: String): Boolean {
        if (android.os.Build.VERSION.SDK_INT < 24) return false
        val w = resources.displayMetrics.widthPixels.toFloat()
        val h = resources.displayMetrics.heightPixels.toFloat()
        val path = Path()
        val (sx, sy, ex, ey) = when (direction.lowercase()) {
            "up" -> floatArrayOf(w / 2, h * .75f, w / 2, h * .25f)
            "down" -> floatArrayOf(w / 2, h * .25f, w / 2, h * .75f)
            "left" -> floatArrayOf(w * .75f, h / 2, w * .25f, h / 2)
            else -> floatArrayOf(w * .25f, h / 2, w * .75f, h / 2)
        }
        path.moveTo(sx, sy)
        path.lineTo(ex, ey)
        return dispatchGesture(
            GestureDescription.Builder()
                .addStroke(GestureDescription.StrokeDescription(path, 0, 500))
                .build(),
            null,
            null
        )
    }
}
