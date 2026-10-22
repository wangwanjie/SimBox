import AppKit

@MainActor
enum MenuBuilder {
    /// 子菜单里 “用 X 打开” 类条目的数字快捷键只分配 1…9。
    private static let maxHotkey = 9

    static func header(for simulator: Simulator) -> NSMenuItem {
        let header = NSMenuItem(title: simulator.displayTitle, action: nil, keyEquivalent: "")
        header.attributedTitle = NSAttributedString(
            string: simulator.displayTitle,
            attributes: [
                .font: NSFont.systemFont(ofSize: NSFont.smallSystemFontSize, weight: .semibold),
                .foregroundColor: NSColor.secondaryLabelColor
            ]
        )
        // 保持可用状态才能展开子菜单：设备目录 / 复制 UDID。
        let submenu = NSMenu()
        submenu.autoenablesItems = false
        submenu.addItem(plainItem(
            title: AppConfig.MenuTitle.deviceFolder,
            selector: #selector(MenuTargetProxy.openInFinder(_:)),
            object: simulator.path
        ))
        submenu.addItem(plainItem(
            title: AppConfig.MenuTitle.copyUDID,
            selector: #selector(MenuTargetProxy.copyString(_:)),
            object: simulator.udid
        ))
        header.submenu = submenu
        return header
    }

    static func items(for content: SimulatorContent) -> [NSMenuItem] {
        content.applications.map { item(for: $0) }
            + content.appGroups.map { item(for: $0) }
            + content.appExtensions.map { item(for: $0) }
    }

    static func item(for application: Application) -> NSMenuItem {
        let item = containerItem(title: application.displayTitle, path: application.contentPath)
        item.kg_setVisibleImage(application.icon)
        item.submenu = submenu(
            for: application.contentPath,
            identifier: application.bundleIdentifier,
            bundlePath: application.bundlePath,
            preferencesPath: application.preferencesPlistPath
        )
        return item
    }

    static func item(for group: AppGroup) -> NSMenuItem {
        let item = containerItem(title: group.identifier, path: group.path)
        item.kg_setVisibleImage(symbolImage("person.2.fill", description: "App Group"))
        item.submenu = submenu(for: group.path, identifier: group.identifier)
        return item
    }

    static func item(for appExtension: AppExtension) -> NSMenuItem {
        let item = containerItem(title: appExtension.identifier, path: appExtension.path)
        item.kg_setVisibleImage(symbolImage("puzzlepiece.extension.fill", description: "App Extension"))
        item.submenu = submenu(for: appExtension.path, identifier: appExtension.identifier)
        return item
    }

    private static func containerItem(title: String, path: String) -> NSMenuItem {
        let item = NSMenuItem(
            title: title,
            action: #selector(MenuTargetProxy.openWithModifier(_:)),
            keyEquivalent: ""
        )
        item.target = MenuTargetProxy.shared
        item.representedObject = path
        return item
    }

    /// 子菜单在真正展开时才构建，避免每次打开主菜单都为所有 app 扫描 Realm 文件、查找外部 app。
    private static func submenu(
        for path: String,
        identifier: String,
        bundlePath: String? = nil,
        preferencesPath: String? = nil
    )
        -> NSMenu {
        LazyMenu { submenu in
            populate(submenu, path: path, identifier: identifier, bundlePath: bundlePath, preferencesPath: preferencesPath)
        }
    }

    private static func populate(
        _ submenu: NSMenu,
        path: String,
        identifier: String,
        bundlePath: String?,
        preferencesPath: String?
    ) {
        var hotkey = 1

        submenu.addItem(appItem(.finder, path: path, selector: #selector(MenuTargetProxy.openInFinder(_:)), hotkey: &hotkey))
        submenu.addItem(appItem(.terminal, path: path, selector: #selector(MenuTargetProxy.openInTerminal(_:)), hotkey: &hotkey))
        if ExternalApp.iTerm.isAvailable {
            submenu.addItem(appItem(.iTerm, path: path, selector: #selector(MenuTargetProxy.openInITerm(_:)), hotkey: &hotkey))
        }
        if ExternalApp.commanderOne.isAvailable {
            submenu.addItem(appItem(
                .commanderOne,
                path: path,
                selector: #selector(MenuTargetProxy.openInCommanderOne(_:)),
                hotkey: &hotkey
            ))
        }

        appendRealmItems(to: submenu, path: path, hotkey: &hotkey)

        if bundlePath != nil || preferencesPath.map({ FileManager.default.fileExists(atPath: $0) }) == true {
            submenu.addItem(.separator())
        }
        if let bundlePath {
            submenu.addItem(plainItem(
                title: AppConfig.MenuTitle.appBundle,
                selector: #selector(MenuTargetProxy.revealInFinder(_:)),
                object: bundlePath
            ))
        }
        if let preferencesPath, FileManager.default.fileExists(atPath: preferencesPath) {
            submenu.addItem(plainItem(
                title: AppConfig.MenuTitle.userDefaults,
                selector: #selector(MenuTargetProxy.openWithDefaultApp(_:)),
                object: preferencesPath
            ))
        }

        submenu.addItem(.separator())
        submenu.addItem(plainItem(
            title: AppConfig.MenuTitle.copyPath,
            selector: #selector(MenuTargetProxy.copyString(_:)),
            object: path
        ))
        submenu.addItem(plainItem(
            title: AppConfig.MenuTitle.copyBundleID,
            selector: #selector(MenuTargetProxy.copyString(_:)),
            object: identifier
        ))

        submenu.addItem(.separator())
        // 破坏性操作不分配快捷键，避免误触。
        submenu.addItem(plainItem(
            title: AppConfig.MenuTitle.resetContainer,
            selector: #selector(MenuTargetProxy.resetContainer(_:)),
            object: path
        ))
    }

    private static func appendRealmItems(to menu: NSMenu, path: String, hotkey: inout Int) {
        let realmFiles = SimulatorService.realmFiles(inContentPath: path)
        guard !realmFiles.isEmpty else {
            return
        }

        guard let icon = ExternalApp.realmStudio.icon(size: AppConfig.menuIconSize) else {
            let install = NSMenuItem(
                title: "Install Realm Studio…",
                action: #selector(MenuTargetProxy.installRealmStudio(_:)),
                keyEquivalent: ""
            )
            install.target = MenuTargetProxy.shared
            menu.addItem(install)
            return
        }

        if realmFiles.count == 1 {
            let item = NSMenuItem(
                title: ExternalApp.realmStudio.name,
                action: #selector(MenuTargetProxy.openRealmFile(_:)),
                keyEquivalent: nextHotkey(&hotkey)
            )
            item.target = MenuTargetProxy.shared
            item.representedObject = realmFiles[0].fullPath
            item.kg_setVisibleImage(icon)
            menu.addItem(item)
        } else {
            let parent = NSMenuItem(title: ExternalApp.realmStudio.name, action: nil, keyEquivalent: "")
            parent.kg_setVisibleImage(icon)
            let sub = NSMenu(title: ExternalApp.realmStudio.name)
            sub.autoenablesItems = false
            for file in realmFiles {
                sub.addItem(plainItem(
                    title: file.fileName,
                    selector: #selector(MenuTargetProxy.openRealmFile(_:)),
                    object: file.fullPath
                ))
            }
            parent.submenu = sub
            menu.addItem(parent)
        }
    }

    private static func appItem(_ app: ExternalApp, path: String, selector: Selector, hotkey: inout Int) -> NSMenuItem {
        let item = NSMenuItem(title: app.name, action: selector, keyEquivalent: nextHotkey(&hotkey))
        item.target = MenuTargetProxy.shared
        item.representedObject = path
        item.kg_setVisibleImage(app.icon(size: AppConfig.menuIconSize))
        return item
    }

    private static func plainItem(title: String, selector: Selector, object: String) -> NSMenuItem {
        let item = NSMenuItem(title: title, action: selector, keyEquivalent: "")
        item.target = MenuTargetProxy.shared
        item.representedObject = object
        return item
    }

    /// 返回 "1"…"9"，超出后返回空串（NSMenuItem 只接受单字符快捷键）。
    private static func nextHotkey(_ hotkey: inout Int) -> String {
        defer {
            hotkey += 1
        }
        return hotkey <= maxHotkey ? "\(hotkey)" : ""
    }

    private static func symbolImage(_ name: String, description: String) -> NSImage? {
        let image = NSImage(systemSymbolName: name, accessibilityDescription: description)
        image?.size = NSSize(width: AppConfig.menuIconSize, height: AppConfig.menuIconSize)
        return image
    }
}

/// 首次展开（以及之后每次展开）时通过 builder 重新填充内容的菜单。
@MainActor
final class LazyMenu: NSMenu, NSMenuDelegate {
    private let builder: @MainActor (NSMenu) -> Void

    init(title: String = "", builder: @escaping @MainActor (NSMenu) -> Void) {
        self.builder = builder
        super.init(title: title)
        autoenablesItems = false
        delegate = self
    }

    @available(*, unavailable)
    required init(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func menuNeedsUpdate(_ menu: NSMenu) {
        menu.removeAllItems()
        builder(menu)
    }
}

@MainActor
final class MenuTargetProxy: NSObject {
    static let shared = MenuTargetProxy()

    @objc func openWithModifier(_ sender: NSMenuItem) {
        guard let path = sender.representedObject as? String else {
            return
        }
        MenuActions.openInPrimaryPlace(path: path)
    }

    @objc func openInFinder(_ sender: NSMenuItem) {
        guard let path = sender.representedObject as? String else {
            return
        }
        ExternalAppLauncher.openInFinder(path: path)
    }

    @objc func revealInFinder(_ sender: NSMenuItem) {
        guard let path = sender.representedObject as? String else {
            return
        }
        ExternalAppLauncher.revealInFinder(path: path)
    }

    @objc func openWithDefaultApp(_ sender: NSMenuItem) {
        guard let path = sender.representedObject as? String else {
            return
        }
        ExternalAppLauncher.openWithDefaultApp(path: path)
    }

    @objc func openInTerminal(_ sender: NSMenuItem) {
        guard let path = sender.representedObject as? String else {
            return
        }
        ExternalAppLauncher.openInTerminal(path: path)
    }

    @objc func openInITerm(_ sender: NSMenuItem) {
        guard let path = sender.representedObject as? String else {
            return
        }
        ExternalAppLauncher.openInITerm(path: path)
    }

    @objc func openInCommanderOne(_ sender: NSMenuItem) {
        guard let path = sender.representedObject as? String else {
            return
        }
        ExternalAppLauncher.openInCommanderOne(path: path)
    }

    @objc func copyString(_ sender: NSMenuItem) {
        guard let string = sender.representedObject as? String else {
            return
        }
        MenuActions.copyToPasteboard(string)
    }

    @objc func resetContainer(_ sender: NSMenuItem) {
        guard let path = sender.representedObject as? String else {
            return
        }
        // 子菜单里的 reset item，父项标题就是那个 app / group 的名字。
        let submenu = sender.menu
        let title = submenu?.supermenu?.items.first { $0.submenu === submenu }?.title
        MenuActions.resetApplicationContainer(at: path, appTitle: title)
    }

    @objc func openRealmFile(_ sender: NSMenuItem) {
        guard let path = sender.representedObject as? String else {
            return
        }
        ExternalAppLauncher.openInRealmStudio(realmPath: path)
    }

    @objc func installRealmStudio(_: NSMenuItem) {
        NSWorkspace.shared.open(AppConfig.RealmConfig.websiteURL)
    }
}

extension NSMenuItem {
    /// macOS 27 起 AppKit 默认隐藏菜单项图片；app 图标是 SimBox 的核心信息，需要强制显示。
    func kg_setVisibleImage(_ image: NSImage?) {
        self.image = image
        if #available(macOS 27.0, *) {
            preferredImageVisibility = .visible
        }
    }
}
