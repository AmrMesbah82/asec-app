package com.asec.app

import android.content.pm.ApplicationInfo
import android.os.Build
import android.os.Bundle
import android.os.Debug
import android.provider.Settings
import android.view.WindowManager
import java.io.File
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

/// FLAG_SECURE: Android refuses screenshots of this window, screen
/// recordings and casting show it as black, and the recent-apps thumbnail is
/// blank. Set before the first frame so nothing is ever captured unprotected.
///
/// The super admin can lift it from Settings → Control centre → "Block
/// screenshots": Dart calls `asec/screen_protection` → `setEnabled(bool)`
/// (lib/core/settings/screen_protection.dart).
class MainActivity : FlutterActivity() {
  override fun onCreate(savedInstanceState: Bundle?) {
    window.setFlags(
      WindowManager.LayoutParams.FLAG_SECURE,
      WindowManager.LayoutParams.FLAG_SECURE,
    )
    super.onCreate(savedInstanceState)
  }

  override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
    super.configureFlutterEngine(flutterEngine)
    MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "asec/screen_protection")
      .setMethodCallHandler { call, result ->
        if (call.method == "setEnabled") {
          val on = call.arguments as? Boolean ?: true
          runOnUiThread {
            if (on) {
              window.addFlags(WindowManager.LayoutParams.FLAG_SECURE)
            } else {
              window.clearFlags(WindowManager.LayoutParams.FLAG_SECURE)
            }
          }
          result.success(null)
        } else if (call.method == "integrity") {
          // lib/core/settings/app_integrity.dart — a release build refuses
          // to run while any of these is found.
          result.success(integrityIssues())
        } else {
          result.notImplemented()
        }
      }
  }

  /// What makes this device unsafe for the lessons: developer options, USB
  /// debugging, an attached debugger, a debuggable (re-signed) build, root,
  /// or a hooking framework (Frida / Xposed).
  private fun integrityIssues(): List<String> {
    val issues = mutableListOf<String>()
    val cr = contentResolver
    try {
      if (Settings.Global.getInt(cr, Settings.Global.DEVELOPMENT_SETTINGS_ENABLED, 0) != 0) {
        issues.add("developer_options")
      }
      if (Settings.Global.getInt(cr, Settings.Global.ADB_ENABLED, 0) != 0) {
        issues.add("usb_debugging")
      }
    } catch (_: Throwable) {}
    if (Debug.isDebuggerConnected() || Debug.waitingForDebugger()) issues.add("debugger")
    if ((applicationInfo.flags and ApplicationInfo.FLAG_DEBUGGABLE) != 0) issues.add("debuggable")

    val rootPaths = listOf(
      "/system/bin/su", "/system/xbin/su", "/sbin/su", "/su/bin/su",
      "/data/local/su", "/data/local/xbin/su", "/data/local/bin/su",
      "/system/sd/xbin/su", "/system/app/Superuser.apk", "/data/adb/magisk",
      "/sbin/.magisk", "/system/bin/.ext/su",
    )
    if (rootPaths.any { File(it).exists() } || (Build.TAGS?.contains("test-keys") == true)) {
      issues.add("root")
    }

    val hookPaths = listOf("/data/local/tmp/frida-server", "/data/local/tmp/re.frida.server")
    var hooked = hookPaths.any { File(it).exists() }
    try {
      Class.forName("de.robv.android.xposed.XposedBridge")
      hooked = true
    } catch (_: Throwable) {}
    try {
      File("/proc/self/maps").useLines { lines ->
        if (lines.any { it.contains("frida", true) || it.contains("xposed", true) || it.contains("lsposed", true) }) {
          hooked = true
        }
      }
    } catch (_: Throwable) {}
    if (hooked) issues.add("hooking")
    return issues.distinct()
  }
}
