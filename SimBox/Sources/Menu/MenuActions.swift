import AppKit

@MainActor
enum MenuActions {
    static func copyToPasteboard(_ string: String) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(string, forType: .string)
    }

    static func resetApplicationContainer(at path: String, appTitle: String? = nil) {
        let alert = NSAlert()
        alert.alertStyle = .warning
        alert.messageText = L10n.resetAlertTitle
        let target = appTitle ?? URL(fileURLWithPath: path).lastPathComponent
        alert.informativeText = L10n.resetAlertMessage(target: target)
        alert.addButton(withTitle: L10n.reset)
        alert.addButton(withTitle: L10n.cancel)
        alert.buttons.first?.hasDestructiveAction = true

        // 弹窗前把 app 拉到前台，否则菜单栏应用的 modal 可能不获得焦点。
        NSApp.activate(ignoringOtherApps: true)
        guard alert.runModal() == .alertFirstButtonReturn else {
            return
        }

        let failures = ContainerResetter().reset(containerAt: path)
        guard !failures.isEmpty else {
            return
        }
        let failureAlert = NSAlert()
        failureAlert.alertStyle = .critical
        failureAlert.messageText = L10n.resetFailedTitle
        failureAlert.informativeText = failures
            .prefix(5)
            .map { "\($0.path)\n\($0.error.localizedDescription)" }
            .joined(separator: "\n\n")
        failureAlert.runModal()
    }

    static func showLoginItemError(_ error: Error) {
        let alert = NSAlert(error: error)
        alert.messageText = L10n.loginItemErrorTitle
        NSApp.activate(ignoringOtherApps: true)
        alert.runModal()
    }

    static func openHomepage() {
        NSWorkspace.shared.open(AppConfig.homepageURL)
    }

    /// 点击条目本身：无修饰键用 Finder，⌥ 用 Terminal，⌃ 用 Commander One（若已安装）。
    static func openInPrimaryPlace(path: String) {
        let flags = NSApp.currentEvent?.modifierFlags ?? []
        if flags.contains(.option) {
            ExternalAppLauncher.openInTerminal(path: path)
        } else if flags.contains(.control), ExternalApp.commanderOne.isAvailable {
            ExternalAppLauncher.openInCommanderOne(path: path)
        } else {
            ExternalAppLauncher.openInFinder(path: path)
        }
    }
}
