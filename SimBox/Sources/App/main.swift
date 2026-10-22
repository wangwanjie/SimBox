import AppKit

// AppDelegate 标注了 @MainActor，入口代码本身运行在主线程，这里显式声明隔离域。
MainActor.assumeIsolated {
    let app = NSApplication.shared
    let delegate = AppDelegate()
    app.delegate = delegate
    app.run()
}
