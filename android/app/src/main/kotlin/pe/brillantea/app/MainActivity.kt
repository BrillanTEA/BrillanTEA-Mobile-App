package pe.brillantea.app

import android.app.ActivityManager
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "pe.brillantea.app/lock_task"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "startLockTask" -> {
                    try {
                        startLockTask()
                        result.success(true)
                    } catch (e: Exception) {
                        result.error("LOCK_ERROR", e.message, null)
                    }
                }
                "stopLockTask" -> {
                    try {
                        stopLockTask()
                        result.success(true)
                    } catch (e: Exception) {
                        result.error("UNLOCK_ERROR", e.message, null)
                    }
                }
                "isLockTaskActive" -> {
                    try {
                        val am = getSystemService(Context.ACTIVITY_SERVICE) as ActivityManager
                        val isLocked = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                            am.lockTaskModeState != ActivityManager.LOCK_TASK_MODE_NONE
                        } else {
                            @Suppress("DEPRECATION")
                            am.isInLockTaskMode
                        }
                        result.success(isLocked)
                    } catch (e: Exception) {
                        result.success(false)
                    }
                }
                "openSecuritySettings" -> {
                    try {
                        val intent = Intent(Settings.ACTION_SECURITY_SETTINGS)
                        intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                        startActivity(intent)
                        result.success(true)
                    } catch (e: Exception) {
                        result.error("SETTINGS_ERROR", e.message, null)
                    }
                }
                "openAccessibilitySettings" -> {
                    try {
                        val intent = Intent(Settings.ACTION_ACCESSIBILITY_SETTINGS)
                        intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                        startActivity(intent)
                        result.success(true)
                    } catch (e: Exception) {
                        result.error("ACCESSIBILITY_ERROR", e.message, null)
                    }
                }
                "abrirCorreo" -> {
                    // Ayuda y soporte (RF-17): abre la app de correo con el destinatario y el asunto listos
                    try {
                        val para = call.argument<String>("para") ?: ""
                        val asunto = call.argument<String>("asunto") ?: ""
                        val intent = Intent(Intent.ACTION_SENDTO, Uri.parse("mailto:"))
                        intent.putExtra(Intent.EXTRA_EMAIL, para.split(",").map { it.trim() }.filter { it.isNotEmpty() }.toTypedArray())
                        intent.putExtra(Intent.EXTRA_SUBJECT, asunto)
                        intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                        startActivity(Intent.createChooser(intent, "Escribir a soporte").addFlags(Intent.FLAG_ACTIVITY_NEW_TASK))
                        result.success(true)
                    } catch (e: Exception) {
                        result.success(false)
                    }
                }
                else -> result.notImplemented()
            }
        }
    }
}
