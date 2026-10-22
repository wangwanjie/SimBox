#!/usr/bin/env swift
//
// 生成一份 CoreSimulator 风格的演示数据，用于截取 README 主界面图。
// 用法: swift scripts/screenshot/make_demo_devices.swift <输出目录>
//

import AppKit
import Foundation

let arguments = CommandLine.arguments
guard arguments.count == 2 else {
    FileHandle.standardError.write(Data("用法: make_demo_devices.swift <输出目录>\n".utf8))
    exit(1)
}

let root = URL(fileURLWithPath: arguments[1], isDirectory: true)
let fm = FileManager.default
try? fm.removeItem(at: root)
try fm.createDirectory(at: root, withIntermediateDirectories: true)

func writePlist(_ plist: [String: Any], to url: URL) throws {
    let data = try PropertyListSerialization.data(fromPropertyList: plist, format: .xml, options: 0)
    try data.write(to: url)
}

func writeMetadata(_ identifier: String, in container: URL) throws {
    try writePlist(
        ["MCMMetadataIdentifier": identifier],
        to: container.appendingPathComponent(".com.apple.mobile_container_manager.metadata.plist")
    )
}

/// 渐变底 + SF Symbol 的 120×120 图标。
func makeIcon(symbol: String, colors: [NSColor], to url: URL) throws {
    let size = 120
    guard let rep = NSBitmapImageRep(
        bitmapDataPlanes: nil, pixelsWide: size, pixelsHigh: size, bitsPerSample: 8, samplesPerPixel: 4,
        hasAlpha: true, isPlanar: false, colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0
    ) else {
        throw NSError(domain: "demo", code: 1)
    }
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)
    let rect = NSRect(x: 0, y: 0, width: size, height: size)
    NSGradient(colors: colors)?.draw(in: rect, angle: -60)
    let config = NSImage.SymbolConfiguration(pointSize: 64, weight: .semibold)
        .applying(.init(paletteColors: [.white]))
    if let image = NSImage(systemSymbolName: symbol, accessibilityDescription: nil)?.withSymbolConfiguration(config) {
        let imageSize = image.size
        image.draw(in: NSRect(
            x: (CGFloat(size) - imageSize.width) / 2,
            y: (CGFloat(size) - imageSize.height) / 2,
            width: imageSize.width,
            height: imageSize.height
        ))
    }
    NSGraphicsContext.restoreGraphicsState()
    guard let png = rep.representation(using: .png, properties: [:]) else {
        throw NSError(domain: "demo", code: 2)
    }
    try png.write(to: url)
}

struct DemoApp {
    let name: String
    let bundleID: String
    let version: String
    let build: String
    let symbol: String
    let colors: [NSColor]
    var realm = false
}

func addDevice(
    name: String,
    runtime: String,
    booted: Bool,
    minutesAgo: Double,
    apps: [DemoApp],
    groups: [String],
    extensions: [String]
) throws {
    let udid = UUID().uuidString
    let device = root.appendingPathComponent(udid, isDirectory: true)
    try fm.createDirectory(at: device, withIntermediateDirectories: true)
    try writePlist([
        "UDID": udid,
        "name": name,
        "runtime": runtime,
        "state": booted ? 3 : 1,
        "isDeleted": false,
        "lastUsedAt": Date().addingTimeInterval(-minutesAgo * 60)
    ], to: device.appendingPathComponent("device.plist"))

    let containers = device.appendingPathComponent("data/Containers", isDirectory: true)
    for (index, app) in apps.enumerated() {
        let bundleContainer = containers.appendingPathComponent("Bundle/Application/\(UUID().uuidString)", isDirectory: true)
        let appFolder = bundleContainer.appendingPathComponent("\(app.name.replacingOccurrences(of: " ", with: "")).app", isDirectory: true)
        try fm.createDirectory(at: appFolder, withIntermediateDirectories: true)
        try writeMetadata(app.bundleID, in: bundleContainer)
        try writePlist([
            "CFBundleDisplayName": app.name,
            "CFBundleShortVersionString": app.version,
            "CFBundleVersion": app.build,
            "CFBundleIcons": ["CFBundlePrimaryIcon": ["CFBundleIconFiles": ["AppIcon60x60"]]]
        ], to: appFolder.appendingPathComponent("Info.plist"))
        try makeIcon(symbol: app.symbol, colors: app.colors, to: appFolder.appendingPathComponent("AppIcon60x60@2x.png"))

        let data = containers.appendingPathComponent("Data/Application/\(UUID().uuidString)", isDirectory: true)
        for sub in ["Documents", "Library/Caches", "Library/Preferences", "tmp"] {
            try fm.createDirectory(at: data.appendingPathComponent(sub), withIntermediateDirectories: true)
        }
        try writeMetadata(app.bundleID, in: data)
        try writePlist(["onboardingDone": true], to: data.appendingPathComponent("Library/Preferences/\(app.bundleID).plist"))
        if app.realm {
            try Data().write(to: data.appendingPathComponent("Documents/default.realm"))
        }
        // 让列表顺序稳定：越靠前的 app 修改时间越新。
        try fm.setAttributes([.modificationDate: Date().addingTimeInterval(Double(-index) * 600)], ofItemAtPath: data.path)
    }
    for (kind, identifiers) in [("Shared/AppGroup", groups), ("Data/PluginKitPlugin", extensions)] {
        for identifier in identifiers {
            let container = containers.appendingPathComponent("\(kind)/\(UUID().uuidString)", isDirectory: true)
            try fm.createDirectory(at: container.appendingPathComponent("Library"), withIntermediateDirectories: true)
            try writeMetadata(identifier, in: container)
        }
    }
}

let palette: [String: [NSColor]] = [
    "blue": [NSColor(calibratedRed: 0.24, green: 0.56, blue: 1, alpha: 1), NSColor(calibratedRed: 0.12, green: 0.32, blue: 0.86, alpha: 1)],
    "orange": [
        NSColor(calibratedRed: 1, green: 0.66, blue: 0.2, alpha: 1),
        NSColor(calibratedRed: 0.95, green: 0.36, blue: 0.16, alpha: 1)
    ],
    "green": [NSColor(calibratedRed: 0.3, green: 0.85, blue: 0.5, alpha: 1), NSColor(calibratedRed: 0.08, green: 0.6, blue: 0.4, alpha: 1)],
    "purple": [NSColor(calibratedRed: 0.7, green: 0.45, blue: 1, alpha: 1), NSColor(calibratedRed: 0.42, green: 0.2, blue: 0.85, alpha: 1)],
    "pink": [NSColor(calibratedRed: 1, green: 0.45, blue: 0.6, alpha: 1), NSColor(calibratedRed: 0.86, green: 0.18, blue: 0.4, alpha: 1)]
]

try addDevice(
    name: "iPhone 18 Pro",
    runtime: "com.apple.CoreSimulator.SimRuntime.iOS-27-0",
    booted: true,
    minutesAgo: 1,
    apps: [
        DemoApp(
            name: "Weather Lab",
            bundleID: "com.example.weatherlab",
            version: "3.2.0",
            build: "412",
            symbol: "cloud.sun.fill",
            colors: palette["blue"]!,
            realm: true
        ),
        DemoApp(
            name: "Recipe Box",
            bundleID: "com.example.recipebox",
            version: "1.8.1",
            build: "77",
            symbol: "fork.knife",
            colors: palette["orange"]!
        ),
        DemoApp(
            name: "Trail Tracker",
            bundleID: "com.example.trails",
            version: "2.0.0",
            build: "2001",
            symbol: "figure.hiking",
            colors: palette["green"]!
        )
    ],
    groups: ["group.com.example.weatherlab"],
    extensions: ["com.example.weatherlab.widget"]
)
try addDevice(
    name: "iPad Pro 13-inch (M5)",
    runtime: "com.apple.CoreSimulator.SimRuntime.iOS-27-0",
    booted: false,
    minutesAgo: 90,
    apps: [
        DemoApp(
            name: "Sketchbook",
            bundleID: "com.example.sketchbook",
            version: "5.1",
            build: "530",
            symbol: "paintbrush.pointed.fill",
            colors: palette["purple"]!
        )
    ],
    groups: [],
    extensions: []
)
try addDevice(
    name: "Apple Watch Series 11 (46mm)",
    runtime: "com.apple.CoreSimulator.SimRuntime.watchOS-27-0",
    booted: false,
    minutesAgo: 300,
    apps: [
        DemoApp(
            name: "Pulse",
            bundleID: "com.example.pulse.watchkitapp",
            version: "1.0",
            build: "12",
            symbol: "heart.fill",
            colors: palette["pink"]!
        )
    ],
    groups: [],
    extensions: []
)
print("演示数据已生成: \(root.path)")
