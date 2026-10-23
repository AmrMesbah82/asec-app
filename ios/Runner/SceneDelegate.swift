import Flutter
import UIKit

/// SCREEN CAPTURE PROTECTION (iOS)
///
/// iOS has no public switch that blocks screenshots, so two layers are used:
///
/// 1. The window's layer is re-parented inside the secure container of a
///    password field (`isSecureTextEntry`). iOS leaves secure content out of
///    screenshots and screen recordings, so the app captures as black.
/// 2. Fallback for recording / AirPlay mirroring: while `UIScreen.isCaptured`
///    is true a black cover sits over the whole window.
///
/// Both follow `AsecScreenProtection.enabled` — the super admin's Control
/// centre switch "Block screenshots", sent from Dart through AppDelegate.
/// Switched off, the secure field stops being secure (captures show the app)
/// and the recording cover is not drawn.
enum AsecScreenProtection {
  static let changed = Notification.Name("AsecScreenProtectionChanged")
  private(set) static var enabled = true

  static func setEnabled(_ on: Bool) {
    guard on != enabled else { return }
    enabled = on
    NotificationCenter.default.post(name: changed, object: nil)
  }

  /// Set by AppDelegate. Screen capture alerts go back to Dart as
  /// `captured("screenshot" | "recording")`, which saves them for the admin.
  static var channel: FlutterMethodChannel?

  static func report(_ type: String) {
    DispatchQueue.main.async { channel?.invokeMethod("captured", arguments: type) }
  }
}

class SceneDelegate: FlutterSceneDelegate {
  private var didSecure = false
  private var captureCover: UIView?
  private var secureField: UITextField?
  private var wasCaptured = false

  override func sceneDidBecomeActive(_ scene: UIScene) {
    super.sceneDidBecomeActive(scene)
    guard let window = self.window else { return }

    if !didSecure {
      didSecure = secure(window)
      NotificationCenter.default.addObserver(
        self,
        selector: #selector(captureChanged),
        name: UIScreen.capturedDidChangeNotification,
        object: nil
      )
      NotificationCenter.default.addObserver(
        self,
        selector: #selector(protectionChanged),
        name: AsecScreenProtection.changed,
        object: nil
      )
      NotificationCenter.default.addObserver(
        self,
        selector: #selector(screenshotTaken),
        name: UIApplication.userDidTakeScreenshotNotification,
        object: nil
      )
    }
    protectionChanged()
  }

  /// Returns false when the window is not in a layer tree yet; the next
  /// `sceneDidBecomeActive` tries again.
  private func secure(_ window: UIWindow) -> Bool {
    guard let parent = window.layer.superlayer else { return false }
    let field = UITextField()
    // Always created secure, so its secure container exists to be found;
    // the switch's real state is applied right after.
    field.isSecureTextEntry = true
    field.isUserInteractionEnabled = false
    // The field must cover the WHOLE window at (0, 0): the window's layer is
    // drawn inside the field's secure container, so the container's origin is
    // where the app starts. A centred, zero-size field put that origin in the
    // middle of the screen and pushed the app down and to the right.
    field.translatesAutoresizingMaskIntoConstraints = true
    field.frame = window.bounds
    field.autoresizingMask = [.flexibleWidth, .flexibleHeight]
    window.addSubview(field)
    parent.addSublayer(field.layer)
    field.layoutIfNeeded()
    // The secure container is the last sublayer on iOS 17+, the first before.
    let container: CALayer?
    if #available(iOS 17.0, *) {
      container = field.layer.sublayers?.last
    } else {
      container = field.layer.sublayers?.first
    }
    guard let secureLayer = container else { return false }
    secureLayer.frame = field.bounds
    secureLayer.addSublayer(window.layer)
    window.layer.position = CGPoint(x: window.bounds.midX, y: window.bounds.midY)
    secureField = field
    field.isSecureTextEntry = AsecScreenProtection.enabled
    return true
  }

  @objc private func protectionChanged() {
    secureField?.isSecureTextEntry = AsecScreenProtection.enabled
    captureChanged()
  }

  @objc private func screenshotTaken() {
    AsecScreenProtection.report("screenshot")
  }

  @objc private func captureChanged() {
    guard let window = self.window else { return }
    let captured = window.windowScene?.screen.isCaptured ?? UIScreen.main.isCaptured
    // Recording (or mirroring) just started → tell the admin, once.
    if captured && !wasCaptured { AsecScreenProtection.report("recording") }
    wasCaptured = captured
    if captured && AsecScreenProtection.enabled {
      if captureCover == nil {
        let cover = UIView(frame: window.bounds)
        cover.backgroundColor = .black
        cover.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        window.addSubview(cover)
        captureCover = cover
      }
      if let cover = captureCover { window.bringSubviewToFront(cover) }
    } else {
      captureCover?.removeFromSuperview()
      captureCover = nil
    }
  }
}
