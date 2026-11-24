package com.odaklanmazamani.odaklanma_zamani

import android.app.NotificationManager
import android.content.Context
import android.content.Intent
import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

/**
 * Odak süresince sistemin "Rahatsız Etme" modunu açıp kapatır.
 * Kullanıcının bir kez "Rahatsız Etme erişimi" vermesi gerekir.
 */
class MainActivity : FlutterActivity() {
    private val channelName = "odaklanma_zamani/focus_mode"
    private var previousFilter: Int? = null

    private val notificationManager: NotificationManager
        get() = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName).setMethodCallHandler { call, result ->
            when (call.method) {
                "hasPermission" -> result.success(notificationManager.isNotificationPolicyAccessGranted)
                "openPermissionSettings" -> {
                    startActivity(
                        Intent(Settings.ACTION_NOTIFICATION_POLICY_ACCESS_SETTINGS)
                            .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                    )
                    result.success(null)
                }
                "enable" -> {
                    val nm = notificationManager
                    if (!nm.isNotificationPolicyAccessGranted) {
                        result.success(false)
                    } else {
                        if (previousFilter == null) previousFilter = nm.currentInterruptionFilter
                        // Öncelikli mod: alarmlar ve medya (ortam sesi) çalmaya devam eder.
                        nm.setInterruptionFilter(NotificationManager.INTERRUPTION_FILTER_PRIORITY)
                        result.success(true)
                    }
                }
                "disable" -> {
                    val nm = notificationManager
                    if (nm.isNotificationPolicyAccessGranted) {
                        nm.setInterruptionFilter(previousFilter ?: NotificationManager.INTERRUPTION_FILTER_ALL)
                    }
                    previousFilter = null
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }
    }
}
