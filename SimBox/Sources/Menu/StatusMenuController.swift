import AppKit

@MainActor
final class StatusMenuController: NSObject {
    private let statusItem: NSStatusItem
    private lazy var menu: NSMenu = {
        let menu = NSMenu()
        menu.autoenablesItems = false
        menu.delegate = self
        return menu
    }()

    init(statusItem: NSStatusItem) {
        self.statusItem = statusItem
        super.init()
        statusItem.menu = menu
        configureStatusButton()
    }

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
        button.toolTip = "SimBox — simulator inspector"
    }

    private func rebuildMenu() {
        menu.removeAllItems()

        let simulators = SimulatorService.activeSimulators()
        if simulators.isEmpty {
            let empty = NSMenuItem(title: "No active simulators", action: nil, keyEquivalent: "")
            empty.isEnabled = false
            menu.addItem(empty)
        } else {
            appendSimulators(Array(simulators.prefix(AppConfig.maxRecentSimulators)))
        }

        menu.addItem(.separator())
        appendServiceItems()
    }

    private func appendSimulators(_ simulators: [Simulator]) {
        var isFirst = true
        for simulator in simulators {
            let apps = SimulatorService.installedApplications(on: simulator)
            let groups = SimulatorService.appGroups(on: simulator)
            let extensions = SimulatorService.appExtensions(on: simulator)
            guard !apps.isEmpty || !groups.isEmpty || !extensions.isEmpty else { continue }

            if !isFirst {
                menu.addItem(.separator())
            }
            isFirst = false

            let header = NSMenuItem(title: simulator.displayTitle, action: nil, keyEquivalent: "")
            header.attributedTitle = NSAttributedString(
                string: simulator.displayTitle,
                attributes: [
                    .font: NSFont.systemFont(ofSize: NSFont.smallSystemFontSize, weight: .semibold),
                    .foregroundColor: NSColor.secondaryLabelColor
                ]
            )
            header.isEnabled = false
            menu.addItem(header)

            for app in apps {
                menu.addItem(MenuBuilder.item(for: app))
            }
            for group in groups {
                menu.addItem(MenuBuilder.item(for: group))
            }
            for extensionApp in extensions {
                menu.addItem(MenuBuilder.item(for: extensionApp))
            }
        }
    }

    private func appendServiceItems() {
        let loginItem = NSMenuItem(
            title: AppConfig.MenuTitle.startAtLogin,
            action: #selector(toggleLoginAtLaunch),
            keyEquivalent: ""
        )
        loginItem.target = self
        loginItem.state = LoginItemManager.isEnabled ? .on : .off
        menu.addItem(loginItem)

        let updateItem = NSMenuItem(
            title: AppConfig.MenuTitle.checkForUpdates,
            action: #selector(checkForUpdates),
            keyEquivalent: ""
        )
        updateItem.target = self
        menu.addItem(updateItem)

        menu.addItem(.separator())

        let appName = ProcessInfo.processInfo.processName
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? ""
        let about = NSMenuItem(
            title: "About \(appName) \(version)",
            action: #selector(openHomepage),
            keyEquivalent: ""
        )
        about.target = self
        menu.addItem(about)

        let quit = NSMenuItem(
            title: AppConfig.MenuTitle.quit,
            action: #selector(quit),
            keyEquivalent: "q"
        )
        quit.target = self
        menu.addItem(quit)
    }

    @objc private func toggleLoginAtLaunch(_ sender: NSMenuItem) {
        do {
            try LoginItemManager.toggle()
            sender.state = LoginItemManager.isEnabled ? .on : .off
        } catch {
            NSSound.beep()
        }
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
    func menuNeedsUpdate(_ menu: NSMenu) {
        rebuildMenu()
    }
}
