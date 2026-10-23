import Flutter
import MachO
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  /// `asec/screen_protection` — see SceneDelegate.swift.
  private var screenChannel: FlutterMethodChannel?

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)

    // The Control centre's "Block screenshots" switch
    // (lib/core/settings/screen_protection.dart) arrives here.
    if let registrar = engineBridge.pluginRegistry.registrar(forPlugin: "AsecScreenProtection") {
      let channel = FlutterMethodChannel(
        name: "asec/screen_protection",
        binaryMessenger: registrar.messenger()
      )
      channel.setMethodCallHandler { call, result in
        if call.method == "setEnabled" {
          let on = (call.arguments as? Bool) ?? true
          DispatchQueue.main.async { AsecScreenProtection.setEnabled(on) }
          result(nil)
        } else if call.method == "integrity" {
          // lib/core/settings/app_integrity.dart
          result(AsecIntegrity.issues())
        } else {
          result(FlutterMethodNotImplemented)
        }
      }
      screenChannel = channel
      AsecScreenProtection.channel = channel
    }
  }
}

/// What makes this device unsafe for the lessons: an attached debugger, a
/// jailbreak, or a hooking framework (Frida, Substrate…) loaded into the app.
/// A release build refuses to run while any is found
/// (lib/core/settings/app_integrity.dart).
enum AsecIntegrity {
  static func issues() -> [String] {
    var out: [String] = []
    if debuggerAttached() { out.append("debugger") }
    #if !targetEnvironment(simulator)
    let paths = [
      "/Applications/Cydia.app", "/Applications/Sileo.app", "/Applications/Zebra.app",
      "/Library/MobileSubstrate/MobileSubstrate.dylib", "/bin/bash", "/usr/sbin/sshd",
      "/etc/apt", "/private/var/lib/apt/", "/var/jb", "/usr/bin/ssh", "/var/binpack",
    ]
    var jailbroken = paths.contains { FileManager.default.fileExists(atPath: $0) }
    let probe = "/private/asec_probe_\(UUID().uuidString).txt"
    if (try? "x".write(toFile: probe, atomically: true, encoding: .utf8)) != nil {
      try? FileManager.default.removeItem(atPath: probe)
      jailbroken = true
    }
    if jailbroken { out.append("jailbreak") }
    #endif
    let suspicious = ["frida", "cynject", "libcycript", "mobilesubstrate", "substitute", "libhooker", "sslkillswitch"]
    for i in 0..<_dyld_image_count() {
      guard let raw = _dyld_get_image_name(i) else { continue }
      let name = String(cString: raw).lowercased()
      if suspicious.contains(where: { name.contains($0) }) {
        out.append("hooking")
        break
      }
    }
    return out
  }

  static func debuggerAttached() -> Bool {
    var info = kinfo_proc()
    var mib: [Int32] = [CTL_KERN, KERN_PROC, KERN_PROC_PID, getpid()]
    var size = MemoryLayout<kinfo_proc>.stride
    let rc = sysctl(&mib, UInt32(mib.count), &info, &size, nil, 0)
    return rc == 0 && (info.kp_proc.p_flag & P_TRACED) != 0
  }
}
