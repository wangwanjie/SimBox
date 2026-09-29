import AppKit

@MainActor
enum MenuActions {
    static func copyToPasteboard(_ path: String) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(path, forType: .string)
    }

    static func resetApplicationContainer(at path: String, appTitle: String? = nil) {
        let alert = NSAlert()
        alert.alertStyle = .warning
        alert.messageText = "重置应用沙盒？"
        let target = appTitle ?? URL(fileURLWithPath: path).lastPathComponent
        alert.informativeText = """
        将删除 \(target) 的 Documents / Library / tmp 目录，操作不可撤销。
        请确认此模拟器上的这个 app 已退出，否则可能残留数据。
        """
        alert.addButton(withTitle: "重置")
        alert.addButton(withTitle: "取消")
        alert.buttons.first?.hasDestructiveAction = true

        // 弹窗前把 app 拉到前台，否则菜单栏应用的 modal 可能不获得焦点。
        NSApp.activate(ignoringOtherApps: true)
        let response = alert.runModal()
        guard response == .alertFirstButtonReturn else { return }

        let fm = FileManager()
        for subfolder in ["Documents", "Library", "tmp"] {
            let url = URL(fileURLWithPath: path).appendingPathComponent(subfolder)
            try? fm.removeItem(at: url)
        }
    }

    static func openHomepage() {
        NSWorkspace.shared.open(AppConfig.homepageURL)
    }

    static func openInPrimaryPlace(path: String) {
        guard let event = NSApp.currentEvent else {
            ExternalAppLauncher.openInFinder(path: path)
            return
        }
        if event.modifierFlags.contains(.option) {
            ExternalAppLauncher.openInTerminal(path: path)
        } else if event.modifierFlags.contains(.control), ExternalAppLauncher.isCommanderOneAvailable {
            ExternalAppLauncher.openInCommanderOne(path: path)
        } else {
            ExternalAppLauncher.openInFinder(path: path)
        }
    }
}
