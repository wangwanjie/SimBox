import AppKit

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusMenuController: StatusMenuController?

    /// 单元测试以 SimBox.app 为宿主运行，此时不创建菜单栏图标、不启动 Sparkle。
    private static var isRunningUnitTests: Bool {
        ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] != nil
            || NSClassFromString("XCTestCase") != nil
    }

    func applicationDidFinishLaunching(_: Notification) {
        NSApp.setActivationPolicy(.accessory)
        guard !Self.isRunningUnitTests else {
            return
        }

        let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        statusItem.isVisible = true
        statusItem.behavior = []
        statusItem.autosaveName = "cn.vanjay.SimBox.status"

        statusMenuController = StatusMenuController(statusItem: statusItem)

        #if DEBUG
            if UserDefaults.standard.bool(forKey: "SimBoxScreenshotMode") {
                showScreenshotStage()
                return
            }
        #endif

        _ = UpdateManager.shared
    }

    #if DEBUG
        private var screenshotWindow: NSWindow?

        /// `-SimBoxScreenshotMode YES` 启动时，用纯色背景盖住屏幕并弹出菜单，便于截取 README 配图。
        private func showScreenshotStage() {
            guard let screen = NSScreen.main, let controller = statusMenuController else {
                return
            }
            // 背景铺满整屏，截图时再按菜单范围裁剪，避免露出桌面上的其他内容。
            let frame = screen.frame
            let window = NSWindow(contentRect: frame, styleMask: [.borderless], backing: .buffered, defer: false)
            window.title = "SimBoxScreenshotStage"
            window.backgroundColor = NSColor(calibratedRed: 0.16, green: 0.18, blue: 0.24, alpha: 1)
            window.level = .floating
            window.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            screenshotWindow = window

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                guard let contentView = window.contentView else {
                    return
                }
                controller.popUpMenu(in: contentView, at: NSPoint(x: frame.width * 0.3, y: frame.height * 0.75))
            }
        }
    #endif

    func applicationSupportsSecureRestorableState(_: NSApplication) -> Bool {
        true
    }
}
