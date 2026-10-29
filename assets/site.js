/* SimBox 主页脚本：多语言、主题、拆盒动画、菜单演示、下载链接 */
(function () {
  "use strict";

  var root = document.documentElement;
  root.classList.add("js");

  // ---------- 文案（简体 / English / 繁體） ----------
  var I18N = {
    "zh-CN": {
      "title": "SimBox — 一键打开模拟器 App 沙盒的菜单栏工具",
      "desc": "SimBox 是免费的 macOS 菜单栏工具，按模拟器分组列出你安装的 App、App Group 和 App Extension，一键在 Finder 或终端中打开沙盒目录。支持 Apple 芯片与 Intel，macOS 13 及以上。",
      "skip": "跳到正文",
      "aria.home": "SimBox 首页",
      "aria.nav": "页面导航",
      "aria.lang": "语言",
      "aria.theme": "外观",
      "aria.github": "GitHub 仓库",
      "aria.footer": "页脚链接",
      "theme.light": "浅色",
      "theme.dark": "深色",
      "theme.system": "跟随系统",
      "nav.demo": "试一试",
      "nav.features": "功能",
      "nav.shots": "截图",
      "nav.install": "安装",
      "hero.eyebrow": "macOS 菜单栏工具 · 免费",
      "hero.h1": "拆开模拟器，<br><em>沙盒</em>一键直达",
      "hero.lead": "SimBox 常驻菜单栏，按模拟器分组列出你安装的 App、App Group 和 App Extension，一键在 Finder 或终端里打开它们的沙盒目录。支持 iOS、iPadOS、watchOS、tvOS 模拟器。",
      "dl.arm": "下载 Apple 芯片版",
      "dl.armSub": "arm64 · M 系列芯片",
      "dl.intel": "下载 Intel 版",
      "hero.meta": "免费 · macOS 13.0 及以上 · 已通过 Apple 公证 · 内置自动更新",
      "hero.chip": "不确定芯片类型？",
      "hero.replay": "点一下盒子，再拆一次",
      "stage.aria": "动画：玩具盒打开，模拟器设备和 App 沙盒文件夹依次弹出。点击可重新播放。",
      "demo.kicker": "可交互演示",
      "demo.h2": "点开菜单栏里的盒子",
      "demo.sub": "这是一个可以点的 SimBox 菜单复刻，数据为示例。点菜单栏里的盒子图标，再点 App 或子菜单里的操作看看会发生什么。",
      "demo.menus": "文件 编辑 显示",
      "demo.statusAria": "SimBox 菜单栏图标",
      "demo.tap": "点我",
      "demo.sample": "示例数据",
      "demo.mod": "模拟按住修饰键，再点 App 条目：",
      "mod.none": "无",
      "feat.kicker": "盒子里有什么",
      "feat.h2": "调试常用的那几下，都在子菜单里",
      "f1.t": "按模拟器分组",
      "f1.d": "列出每台模拟器里你安装的 App、App Group 与 App Extension，显示图标、名称和版本号；系统 App 自动隐藏。",
      "f2.t": "已启动的排最前",
      "f2.d": "已启动的模拟器排在最前，其余按最近使用时间排序；超过 5 台的收进「更多模拟器」子菜单。",
      "f3.t": "四种打开方式",
      "f3.d": "用 Finder、终端、iTerm 或 Commander One 打开沙盒目录，子菜单带 ⌘1…⌘9 快捷键。",
      "f4.t": "定位安装包",
      "f4.d": "在 Finder 中定位 App 的 .app 安装包。",
      "f5.d": "直接打开 App 的 UserDefaults 对应的 plist 文件。",
      "f6.t": "拷贝路径与 ID",
      "f6.d": "拷贝沙盒路径、Bundle Identifier；模拟器标题的子菜单可拷贝 UDID、打开设备目录。",
      "f7.t": "重置 App 数据",
      "f7.d": "清空 Documents / Library / tmp 内容，保留容器结构，App 下次启动即可正常读写。",
      "f8.d": "检测到 .realm 文件时提供 Realm Studio 快捷入口。",
      "f9.t": "登录时启动",
      "f9.d": "开机自启，需要授权时自动跳转到「系统设置 › 登录项」。",
      "f10.t": "按芯片自动更新",
      "f10.d": "内置 Sparkle 自动更新，Apple 芯片与 Intel 分别推送各自的安装包。",
      "f11.t": "三种语言",
      "f11.d": "界面支持 English、简体中文、繁體中文，跟随系统语言。",
      "f12.t": "只在菜单栏",
      "f12.d": "原生 AppKit 菜单栏应用，没有主窗口，也不占程序坞。",
      "keys.kicker": "快捷键",
      "keys.h2": "按住一个键，换一个去处",
      "keys.sub": "点击 App 条目本身时，按住不同修饰键打开到不同位置；子菜单里的打开方式还带 ⌘1…⌘9 快捷键。",
      "keys.click": "点击",
      "keys.terminal": "终端",
      "keys.ifInstalled": "若已安装",
      "shots.kicker": "真实界面",
      "shots.h2": "三种界面语言，跟随系统",
      "shots.sub": "以下是 SimBox 运行时的菜单截图，App 为演示数据。",
      "shots.alt": "SimBox 菜单截图：按模拟器分组的 App 列表，以及 App 子菜单里的打开方式和操作",
      "ins.kicker": "安装",
      "ins.h2": "三步放进菜单栏",
      "ins.s1t": "下载 DMG",
      "ins.s1d": "按本机芯片选择 <code>SimBox_v&lt;版本&gt;_arm64.dmg</code> 或 <code>SimBox_v&lt;版本&gt;_x86_64.dmg</code>，上方按钮会直接下载最新版。",
      "ins.s2t": "拖进「应用程序」",
      "ins.s2d": "安装包已经过 Apple 公证。打开 DMG，把 SimBox 拖进「应用程序」文件夹。",
      "ins.s3t": "打开，去菜单栏找它",
      "ins.s3d": "启动后 SimBox 出现在菜单栏，可在菜单里开启「登录时启动」。新版本通过内置的 Sparkle 推送，也可以点「检查更新…」。",
      "ins.chipT": "不确定芯片类型？",
      "ins.chipD": "打开「苹果菜单 › 关于本机」，「芯片」一栏写着 Apple M… 的选 Apple 芯片版，写着 Intel 的选 Intel 版。",
      "ins.reqT": "系统要求",
      "ins.reqD": "macOS 13.0 或更高版本；Apple 芯片或 Intel 芯片；已安装 Xcode 及模拟器运行时。",
      "foot.more": "VanJay 的更多作品",
      "foot.releases": "版本历史",
      "foot.issues": "反馈",
      "shot.alt.zh-Hans": "SimBox 简体中文界面截图",
      "shot.alt.en": "SimBox 英文界面截图",
      "shot.alt.zh-Hant": "SimBox 繁体中文界面截图",
      // 菜单文案取自 App 的 Localizable.xcstrings
      "m.booted": "已启动",
      "m.finder": "访达",
      "m.terminal": "终端",
      "m.realm": "安装 Realm Studio…",
      "m.bundle": "在访达中显示 App 安装包",
      "m.copyPath": "拷贝路径",
      "m.copyID": "拷贝 Bundle ID",
      "m.reset": "重置 App 数据…",
      "m.deviceFolder": "在访达中打开设备目录",
      "m.copyUDID": "拷贝 UDID",
      "m.login": "登录时启动",
      "m.update": "检查更新…",
      "m.about": "关于 SimBox {v}",
      "m.quit": "退出 SimBox",
      "m.resetTitle": "重置 App 数据？",
      "m.resetBody": "将清空 {n} 的 Documents、Library、tmp 等目录中的全部数据，此操作不可撤销。\n请先在模拟器上退出该 App，否则可能残留数据。",
      "m.cancel": "取消",
      "m.resetBtn": "重置",
      "m.close": "关闭",
      "t.copied": "已拷贝",
      "t.reset": "{n} 的 Documents、Library、tmp 已清空（演示）",
      "t.realm": "真实 App 会打开 Realm Studio 的下载页",
      "t.loginOn": "已开启登录时启动（演示）",
      "t.loginOff": "已关闭登录时启动（演示）",
      "t.update": "真实 App 会通过 Sparkle 检查与本机芯片匹配的新版本",
      "t.about": "SimBox — 模拟器沙盒浏览器",
      "t.quit": "这是演示，SimBox 继续留在菜单栏里",
      "t.commander": "按住 ⌃ Control 点击：在 Commander One 中打开（若已安装）"
    },
    "en": {
      "title": "SimBox — Open simulator app sandboxes from the menu bar",
      "desc": "SimBox is a free macOS menu bar app that lists the apps, App Groups and App Extensions you installed, grouped by simulator, and opens their sandbox in Finder or Terminal in one click. Apple silicon and Intel, macOS 13 or later.",
      "skip": "Skip to content",
      "aria.home": "SimBox home",
      "aria.nav": "Page navigation",
      "aria.lang": "Language",
      "aria.theme": "Appearance",
      "aria.github": "GitHub repository",
      "aria.footer": "Footer links",
      "theme.light": "Light",
      "theme.dark": "Dark",
      "theme.system": "Match system",
      "nav.demo": "Try it",
      "nav.features": "Features",
      "nav.shots": "Screenshots",
      "nav.install": "Install",
      "hero.eyebrow": "A free macOS menu bar app",
      "hero.h1": "Unbox your simulators.<br><em>Sandboxes</em> in one click.",
      "hero.lead": "SimBox lives in your menu bar and lists the apps, App Groups and App Extensions you installed, grouped by simulator. One click opens their sandbox folder in Finder or Terminal, for iOS, iPadOS, watchOS and tvOS simulators.",
      "dl.arm": "Download for Apple silicon",
      "dl.armSub": "arm64 · M-series chips",
      "dl.intel": "Download for Intel",
      "hero.meta": "Free · macOS 13.0 or later · Notarized by Apple · Built-in auto update",
      "hero.chip": "Not sure which chip you have?",
      "hero.replay": "Tap the box to unbox again",
      "stage.aria": "Animation: a toy box opens and simulator devices and app sandbox folders pop out one by one. Click to replay.",
      "demo.kicker": "Interactive demo",
      "demo.h2": "Open the box in the menu bar",
      "demo.sub": "A clickable replica of the SimBox menu with sample data. Click the box icon in the menu bar, then pick an app or an action from its submenu.",
      "demo.menus": "File Edit View",
      "demo.statusAria": "SimBox menu bar icon",
      "demo.tap": "Click me",
      "demo.sample": "Sample data",
      "demo.mod": "Hold a modifier, then click an app:",
      "mod.none": "None",
      "feat.kicker": "What's in the box",
      "feat.h2": "The everyday debugging moves, tucked into one submenu",
      "f1.t": "Grouped by simulator",
      "f1.d": "Lists the apps, App Groups and App Extensions you installed in each simulator, with icon, name and version. System apps stay hidden.",
      "f2.t": "Booted first",
      "f2.d": "Booted simulators come first, the rest follow by last use. Beyond five, they fold into a More Simulators submenu.",
      "f3.t": "Four ways to open",
      "f3.d": "Open a sandbox in Finder, Terminal, iTerm or Commander One, with ⌘1…⌘9 in the submenu.",
      "f4.t": "Reveal the .app",
      "f4.d": "Reveal the app bundle in Finder.",
      "f5.d": "Open the plist file that backs the app's UserDefaults.",
      "f6.t": "Copy path & ID",
      "f6.d": "Copy the sandbox path or bundle identifier. A simulator's title has its own submenu to copy the UDID or open the device folder.",
      "f7.t": "Reset app data",
      "f7.d": "Empties Documents / Library / tmp while keeping the container intact, so the app reads and writes normally on its next launch.",
      "f8.d": "A shortcut to Realm Studio whenever a .realm file is found.",
      "f9.t": "Launch at login",
      "f9.d": "Starts with your Mac and takes you to System Settings › Login Items when approval is needed.",
      "f10.t": "Updates for your chip",
      "f10.d": "Built-in Sparkle updates deliver the matching build for Apple silicon or Intel.",
      "f11.t": "Three languages",
      "f11.d": "English, Simplified Chinese and Traditional Chinese, following your system language.",
      "f12.t": "Menu bar only",
      "f12.d": "A native AppKit menu bar app with no main window and no Dock icon.",
      "keys.kicker": "Shortcuts",
      "keys.h2": "Hold a key, pick a destination",
      "keys.sub": "Hold a modifier while clicking an app to choose where it opens. The open actions in the submenu also have ⌘1…⌘9.",
      "keys.click": "Click",
      "keys.terminal": "Terminal",
      "keys.ifInstalled": "if installed",
      "shots.kicker": "The real thing",
      "shots.h2": "Three languages, following your system",
      "shots.sub": "Screenshots of the running SimBox menu. The apps are sample data.",
      "shots.alt": "SimBox menu screenshot: apps grouped by simulator, with an app's submenu of open actions and tools",
      "ins.kicker": "Install",
      "ins.h2": "Three steps to the menu bar",
      "ins.s1t": "Download the DMG",
      "ins.s1d": "Pick <code>SimBox_v&lt;version&gt;_arm64.dmg</code> or <code>SimBox_v&lt;version&gt;_x86_64.dmg</code> for your chip. The buttons above download the latest release directly.",
      "ins.s2t": "Drag into Applications",
      "ins.s2d": "The DMG is notarized by Apple. Open it and drag SimBox into the Applications folder.",
      "ins.s3t": "Launch it, find it in the menu bar",
      "ins.s3d": "SimBox appears in the menu bar, where you can turn on Launch at login. New versions arrive through the built-in Sparkle updater, or choose Check for updates….",
      "ins.chipT": "Not sure which chip you have?",
      "ins.chipD": "Open  › About This Mac. If the Chip line says Apple M…, pick Apple silicon; if it says Intel, pick Intel.",
      "ins.reqT": "Requirements",
      "ins.reqD": "macOS 13.0 or later; Apple silicon or Intel; Xcode with simulator runtimes installed.",
      "foot.more": "More apps by VanJay",
      "foot.releases": "Releases",
      "foot.issues": "Feedback",
      "shot.alt.zh-Hans": "SimBox in Simplified Chinese",
      "shot.alt.en": "SimBox in English",
      "shot.alt.zh-Hant": "SimBox in Traditional Chinese",
      "m.booted": "Booted",
      "m.finder": "Finder",
      "m.terminal": "Terminal",
      "m.realm": "Install Realm Studio…",
      "m.bundle": "App bundle in Finder",
      "m.copyPath": "Copy path",
      "m.copyID": "Copy bundle identifier",
      "m.reset": "Reset app data…",
      "m.deviceFolder": "Device folder in Finder",
      "m.copyUDID": "Copy UDID",
      "m.login": "Launch at login",
      "m.update": "Check for updates…",
      "m.about": "About SimBox {v}",
      "m.quit": "Quit SimBox",
      "m.resetTitle": "Reset app data?",
      "m.resetBody": "All data inside the Documents, Library and tmp folders of {n} will be erased. This cannot be undone.\nQuit the app on the simulator first, otherwise some data may remain.",
      "m.cancel": "Cancel",
      "m.resetBtn": "Reset",
      "m.close": "Close",
      "t.copied": "Copied",
      "t.reset": "Emptied Documents, Library and tmp of {n} (demo)",
      "t.realm": "The real app opens the Realm Studio download page",
      "t.loginOn": "Launch at login turned on (demo)",
      "t.loginOff": "Launch at login turned off (demo)",
      "t.update": "The real app checks for a build that matches your chip via Sparkle",
      "t.about": "SimBox — simulator sandbox browser",
      "t.quit": "It's a demo, so SimBox stays in the menu bar",
      "t.commander": "⌃ Control-click: opens in Commander One (if installed)"
    },
    "zh-TW": {
      "title": "SimBox — 一鍵打開模擬器 App 沙盒的選單列工具",
      "desc": "SimBox 是免費的 macOS 選單列工具，依模擬器分組列出你安裝的 App、App Group 和 App Extension，一鍵在 Finder 或終端機中打開沙盒檔案夾。支援 Apple 晶片與 Intel，macOS 13 以上。",
      "skip": "跳到正文",
      "aria.home": "SimBox 首頁",
      "aria.nav": "頁面導覽",
      "aria.lang": "語言",
      "aria.theme": "外觀",
      "aria.github": "GitHub 儲存庫",
      "aria.footer": "頁尾連結",
      "theme.light": "淺色",
      "theme.dark": "深色",
      "theme.system": "跟隨系統",
      "nav.demo": "試試看",
      "nav.features": "功能",
      "nav.shots": "截圖",
      "nav.install": "安裝",
      "hero.eyebrow": "macOS 選單列工具 · 免費",
      "hero.h1": "拆開模擬器，<br><em>沙盒</em>一鍵直達",
      "hero.lead": "SimBox 常駐選單列，依模擬器分組列出你安裝的 App、App Group 和 App Extension，一鍵在 Finder 或終端機裡打開它們的沙盒檔案夾。支援 iOS、iPadOS、watchOS、tvOS 模擬器。",
      "dl.arm": "下載 Apple 晶片版",
      "dl.armSub": "arm64 · M 系列晶片",
      "dl.intel": "下載 Intel 版",
      "hero.meta": "免費 · macOS 13.0 以上 · 已通過 Apple 公證 · 內建自動更新",
      "hero.chip": "不確定晶片類型？",
      "hero.replay": "點一下盒子，再拆一次",
      "stage.aria": "動畫：玩具盒打開，模擬器裝置和 App 沙盒檔案夾依序彈出。點一下可重新播放。",
      "demo.kicker": "互動示範",
      "demo.h2": "點開選單列裡的盒子",
      "demo.sub": "這是可以點的 SimBox 選單複刻，資料為範例。點選單列裡的盒子圖示，再點 App 或子選單裡的操作看看會發生什麼。",
      "demo.menus": "檔案 編輯 顯示方式",
      "demo.statusAria": "SimBox 選單列圖示",
      "demo.tap": "點我",
      "demo.sample": "範例資料",
      "demo.mod": "模擬按住輔助鍵，再點 App 項目：",
      "mod.none": "無",
      "feat.kicker": "盒子裡有什麼",
      "feat.h2": "除錯常用的那幾下，都在子選單裡",
      "f1.t": "依模擬器分組",
      "f1.d": "列出每台模擬器裡你安裝的 App、App Group 與 App Extension，顯示圖示、名稱和版本號；系統 App 自動隱藏。",
      "f2.t": "已啟動的排最前",
      "f2.d": "已啟動的模擬器排在最前，其餘依最近使用時間排序；超過 5 台的收進「更多模擬器」子選單。",
      "f3.t": "四種打開方式",
      "f3.d": "用 Finder、終端機、iTerm 或 Commander One 打開沙盒檔案夾，子選單帶 ⌘1…⌘9 快速鍵。",
      "f4.t": "定位 App 套件",
      "f4.d": "在 Finder 中定位 App 的 .app 套件。",
      "f5.d": "直接打開 App 的 UserDefaults 對應的 plist 檔案。",
      "f6.t": "拷貝路徑與 ID",
      "f6.d": "拷貝沙盒路徑、Bundle Identifier；模擬器標題的子選單可拷貝 UDID、打開裝置檔案夾。",
      "f7.t": "重置 App 資料",
      "f7.d": "清除 Documents / Library / tmp 內容，保留容器結構，App 下次啟動即可正常讀寫。",
      "f8.d": "偵測到 .realm 檔案時提供 Realm Studio 快捷入口。",
      "f9.t": "登入時啟動",
      "f9.d": "開機自動啟動，需要授權時自動跳到「系統設定 › 登入項目」。",
      "f10.t": "依晶片自動更新",
      "f10.d": "內建 Sparkle 自動更新，Apple 晶片與 Intel 各自推送對應的安裝檔。",
      "f11.t": "三種語言",
      "f11.d": "介面支援 English、简体中文、繁體中文，跟隨系統語言。",
      "f12.t": "只在選單列",
      "f12.d": "原生 AppKit 選單列軟體，沒有主視窗，也不佔 Dock。",
      "keys.kicker": "快速鍵",
      "keys.h2": "按住一個鍵，換一個去處",
      "keys.sub": "點 App 項目本身時，按住不同輔助鍵打開到不同位置；子選單裡的打開方式還帶 ⌘1…⌘9 快速鍵。",
      "keys.click": "點按",
      "keys.terminal": "終端機",
      "keys.ifInstalled": "若已安裝",
      "shots.kicker": "真實介面",
      "shots.h2": "三種介面語言，跟隨系統",
      "shots.sub": "以下是 SimBox 執行時的選單截圖，App 為示範資料。",
      "shots.alt": "SimBox 選單截圖：依模擬器分組的 App 列表，以及 App 子選單裡的打開方式和操作",
      "ins.kicker": "安裝",
      "ins.h2": "三步放進選單列",
      "ins.s1t": "下載 DMG",
      "ins.s1d": "依本機晶片選擇 <code>SimBox_v&lt;版本&gt;_arm64.dmg</code> 或 <code>SimBox_v&lt;版本&gt;_x86_64.dmg</code>，上方按鈕會直接下載最新版。",
      "ins.s2t": "拖進「應用程式」",
      "ins.s2d": "安裝檔已通過 Apple 公證。打開 DMG，把 SimBox 拖進「應用程式」檔案夾。",
      "ins.s3t": "打開，去選單列找它",
      "ins.s3d": "啟動後 SimBox 出現在選單列，可在選單裡開啟「登入時啟動」。新版本透過內建的 Sparkle 推送，也可以點「檢查更新項目…」。",
      "ins.chipT": "不確定晶片類型？",
      "ins.chipD": "打開「蘋果選單 › 關於這台 Mac」，「晶片」一欄寫著 Apple M… 的選 Apple 晶片版，寫著 Intel 的選 Intel 版。",
      "ins.reqT": "系統需求",
      "ins.reqD": "macOS 13.0 或以上版本；Apple 晶片或 Intel 晶片；已安裝 Xcode 及模擬器執行環境。",
      "foot.more": "VanJay 的更多作品",
      "foot.releases": "版本紀錄",
      "foot.issues": "意見回饋",
      "shot.alt.zh-Hans": "SimBox 簡體中文介面截圖",
      "shot.alt.en": "SimBox 英文介面截圖",
      "shot.alt.zh-Hant": "SimBox 繁體中文介面截圖",
      "m.booted": "已啟動",
      "m.finder": "Finder",
      "m.terminal": "終端機",
      "m.realm": "安裝 Realm Studio…",
      "m.bundle": "在 Finder 中顯示 App 套件",
      "m.copyPath": "拷貝路徑",
      "m.copyID": "拷貝 Bundle ID",
      "m.reset": "重置 App 資料…",
      "m.deviceFolder": "在 Finder 中打開裝置檔案夾",
      "m.copyUDID": "拷貝 UDID",
      "m.login": "登入時啟動",
      "m.update": "檢查更新項目…",
      "m.about": "關於 SimBox {v}",
      "m.quit": "結束 SimBox",
      "m.resetTitle": "重置 App 資料？",
      "m.resetBody": "將清除 {n} 的 Documents、Library、tmp 等檔案夾中的所有資料，此操作無法還原。\n請先在模擬器上結束該 App，否則可能殘留資料。",
      "m.cancel": "取消",
      "m.resetBtn": "重置",
      "m.close": "關閉",
      "t.copied": "已拷貝",
      "t.reset": "{n} 的 Documents、Library、tmp 已清除（示範）",
      "t.realm": "真實 App 會打開 Realm Studio 的下載頁面",
      "t.loginOn": "已開啟登入時啟動（示範）",
      "t.loginOff": "已關閉登入時啟動（示範）",
      "t.update": "真實 App 會透過 Sparkle 檢查與本機晶片相符的新版本",
      "t.about": "SimBox — 模擬器沙盒瀏覽器",
      "t.quit": "這是示範，SimBox 繼續留在選單列裡",
      "t.commander": "按住 ⌃ Control 點按：在 Commander One 中打開（若已安裝）"
    }
  };

  var LANGS = ["zh-CN", "en", "zh-TW"];
  var SHOT_FOR_LANG = { "zh-CN": "zh-Hans", "en": "en", "zh-TW": "zh-Hant" };
  var params = new URLSearchParams(location.search);
  var lang = "zh-CN";
  var appVersion = "2.3.0";

  function store(key, value) {
    try {
      localStorage.setItem(key, value);
    } catch (e) {}
  }
  function load(key) {
    try {
      return localStorage.getItem(key);
    } catch (e) {
      return null;
    }
  }

  // 把各种写法归一到三种语言代码
  function normalizeLang(value) {
    if (!value) {
      return null;
    }
    var v = String(value).toLowerCase();
    if (/^zh[-_]?(tw|hk|mo|hant)/.test(v) || v === "tw") {
      return "zh-TW";
    }
    if (v.indexOf("zh") === 0 || v === "cn") {
      return "zh-CN";
    }
    if (v.indexOf("en") === 0) {
      return "en";
    }
    return null;
  }
  function detectLang() {
    var list = navigator.languages && navigator.languages.length ? navigator.languages : [navigator.language || "en"];
    for (var i = 0; i < list.length; i++) {
      var v = String(list[i]).toLowerCase();
      if (v.indexOf("zh") === 0) {
        return normalizeLang(v) || "zh-CN";
      }
      if (v.indexOf("en") === 0) {
        return "en";
      }
    }
    return "en";
  }

  function t(key, vars) {
    var s = (I18N[lang] && I18N[lang][key]) || I18N["zh-CN"][key] || "";
    if (vars) {
      Object.keys(vars).forEach(function (k) {
        s = s.split("{" + k + "}").join(vars[k]);
      });
    }
    return s;
  }

  function applyLang(next, persist) {
    lang = LANGS.indexOf(next) >= 0 ? next : "zh-CN";
    root.lang = lang;
    document.title = t("title");
    document.querySelector('meta[name="description"]').content = t("desc");
    document.querySelector('meta[property="og:title"]').content = t("title");
    document.querySelector('meta[property="og:description"]').content = t("desc");
    document.querySelectorAll("[data-i]").forEach(function (el) {
      el.textContent = t(el.getAttribute("data-i"));
    });
    document.querySelectorAll("[data-ih]").forEach(function (el) {
      el.innerHTML = t(el.getAttribute("data-ih"));
    });
    document.querySelectorAll("[data-iaria]").forEach(function (el) {
      el.setAttribute("aria-label", t(el.getAttribute("data-iaria")));
    });
    document.querySelectorAll("[data-ititle]").forEach(function (el) {
      el.setAttribute("title", t(el.getAttribute("data-ititle")));
    });
    document.querySelectorAll("[data-ialt]").forEach(function (el) {
      el.setAttribute("alt", t(el.getAttribute("data-ialt")));
    });
    document.querySelectorAll("#lang-seg button").forEach(function (b) {
      b.setAttribute("aria-pressed", String(b.dataset.lang === lang));
    });
    if (persist) {
      store("simbox.lang", lang);
    }
    showShot(SHOT_FOR_LANG[lang]);
    if (demo) {
      demo.relabel();
    }
  }

  // ---------- 主题 ----------
  var media = matchMedia("(prefers-color-scheme: dark)");
  function applyTheme(pref, persist) {
    if (pref !== "light" && pref !== "dark") {
      pref = "system";
    }
    var dark = pref === "dark" || (pref === "system" && media.matches);
    root.dataset.themePref = pref;
    root.dataset.theme = dark ? "dark" : "light";
    document.querySelector('meta[name="theme-color"]').content = dark ? "#14102b" : "#fff7e8";
    document.querySelectorAll("#theme-seg button").forEach(function (b) {
      b.setAttribute("aria-pressed", String(b.dataset.themeBtn === pref));
    });
    if (persist) {
      store("simbox.theme", pref);
    }
  }
  var onSchemeChange = function () {
    if (root.dataset.themePref === "system") {
      applyTheme("system", false);
    }
  };
  if (media.addEventListener) {
    media.addEventListener("change", onSchemeChange);
  } else if (media.addListener) {
    media.addListener(onSchemeChange);
  }
  document.getElementById("theme-seg").addEventListener("click", function (e) {
    var b = e.target.closest("button");
    if (b) {
      applyTheme(b.dataset.themeBtn, true);
    }
  });
  document.getElementById("lang-seg").addEventListener("click", function (e) {
    var b = e.target.closest("button");
    if (b) {
      applyLang(b.dataset.lang, true);
    }
  });

  // ---------- 截图切换 ----------
  var shotImg = document.getElementById("shot-img");
  var currentShot = "";
  function showShot(name) {
    document.querySelectorAll("#shot-tabs button").forEach(function (b) {
      b.setAttribute("aria-selected", String(b.dataset.shot === name));
    });
    if (name === currentShot) {
      shotImg.alt = t("shots.alt") + " · " + t("shot.alt." + name);
      return;
    }
    currentShot = name;
    shotImg.classList.add("fade");
    var base = "assets/screenshots/" + name;
    shotImg.srcset = base + "-800.webp 800w, " + base + ".webp 1450w";
    shotImg.src = base + "-800.webp";
    shotImg.alt = t("shots.alt") + " · " + t("shot.alt." + name);
  }
  shotImg.addEventListener("load", function () {
    shotImg.classList.remove("fade");
  });
  document.getElementById("shot-tabs").addEventListener("click", function (e) {
    var b = e.target.closest("button");
    if (b) {
      showShot(b.dataset.shot);
    }
  });

  // ---------- 拆盒主视觉 ----------
  var reduceMotion = matchMedia("(prefers-reduced-motion: reduce)");
  var stage = document.getElementById("stage");
  var unboxTimers = [];
  function unbox() {
    unboxTimers.forEach(clearTimeout);
    unboxTimers = [];
    stage.classList.remove("open", "shake");
    if (reduceMotion.matches) {
      stage.classList.add("open");
      return;
    }
    // 强制回流，让动画从头播放
    void stage.offsetWidth;
    stage.classList.add("shake");
    unboxTimers.push(setTimeout(function () {
      stage.classList.add("open");
    }, 520));
    unboxTimers.push(setTimeout(function () {
      stage.classList.remove("shake");
    }, 700));
  }
  stage.addEventListener("click", unbox);

  // 指针视差：rAF 合并更新，只写 CSS 变量，驱动 transform
  var hero = document.querySelector(".hero");
  var pending = null;
  var rafId = 0;
  hero.addEventListener("pointermove", function (e) {
    if (reduceMotion.matches || e.pointerType === "touch") {
      return;
    }
    var r = stage.getBoundingClientRect();
    pending = {
      x: Math.max(-1, Math.min(1, (e.clientX - (r.left + r.width / 2)) / (r.width / 2 + 200))),
      y: Math.max(-1, Math.min(1, (e.clientY - (r.top + r.height / 2)) / (r.height / 2 + 200)))
    };
    if (!rafId) {
      rafId = requestAnimationFrame(function () {
        rafId = 0;
        if (pending) {
          stage.style.setProperty("--px", pending.x.toFixed(3));
          stage.style.setProperty("--py", pending.y.toFixed(3));
        }
      });
    }
  });
  hero.addEventListener("pointerleave", function () {
    stage.style.setProperty("--px", "0");
    stage.style.setProperty("--py", "0");
  });

  // 首屏离开视口或页面隐藏时暂停循环动画
  var heroVisible = true;
  function syncPause() {
    var paused = !heroVisible || document.hidden;
    stage.classList.toggle("paused", paused);
    hero.classList.toggle("paused", paused);
  }
  document.addEventListener("visibilitychange", syncPause);

  // ---------- 滚动渐入 ----------
  if ("IntersectionObserver" in window) {
    new IntersectionObserver(function (entries) {
      entries.forEach(function (en) {
        heroVisible = en.isIntersecting;
      });
      syncPause();
    }).observe(hero);

    var revealIO = new IntersectionObserver(function (entries) {
      entries.forEach(function (en) {
        if (en.isIntersecting) {
          en.target.classList.add("in");
          revealIO.unobserve(en.target);
        }
      });
    }, { rootMargin: "0px 0px -8% 0px", threshold: .08 });
    document.querySelectorAll(".reveal").forEach(function (el) {
      // 同一组里的卡片错开出现
      var siblings = el.parentElement.querySelectorAll(":scope > .reveal");
      var idx = Array.prototype.indexOf.call(siblings, el);
      el.style.setProperty("--rd", (Math.min(idx, 6) * .07) + "s");
      revealIO.observe(el);
    });
  } else {
    document.querySelectorAll(".reveal").forEach(function (el) {
      el.classList.add("in");
    });
  }

  // ---------- 快捷键键帽：真实按下 ⌥ / ⌃ 时跟着按下 ----------
  var keycards = document.querySelectorAll(".keycard");
  function pressKeycards(e) {
    keycards.forEach(function (k) {
      var on = (k.dataset.key === "alt" && e.altKey) || (k.dataset.key === "ctrl" && e.ctrlKey);
      k.classList.toggle("pressed", on);
    });
  }
  document.addEventListener("keydown", pressKeycards);
  document.addEventListener("keyup", pressKeycards);

  // ---------- 菜单栏演示 ----------
  var ICONS = {
    cloud: '<svg viewBox="0 0 16 16"><path d="M4.5 12.5h7a2.5 2.5 0 0 0 .3-5A3.5 3.5 0 0 0 5 6.8a2.9 2.9 0 0 0-.5 5.7z"/></svg>',
    fork: '<svg viewBox="0 0 16 16"><path d="M5 2v4.5a1.5 1.5 0 0 0 3 0V2M6.5 7v7M11 2c-1.2.6-1.5 2-1.5 3.5V9H11V14"/></svg>',
    walk: '<svg viewBox="0 0 16 16"><circle cx="9" cy="3" r="1.3"/><path d="M8.5 6 6 14M8.5 6l2 3h2M8.5 6 5.5 8v2.5M7.3 10.5 10 14"/></svg>',
    brush: '<svg viewBox="0 0 16 16"><path d="M13.5 2.5 7 9M4.5 9.5c-1.6 0-2 1.4-2 2.5 0 .8-.5 1.5-1 1.5h3.5a2.5 2.5 0 0 0 2-4z"/></svg>',
    heart: '<svg viewBox="0 0 16 16"><path d="M8 13.5S2.5 10.2 2.5 6.3A2.8 2.8 0 0 1 8 4.8a2.8 2.8 0 0 1 5.5 1.5C13.5 10.2 8 13.5 8 13.5z"/></svg>',
    remote: '<svg viewBox="0 0 16 16"><rect x="5" y="1.5" width="6" height="13" rx="2"/><circle cx="8" cy="5" r="1.2"/><path d="M8 9v3"/></svg>',
    group: '<svg viewBox="0 0 16 16"><circle cx="5.5" cy="5" r="2.3"/><circle cx="11" cy="5.5" r="2"/><path d="M1.5 13c0-2.5 1.8-4 4-4s4 1.5 4 4zM10 9.2c2.4-.3 4.5 1 4.5 3.8H11"/></svg>',
    ext: '<svg viewBox="0 0 16 16"><path d="M2 5.5h3a1.8 1.8 0 1 1 3.5 0H12v3.2a1.8 1.8 0 1 1 0 3.5V14H2z"/></svg>',
    finder: '<svg viewBox="0 0 16 16"><rect x="1.5" y="1.5" width="13" height="13" rx="3" fill="#3ea6ff" stroke="none"/><path d="M8 1.5v13M5 6v1M11 6v1M5 10.5c1.8 1.3 4.2 1.3 6 0" stroke="#fff"/></svg>',
    term: '<svg viewBox="0 0 16 16"><rect x="1.5" y="1.5" width="13" height="13" rx="3" fill="#222" stroke="none"/><path d="M4.5 6l2 2-2 2M8.5 10.5h3" stroke="#fff"/></svg>',
    iterm: '<svg viewBox="0 0 16 16"><rect x="1.5" y="1.5" width="13" height="13" rx="3" fill="#111" stroke="none"/><path d="M4.5 5.5v3M7 5.5h4" stroke="#3ce36b"/></svg>',
    chev: '<svg class="chev" viewBox="0 0 8 12"><path d="M2 1.5 6.5 6 2 10.5"/></svg>'
  };

  // 示例数据：与 README 截图一致，并补一台 tvOS 模拟器
  var SIMS = [
    {
      name: "iPhone 18 Pro", os: "iOS 27.0", booted: true, udid: "8F3A2C1E-5B6D-4E7F-9A0B-1C2D3E4F5A6B",
      items: [
        { kind: "app", name: "Weather Lab", ver: "3.2.0 (412)", id: "com.example.weatherlab", exe: "WeatherLab", icon: "cloud", color: "linear-gradient(160deg,#5fb6ff,#3a7cf0)", realm: true },
        { kind: "app", name: "Recipe Box", ver: "1.8.1 (77)", id: "com.example.recipebox", exe: "RecipeBox", icon: "fork", color: "linear-gradient(160deg,#ffb347,#ff7a29)" },
        { kind: "app", name: "Trail Tracker", ver: "2.0.0 (2001)", id: "com.example.trailtracker", exe: "TrailTracker", icon: "walk", color: "linear-gradient(160deg,#5fe08f,#21b067)" },
        { kind: "group", name: "group.com.example.weatherlab", id: "group.com.example.weatherlab", icon: "group" },
        { kind: "ext", name: "com.example.weatherlab.widget", id: "com.example.weatherlab.widget", icon: "ext" }
      ]
    },
    {
      name: "iPad Pro 13-inch (M5)", os: "iOS 27.0", udid: "2D4C6E8A-1B3D-4F5A-8C7E-9B0A1D2C3E4F",
      items: [{ kind: "app", name: "Sketchbook", ver: "5.1 (530)", id: "com.example.sketchbook", exe: "Sketchbook", icon: "brush", color: "linear-gradient(160deg,#b78cff,#7a4cf0)" }]
    },
    {
      name: "Apple Watch Series 11 (46mm)", os: "watchOS 27.0", udid: "6A1B2C3D-4E5F-4A7B-8C9D-0E1F2A3B4C5D",
      items: [{ kind: "app", name: "Pulse", ver: "1.0 (12)", id: "com.example.pulse", exe: "Pulse", icon: "heart", color: "linear-gradient(160deg,#ff8aa8,#ff4f7a)" }]
    },
    {
      name: "Apple TV 4K (3rd generation)", os: "tvOS 27.0", udid: "C3D4E5F6-A7B8-4C9D-8E0F-1A2B3C4D5E6F",
      items: [{ kind: "app", name: "Couch Remote", ver: "1.2 (9)", id: "com.example.couchremote", exe: "CouchRemote", icon: "remote", color: "linear-gradient(160deg,#7f8cff,#4b55d6)" }]
    }
  ];
  var DEV_ROOT = "~/Library/Developer/CoreSimulator/Devices/";

  function esc(s) {
    return String(s).replace(/[&<>"]/g, function (c) {
      return { "&": "&amp;", "<": "&lt;", ">": "&gt;", "\"": "&quot;" }[c];
    });
  }
  function shortId(s) {
    return s.slice(0, 8) + "…";
  }
  function containerPath(sim, item) {
    var kind = item.kind === "group" ? "Shared/AppGroup/" : "Data/Application/";
    var tail = item.kind === "ext" ? "Data/PluginKitPlugin/" : kind;
    return DEV_ROOT + shortId(sim.udid) + "/data/Containers/" + tail + "4B7D9E21-…";
  }

  var demo = (function () {
    var desk = document.getElementById("desk");
    var anchor = document.getElementById("menu-anchor");
    var statusItem = document.getElementById("status-item");
    var winLayer = document.getElementById("win-layer");
    var toastEl = document.getElementById("toast");
    var hint = document.getElementById("tap-hint");
    var modifier = "none";
    var loginOn = true;
    var menuEl = null;
    var openRow = null;
    var toastTimer = 0;
    var canHover = matchMedia("(hover: hover)").matches;

    function row(opts) {
      var b = document.createElement("button");
      b.type = "button";
      b.className = "row" + (opts.hdr ? " hdr" : "");
      b.setAttribute("role", "menuitem");
      var html = "";
      if (opts.check !== undefined) {
        html += '<span class="check">' + (opts.check ? "✓" : "") + "</span>";
      }
      if (opts.icon) {
        html += '<span class="ic' + (opts.sym ? " sym" : "") + '"' + (opts.color ? ' style="background:' + opts.color + '"' : "") + ">" + ICONS[opts.icon] + "</span>";
      }
      html += '<span class="lbl">' + esc(opts.label) + "</span>";
      if (opts.kbd) {
        html += '<span class="kbd">' + opts.kbd + "</span>";
      }
      if (opts.sub) {
        html += ICONS.chev;
        b.setAttribute("aria-haspopup", "menu");
        b.setAttribute("aria-expanded", "false");
      }
      b.innerHTML = html;
      if (opts.sub) {
        b._buildSub = opts.sub;
        if (canHover) {
          b.addEventListener("pointerenter", function () {
            openSub(b);
          });
        }
      } else if (canHover) {
        b.addEventListener("pointerenter", function () {
          // 只有主菜单里的普通条目才收起已展开的子菜单
          if (b.parentElement && !b.parentElement.classList.contains("sub-menu")) {
            closeSub();
          }
        });
      }
      b.addEventListener("click", function (e) {
        e.stopPropagation();
        if (opts.sub) {
          // App 条目本身可以点击（按修饰键选择打开位置）；标题行只展开子菜单
          if (opts.onClick && (canHover || openRow === b)) {
            opts.onClick(e);
            return;
          }
          openSub(b);
          return;
        }
        if (opts.onClick) {
          opts.onClick(e);
        }
      });
      return b;
    }
    function sep() {
      var d = document.createElement("div");
      d.className = "sep";
      d.setAttribute("role", "separator");
      return d;
    }
    function menuBox(extra) {
      var m = document.createElement("div");
      m.className = "menu" + (extra ? " " + extra : "");
      m.setAttribute("role", "menu");
      return m;
    }

    function openSub(r) {
      if (openRow === r) {
        return;
      }
      closeSub();
      openRow = r;
      r.classList.add("on");
      r.setAttribute("aria-expanded", "true");
      var sub = menuBox("sub-menu");
      r._buildSub(sub);
      sub.addEventListener("pointerenter", function () {
        r.classList.add("on");
      });
      r.appendChild(sub);
    }
    function closeSub() {
      if (!openRow) {
        return;
      }
      openRow.classList.remove("on");
      openRow.setAttribute("aria-expanded", "false");
      var s = openRow.querySelector(".sub-menu");
      if (s) {
        s.remove();
      }
      openRow = null;
    }

    function containerSub(sim, item) {
      return function (sub) {
        var path = containerPath(sim, item);
        sub.appendChild(row({ icon: "finder", label: t("m.finder"), kbd: "⌘1", onClick: function () { act(function () { finderWin(item, path); }); } }));
        sub.appendChild(row({ icon: "term", label: t("m.terminal"), kbd: "⌘2", onClick: function () { act(function () { termWin("Terminal", path); }); } }));
        sub.appendChild(row({ icon: "iterm", label: "iTerm", kbd: "⌘3", onClick: function () { act(function () { termWin("iTerm2", path); }); } }));
        if (item.realm) {
          sub.appendChild(row({ label: t("m.realm"), onClick: function () { act(function () { toast(t("t.realm")); }); } }));
        }
        if (item.kind === "app") {
          sub.appendChild(sep());
          sub.appendChild(row({ label: t("m.bundle"), onClick: function () { act(function () { bundleWin(sim, item); }); } }));
          sub.appendChild(row({ label: "UserDefaults plist", onClick: function () { act(function () { plistWin(item, path); }); } }));
        }
        sub.appendChild(sep());
        sub.appendChild(row({ label: t("m.copyPath"), onClick: function () { act(function () { copied(path); }); } }));
        sub.appendChild(row({ label: t("m.copyID"), onClick: function () { act(function () { copied(item.id); }); } }));
        sub.appendChild(sep());
        sub.appendChild(row({ label: t("m.reset"), onClick: function () { act(function () { resetDlg(item, path); }); } }));
      };
    }

    function build() {
      var m = menuBox();
      SIMS.forEach(function (sim, si) {
        if (si > 0) {
          m.appendChild(sep());
        }
        var title = sim.name + " · " + sim.os + (sim.booted ? " (" + t("m.booted") + ")" : "");
        m.appendChild(row({
          hdr: true, label: title,
          sub: function (sub) {
            sub.appendChild(row({ label: t("m.deviceFolder"), onClick: function () { act(function () { deviceWin(sim); }); } }));
            sub.appendChild(row({ label: t("m.copyUDID"), onClick: function () { act(function () { copied(sim.udid); }); } }));
          }
        }));
        sim.items.forEach(function (item) {
          var label = item.kind === "app" ? item.name + " " + item.ver : item.name;
          m.appendChild(row({
            icon: item.icon, sym: item.kind !== "app", color: item.color, label: label,
            sub: containerSub(sim, item),
            onClick: function (e) {
              // 点击 App 条目本身：按修饰键决定打开位置
              var mod = e.altKey ? "alt" : e.ctrlKey ? "ctrl" : modifier;
              var path = containerPath(sim, item);
              act(function () {
                if (mod === "alt") {
                  termWin("Terminal", path);
                } else if (mod === "ctrl") {
                  toast(t("t.commander"));
                } else {
                  finderWin(item, path);
                }
              });
            }
          }));
        });
      });
      m.appendChild(sep());
      m.appendChild(row({ label: t("m.login"), check: loginOn, onClick: function () {
        loginOn = !loginOn;
        act(function () { toast(t(loginOn ? "t.loginOn" : "t.loginOff")); });
      } }));
      m.appendChild(row({ label: t("m.update"), onClick: function () { act(function () { toast(t("t.update")); }); } }));
      m.appendChild(sep());
      m.appendChild(row({ label: t("m.about", { v: appVersion }), onClick: function () { act(function () { toast(t("t.about")); }); } }));
      m.appendChild(row({ label: t("m.quit"), kbd: "⌘Q", onClick: function () { act(function () { toast(t("t.quit")); }); } }));
      m.addEventListener("click", function (e) {
        e.stopPropagation();
      });
      return m;
    }

    function openMenu() {
      closeMenu();
      menuEl = build();
      anchor.appendChild(menuEl);
      statusItem.setAttribute("aria-expanded", "true");
      hint.classList.add("gone");
      var first = menuEl.querySelector(".row");
      if (first && !canHover) {
        first.blur();
      }
    }
    function closeMenu() {
      closeSub();
      if (menuEl) {
        menuEl.remove();
        menuEl = null;
      }
      statusItem.setAttribute("aria-expanded", "false");
    }
    // 执行菜单操作：先收起菜单，再展示结果
    function act(fn) {
      closeMenu();
      fn();
    }

    statusItem.addEventListener("click", function (e) {
      e.stopPropagation();
      if (menuEl) {
        closeMenu();
      } else {
        openMenu();
      }
    });
    desk.addEventListener("click", function (e) {
      if (menuEl && !menuEl.contains(e.target)) {
        closeMenu();
      }
    });
    document.addEventListener("keydown", function (e) {
      if (e.key === "Escape") {
        closeMenu();
      }
    });

    // ---- 结果：窗口与提示 ----
    function toast(html) {
      toastEl.innerHTML = html;
      toastEl.classList.add("show");
      clearTimeout(toastTimer);
      toastTimer = setTimeout(function () {
        toastEl.classList.remove("show");
      }, 3200);
    }
    function copied(text) {
      toast(esc(t("t.copied")) + "<code>" + esc(text) + "</code>");
    }
    function showWin(title, path, bodyHTML) {
      var old = winLayer.querySelector(".win");
      if (old) {
        old.remove();
      }
      var w = document.createElement("div");
      w.className = "win";
      w.innerHTML =
        '<div class="win-bar"><button type="button" class="tl" aria-label="' + esc(t("m.close")) + '"></button><span class="tl"></span><span class="tl"></span><span class="ttl">' + esc(title) + "</span></div>" +
        (path ? '<div class="win-path">' + esc(path) + "</div>" : "") + bodyHTML;
      w.querySelector("button.tl").addEventListener("click", function (e) {
        e.stopPropagation();
        w.classList.add("out");
        setTimeout(function () {
          w.remove();
        }, 260);
      });
      winLayer.appendChild(w);
      return w;
    }
    function files(list, selected) {
      return '<div class="win-files">' + list.map(function (f, i) {
        var cls = f.type === "doc" ? "fi doc" : f.type === "app" ? "fi app" : "fi";
        return '<span class="file' + (f.name === selected ? " sel" : "") + '" style="animation-delay:' + (i * 0.06) + 's"><span class="' + cls + '"></span>' + esc(f.name) + "</span>";
      }).join("") + "</div>";
    }
    function finderWin(item, path) {
      var list = item.kind === "app"
        ? [{ name: "Documents" }, { name: "Library" }, { name: "SystemData" }, { name: "tmp" }]
        : [{ name: "Library" }];
      showWin(item.kind === "app" ? item.name : item.id, path, files(list));
    }
    function bundleWin(sim, item) {
      var path = DEV_ROOT + shortId(sim.udid) + "/data/Containers/Bundle/Application/9C1E3A57-…";
      showWin("Finder", path, files([{ name: item.exe + ".app", type: "app" }], item.exe + ".app"));
    }
    function plistWin(item, path) {
      showWin("Preferences", path + "/Library/Preferences", files([{ name: item.id + ".plist", type: "doc" }], item.id + ".plist"));
    }
    function deviceWin(sim) {
      showWin(sim.name, DEV_ROOT + sim.udid, files([{ name: "data" }, { name: "device.plist", type: "doc" }]));
    }
    function termWin(app, path) {
      var body =
        '<pre class="term"><span class="p">~ %</span> cd <span class="c">' + esc(path) + "</span>\n" +
        '<span class="p">4B7D9E21 %</span> ls\nDocuments   Library   SystemData   tmp\n<span class="p">4B7D9E21 %</span> ▍</pre>';
      showWin(app + " — zsh", "", body);
    }
    function resetDlg(item, path) {
      var name = item.kind === "app" ? item.name : item.id;
      var w = showWin("SimBox", "",
        '<div class="dlg"><img src="assets/icon-128.webp" width="52" height="52" alt="" decoding="async"><h4>' + esc(t("m.resetTitle")) + "</h4><p>" + esc(t("m.resetBody", { n: name })) + "</p>" +
        '<div class="acts"><button type="button" class="cancel">' + esc(t("m.cancel")) + '</button><button type="button" class="danger">' + esc(t("m.resetBtn")) + "</button></div></div>");
      w.querySelector(".cancel").addEventListener("click", function (e) {
        e.stopPropagation();
        w.remove();
      });
      w.querySelector(".danger").addEventListener("click", function (e) {
        e.stopPropagation();
        var f = finderAfterReset(item, path);
        f.classList.add("shake");
        toast(esc(t("t.reset", { n: name })));
      });
    }
    function finderAfterReset(item, path) {
      finderWin(item, path);
      return winLayer.querySelector(".win");
    }

    // 修饰键模拟
    document.getElementById("mod-seg").addEventListener("click", function (e) {
      var b = e.target.closest("button");
      if (!b) {
        return;
      }
      modifier = b.dataset.mod;
      document.querySelectorAll("#mod-seg button").forEach(function (x) {
        x.setAttribute("aria-pressed", String(x === b));
      });
    });

    // 菜单栏时钟
    var clock = document.getElementById("mb-clock");
    function tick() {
      var d = new Date();
      clock.textContent = d.getHours() + ":" + String(d.getMinutes()).padStart(2, "0");
    }
    tick();
    setInterval(tick, 30000);

    // 演示区第一次进入视口时自动展开菜单，提示可以操作
    if ("IntersectionObserver" in window) {
      var autoIO = new IntersectionObserver(function (entries) {
        if (entries[0].isIntersecting) {
          autoIO.disconnect();
          setTimeout(function () {
            if (!menuEl) {
              openMenu();
            }
          }, 700);
        }
      }, { threshold: .55 });
      autoIO.observe(desk);
    }

    return {
      relabel: function () {
        // 语言切换后重建已打开的菜单，窗口与提示收起
        if (menuEl) {
          openMenu();
        }
        toastEl.classList.remove("show");
        winLayer.innerHTML = "";
      }
    };
  })();

  // ---------- 下载：识别 Intel，并用 API 把按钮换成最新 DMG 直链 ----------
  (function () {
    var arm = document.getElementById("dl-arm");
    var intel = document.getElementById("dl-intel");
    try {
      var gl = document.createElement("canvas").getContext("webgl");
      var info = gl && gl.getExtension("WEBGL_debug_renderer_info");
      var renderer = info ? String(gl.getParameter(info.UNMASKED_RENDERER_WEBGL)) : "";
      if (/Intel|AMD|Radeon/i.test(renderer) && !/Apple/i.test(renderer)) {
        arm.className = "btn btn-alt";
        intel.className = "btn btn-main";
        document.getElementById("downloads").prepend(intel);
      }
    } catch (e) {}

    if (!window.fetch) {
      return;
    }
    fetch("https://api.github.com/repos/wangwanjie/SimBox/releases/latest", { headers: { Accept: "application/vnd.github+json" } })
      .then(function (r) {
        return r.ok ? r.json() : null;
      })
      .then(function (rel) {
        if (!rel) {
          return;
        }
        if (rel.tag_name) {
          document.getElementById("version").textContent = rel.tag_name;
          appVersion = String(rel.tag_name).replace(/^v/, "");
        }
        (rel.assets || []).forEach(function (a) {
          if (/_arm64\.dmg$/i.test(a.name)) {
            arm.href = a.browser_download_url;
          } else if (/_x86_64\.dmg$/i.test(a.name)) {
            intel.href = a.browser_download_url;
          }
        });
      })
      .catch(function () {});
  })();

  // ---------- 初始化 ----------
  applyTheme(params.get("theme") || load("simbox.theme") || "system", false);
  applyLang(normalizeLang(params.get("lang")) || normalizeLang(load("simbox.lang")) || detectLang(), false);
  if (document.readyState === "complete") {
    setTimeout(unbox, 250);
  } else {
    window.addEventListener("load", function () {
      setTimeout(unbox, 250);
    });
  }
})();
