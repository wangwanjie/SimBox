import AppKit

@MainActor
enum MenuBuilder {
    static func item(for application: Application) -> NSMenuItem {
        let item = NSMenuItem(
            title: application.displayTitle,
            action: #selector(MenuTargetProxy.shared.openWithModifier(_:)),
            keyEquivalent: ""
        )
        item.target = MenuTargetProxy.shared
        item.representedObject = application.contentPath
        item.image = application.icon
        item.submenu = submenu(for: application.contentPath)
        return item
    }

    static func item(for group: AppGroup) -> NSMenuItem {
        let item = NSMenuItem(
            title: group.identifier,
            action: #selector(MenuTargetProxy.shared.openWithModifier(_:)),
            keyEquivalent: ""
        )
        item.target = MenuTargetProxy.shared
        item.representedObject = group.path
        item.submenu = submenu(for: group.path)
        return item
    }

    static func item(for appExtension: AppExtension) -> NSMenuItem {
        let item = NSMenuItem(
            title: appExtension.identifier,
            action: #selector(MenuTargetProxy.shared.openWithModifier(_:)),
            keyEquivalent: ""
        )
        item.target = MenuTargetProxy.shared
        item.representedObject = appExtension.path
        item.submenu = submenu(for: appExtension.path)
        return item
    }

    private static func submenu(for path: String) -> NSMenu {
        let submenu = NSMenu()
        submenu.autoenablesItems = false

        var hotkey = 1

        submenu.addItem(actionItem(
            title: AppConfig.MenuTitle.finder,
            path: path,
            iconPath: AppConfig.ExternalApp.finder,
            selector: #selector(MenuTargetProxy.shared.openInFinder(_:)),
            hotkey: &hotkey
        ))

        submenu.addItem(actionItem(
            title: AppConfig.MenuTitle.terminal,
            path: path,
            iconPath: AppConfig.ExternalApp.terminal,
            selector: #selector(MenuTargetProxy.shared.openInTerminal(_:)),
            hotkey: &hotkey
        ))

        if ExternalAppLauncher.isITermAvailable {
            submenu.addItem(actionItem(
                title: AppConfig.MenuTitle.iTerm,
                path: path,
                iconPath: AppConfig.ExternalApp.iTerm,
                selector: #selector(MenuTargetProxy.shared.openInITerm(_:)),
                hotkey: &hotkey
            ))
        }

        if ExternalAppLauncher.isCommanderOneAvailable {
            let iconPath = FileManager.default.fileExists(atPath: AppConfig.ExternalApp.commanderOnePro)
                ? AppConfig.ExternalApp.commanderOnePro
                : AppConfig.ExternalApp.commanderOne
            submenu.addItem(actionItem(
                title: AppConfig.MenuTitle.commanderOne,
                path: path,
                iconPath: iconPath,
                selector: #selector(MenuTargetProxy.shared.openInCommanderOne(_:)),
                hotkey: &hotkey
            ))
        }

        appendRealmItems(to: submenu, path: path, hotkey: &hotkey)

        submenu.addItem(.separator())

        submenu.addItem(actionItem(
            title: AppConfig.MenuTitle.copyPath,
            path: path,
            iconPath: nil,
            selector: #selector(MenuTargetProxy.shared.copyPath(_:)),
            hotkey: &hotkey
        ))

        submenu.addItem(actionItem(
            title: AppConfig.MenuTitle.resetContainer,
            path: path,
            iconPath: nil,
            selector: #selector(MenuTargetProxy.shared.resetContainer(_:)),
            hotkey: &hotkey
        ))

        return submenu
    }

    private static func appendRealmItems(to menu: NSMenu, path: String, hotkey: inout Int) {
        let realmFiles = SimulatorService.realmFiles(inContentPath: path)
        guard !realmFiles.isEmpty else { return }

        guard ExternalAppLauncher.isRealmStudioAvailable else {
            let install = NSMenuItem(
                title: "Install Realm Studio…",
                action: #selector(MenuTargetProxy.shared.installRealmStudio(_:)),
                keyEquivalent: "\(hotkey)"
            )
            install.target = MenuTargetProxy.shared
            menu.addItem(install)
            hotkey += 1
            return
        }

        let icon = NSWorkspace.shared.icon(forFile: AppConfig.ExternalApp.realmStudio)
        icon.size = NSSize(width: AppConfig.menuIconSize, height: AppConfig.menuIconSize)

        if realmFiles.count == 1 {
            let file = realmFiles[0]
            let item = NSMenuItem(
                title: "Realm Studio",
                action: #selector(MenuTargetProxy.shared.openRealmFile(_:)),
                keyEquivalent: "\(hotkey)"
            )
            item.target = MenuTargetProxy.shared
            item.representedObject = file.fullPath
            item.image = icon
            menu.addItem(item)
        } else {
            let parent = NSMenuItem(title: "Realm Studio", action: nil, keyEquivalent: "\(hotkey)")
            parent.image = icon
            let sub = NSMenu(title: "Realm Studio")
            sub.autoenablesItems = false
            for file in realmFiles {
                let child = NSMenuItem(
                    title: file.fileName,
                    action: #selector(MenuTargetProxy.shared.openRealmFile(_:)),
                    keyEquivalent: ""
                )
                child.target = MenuTargetProxy.shared
                child.representedObject = file.fullPath
                sub.addItem(child)
            }
            menu.setSubmenu(sub, for: parent)
            menu.addItem(parent)
        }
        hotkey += 1
    }

    private static func actionItem(
        title: String,
        path: String,
        iconPath: String?,
        selector: Selector,
        hotkey: inout Int
    )
        -> NSMenuItem
    {
        let item = NSMenuItem(title: title, action: selector, keyEquivalent: "\(hotkey)")
        item.target = MenuTargetProxy.shared
        item.representedObject = path
        if let iconPath {
            let icon = NSWorkspace.shared.icon(forFile: iconPath)
            icon.size = NSSize(width: AppConfig.menuIconSize, height: AppConfig.menuIconSize)
            item.image = icon
        }
        hotkey += 1
        return item
    }
}

@MainActor
final class MenuTargetProxy: NSObject {
    static let shared = MenuTargetProxy()

    @objc func openWithModifier(_ sender: NSMenuItem) {
        guard let path = sender.representedObject as? String else { return }
        MenuActions.openInPrimaryPlace(path: path)
    }

    @objc func openInFinder(_ sender: NSMenuItem) {
        guard let path = sender.representedObject as? String else { return }
        ExternalAppLauncher.openInFinder(path: path)
    }

    @objc func openInTerminal(_ sender: NSMenuItem) {
        guard let path = sender.representedObject as? String else { return }
        ExternalAppLauncher.openInTerminal(path: path)
    }

    @objc func openInITerm(_ sender: NSMenuItem) {
        guard let path = sender.representedObject as? String else { return }
        ExternalAppLauncher.openInITerm(path: path)
    }

    @objc func openInCommanderOne(_ sender: NSMenuItem) {
        guard let path = sender.representedObject as? String else { return }
        ExternalAppLauncher.openInCommanderOne(path: path)
    }

    @objc func copyPath(_ sender: NSMenuItem) {
        guard let path = sender.representedObject as? String else { return }
        MenuActions.copyToPasteboard(path)
    }

    @objc func resetContainer(_ sender: NSMenuItem) {
        guard let path = sender.representedObject as? String else { return }
        // 子菜单里的 reset item，父项标题就是那个 app / group 的名字。
        let submenu = sender.menu
        let title = submenu?.supermenu?.items.first { $0.submenu === submenu }?.title
        MenuActions.resetApplicationContainer(at: path, appTitle: title)
    }

    @objc func openRealmFile(_ sender: NSMenuItem) {
        guard let path = sender.representedObject as? String else { return }
        ExternalAppLauncher.openInRealmStudio(realmPath: path)
    }

    @objc func installRealmStudio(_: NSMenuItem) {
        NSWorkspace.shared.open(AppConfig.RealmConfig.websiteURL)
    }
}
