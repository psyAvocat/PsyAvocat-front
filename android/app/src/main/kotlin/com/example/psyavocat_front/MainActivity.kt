package com.example.psyavocat_front

import android.app.NotificationChannel
import android.app.NotificationManager
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.os.Bundle
import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {

    companion object {
        /** Canal déclaré dans le manifeste (default_notification_channel_id) et utilisé par le serveur. */
        private const val CANAL_NOTIFICATIONS = "high_importance_channel"

        /** Pont avec Flutter : état et réglages des notifications du téléphone. */
        private const val CANAL_FLUTTER = "psyavocat/notifications"
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        creerCanalNotifications()
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CANAL_FLUTTER).setMethodCallHandler { call, result ->
            when (call.method) {
                "areNotificationsEnabled" -> result.success(notificationsAutorisees())
                "openNotificationSettings" -> {
                    ouvrirReglagesNotifications()
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }
    }

    /**
     * Android 8+ : sans canal créé par l'application, les notifications reçues application
     * fermée tombent dans un canal de secours sans priorité. Celui-ci s'affiche en bandeau, avec son.
     */
    private fun creerCanalNotifications() {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return
        val manager = getSystemService(NotificationManager::class.java) ?: return
        val canal = NotificationChannel(
            CANAL_NOTIFICATIONS,
            "Rendez-vous et messages",
            NotificationManager.IMPORTANCE_HIGH
        ).apply {
            description = "Rendez-vous, rappels, messages et suivi de vos dossiers."
        }
        manager.createNotificationChannel(canal)
    }

    private fun notificationsAutorisees(): Boolean {
        val manager = getSystemService(NotificationManager::class.java) ?: return true
        if (!manager.areNotificationsEnabled()) return false
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val canal = manager.getNotificationChannel(CANAL_NOTIFICATIONS)
            if (canal != null && canal.importance == NotificationManager.IMPORTANCE_NONE) return false
        }
        return true
    }

    private fun ouvrirReglagesNotifications() {
        val intent = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            Intent(Settings.ACTION_APP_NOTIFICATION_SETTINGS)
                .putExtra(Settings.EXTRA_APP_PACKAGE, packageName)
        } else {
            Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS, Uri.fromParts("package", packageName, null))
        }
        startActivity(intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK))
    }
}
