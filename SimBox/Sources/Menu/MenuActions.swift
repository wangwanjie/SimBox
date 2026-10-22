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
        alert.messageText = "重置应用沙盒？"
        let target = appTitle ?? URL(fileURLWithPath: path).lastPathComponent
        alert.informativeText = """
        将清空 \(target) 容器内 Documents / Library / tmp 等目录中的全部数据，操作不可撤销。
        请确认此模拟器上的这个 app 已退出，否则可能残留数据。
        """
        alert.addButton(withTitle: "重置")
        alert.addButton(withTitle: "取消")
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
        failureAlert.messageText = "部分数据未能删除"
        failureAlert.informativeText = failures
            .prefix(5)
            .map { "\($0.path)\n\($0.error.localizedDescription)" }
            .joined(separator: "\n\n")
        failureAlert.runModal()
    }

    static func showLoginItemError(_ error: Error) {
        let alert = NSAlert(error: error)
        alert.messageText = "无法修改开机自启设置"
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
