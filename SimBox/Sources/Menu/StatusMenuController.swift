import AppKit

@MainActor
final class StatusMenuController: NSObject {
    private let statusItem: NSStatusItem
    private let service: SimulatorService
    private lazy var menu: NSMenu = {
        let menu = NSMenu()
        menu.autoenablesItems = false
        menu.delegate = self
        return menu
    }()

    init(statusItem: NSStatusItem, service: SimulatorService = .shared) {
        self.statusItem = statusItem
        self.service = service
        super.init()
        statusItem.menu = menu
        configureStatusButton()
    }

    #if DEBUG
        /// 仅用于生成 README 截图：在指定窗口内弹出与菜单栏完全相同的菜单。
        func popUpMenu(in view: NSView, at point: NSPoint) {
            menu.popUp(positioning: nil, at: point, in: view)
        }
    #endif

    private func configureStatusButton() {
        guard let button = statusItem.button else {
            NSLog("[SimBox] statusItem.button is nil — cannot show menu bar icon")
            return
        }
        let image = NSImage(named: "MenuBarIcon")
            ?? NSImage(systemSymbolName: "iphone.gen3", accessibilityDescription: "SimBox")
            ?? NSImage(systemSymbolName: "iphone", accessibilityDescription: "SimBox")
        image?.isTemplate = true
        image?.size = NSSize(width: 18, height: 18)
        button.image = image
        button.imagePosition = .imageOnly
        button.toolTip = L10n.statusItemToolTip
    }

    private func rebuildMenu() {
        menu.removeAllItems()

        // 先按排序挑出前 N 台确实有用户内容的模拟器直接展开；只装了系统 app 的会被跳过，
        // 不再占用名额。剩余模拟器收进 “More Simulators”，展开时才扫描。
        var shown: [SimulatorContent] = []
        var overflow: [Simulator] = []
        for simulator in service.activeSimulators() {
            if shown.count >= AppConfig.maxRecentSimulators {
                overflow.append(simulator)
                continue
            }
            let content = service.content(of: simulator)
            if !content.isEmpty {
                shown.append(content)
            }
        }

        if shown.isEmpty {
            let empty = NSMenuItem(title: L10n.noSimulators, action: nil, keyEquivalent: "")
            empty.isEnabled = false
            menu.addItem(empty)
        }

        for (index, content) in shown.enumerated() {
            if index > 0 {
                menu.addItem(.separator())
            }
            menu.addItem(MenuBuilder.header(for: content.simulator))
            MenuBuilder.items(for: content).forEach { menu.addItem($0) }
        }

        if !overflow.isEmpty {
            menu.addItem(.separator())
            menu.addItem(overflowItem(for: overflow))
        }

        menu.addItem(.separator())
        appendServiceItems()
    }

    private func overflowItem(for simulators: [Simulator]) -> NSMenuItem {
        let item = NSMenuItem(title: L10n.moreSimulators, action: nil, keyEquivalent: "")
        let service = service
        item.submenu = LazyMenu(title: L10n.moreSimulators) { submenu in
            for simulator in simulators {
                let simulatorItem = NSMenuItem(title: simulator.displayTitle, action: nil, keyEquivalent: "")
                simulatorItem.submenu = LazyMenu(title: simulator.displayTitle) { simulatorMenu in
                    let content = service.content(of: simulator)
                    let header = MenuBuilder.header(for: simulator)
                    simulatorMenu.addItem(header)
                    if content.isEmpty {
                        let empty = NSMenuItem(title: L10n.noSimulators, action: nil, keyEquivalent: "")
                        empty.isEnabled = false
                        simulatorMenu.addItem(empty)
                    }
                    MenuBuilder.items(for: content).forEach { simulatorMenu.addItem($0) }
                }
                submenu.addItem(simulatorItem)
            }
        }
        return item
    }

    private func appendServiceItems() {
        let loginItem = NSMenuItem(
            title: L10n.startAtLogin,
            action: #selector(toggleLoginAtLaunch),
            keyEquivalent: ""
        )
        loginItem.target = self
        loginItem.state = LoginItemManager.isEnabled ? .on : .off
        menu.addItem(loginItem)

        let updateItem = NSMenuItem(
            title: L10n.checkForUpdates,
            action: #selector(checkForUpdates),
            keyEquivalent: ""
        )
        updateItem.target = self
        menu.addItem(updateItem)

        menu.addItem(.separator())

        let appName = Bundle.main.object(forInfoDictionaryKey: "CFBundleName") as? String ?? "SimBox"
        let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? ""
        let about = NSMenuItem(
            title: L10n.about(appName: appName, version: version),
            action: #selector(openHomepage),
            keyEquivalent: ""
        )
        about.target = self
        menu.addItem(about)

        let quit = NSMenuItem(
            title: L10n.quit,
            action: #selector(quit),
            keyEquivalent: "q"
        )
        quit.target = self
        menu.addItem(quit)
    }

    @objc private func toggleLoginAtLaunch(_ sender: NSMenuItem) {
        do {
            _ = try LoginItemManager.toggle()
        } catch {
            MenuActions.showLoginItemError(error)
        }
        sender.state = LoginItemManager.isEnabled ? .on : .off
    }

    @objc private func checkForUpdates() {
        UpdateManager.shared.checkForUpdates()
    }

    @objc private func openHomepage() {
        MenuActions.openHomepage()
    }

    @objc private func quit() {
        NSApp.terminate(nil)
    }
}

extension StatusMenuController: NSMenuDelegate {
    func menuNeedsUpdate(_: NSMenu) {
        rebuildMenu()
    }
}
