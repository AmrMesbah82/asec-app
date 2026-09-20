import Cocoa
import FlutterMacOS

// Window sizing ported from manger_plus/macos/Runner/MainFlutterWindow.swift.
class MainFlutterWindow: NSWindow {
  override func awakeFromNib() {
    let flutterViewController = FlutterViewController()

    // OPENING SIZE
    // MainMenu.xib opens at 800x600, which is too small for the admin console
    // (side rail + members table + results charts). Open at a real desktop
    // size instead.
    let defaultSize = NSSize(width: 1440, height: 900)

    // MINIMUM SIZE
    //
    // A Mac running ASEC is the admin console, so a release build keeps room
    // for the rail and a table: 960 x 640.
    //
    // DEBUG builds allow 380 x 480 so the member-side layouts (videos, quiz
    // attempt) can be previewed at phone width without a simulator.
    //
    // `contentMinSize`, not `minSize`: `minSize` includes the title bar, so the
    // number would not be the width Flutter's LayoutBuilder actually sees.
    #if DEBUG
    let minimumContentSize = NSSize(width: 380, height: 480)
    #else
    let minimumContentSize = NSSize(width: 960, height: 640)
    #endif

    var windowFrame = self.frame
    windowFrame.size = defaultSize

    // Centre on whichever screen the window opened on, so it does not start
    // half off-screen on a laptop display.
    if let screen = self.screen ?? NSScreen.main {
      let visible = screen.visibleFrame
      windowFrame.origin = NSPoint(
        x: visible.midX - defaultSize.width / 2,
        y: visible.midY - defaultSize.height / 2
      )
    }

    self.contentViewController = flutterViewController
    self.setFrame(windowFrame, display: true)
    self.contentMinSize = minimumContentSize

    RegisterGeneratedPlugins(registry: flutterViewController)

    super.awakeFromNib()
  }
}
