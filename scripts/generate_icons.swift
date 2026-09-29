#!/usr/bin/env swift
//
// 生成 SimBox 的 App 图标与菜单栏图标。
// 使用: swift scripts/generate_icons.swift
// 会写入 SimBox/Resources/Assets.xcassets/ 下的 AppIcon、MenuBarIcon 和 AppIconFallback。
//

import AppKit
import Foundation

let projectDir = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
let assetsDir = projectDir
    .appendingPathComponent("SimBox/Resources/Assets.xcassets")

@discardableResult
func writePNG(_ image: NSImage, size: CGSize, to url: URL, isTemplate: Bool = false) -> Bool {
    let rep = NSBitmapImageRep(
        bitmapDataPlanes: nil,
        pixelsWide: Int(size.width),
        pixelsHigh: Int(size.height),
        bitsPerSample: 8,
        samplesPerPixel: 4,
        hasAlpha: true,
        isPlanar: false,
        colorSpaceName: .deviceRGB,
        bytesPerRow: 0,
        bitsPerPixel: 0
    )!
    rep.size = size

    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)
    let rect = CGRect(origin: .zero, size: size)
    image.draw(in: rect, from: .zero, operation: .copy, fraction: 1)
    NSGraphicsContext.restoreGraphicsState()

    guard let data = rep.representation(using: .png, properties: [:]) else {
        FileHandle.standardError.write(Data("[icons] png encode failed: \(url.lastPathComponent)\n".utf8))
        return false
    }
    do {
        try data.write(to: url)
        return true
    } catch {
        FileHandle.standardError.write(Data("[icons] write failed: \(error)\n".utf8))
        return false
    }
}

func drawAppIcon(size: CGFloat) -> NSImage {
    let image = NSImage(size: NSSize(width: size, height: size))
    image.lockFocusFlipped(false)
    guard let ctx = NSGraphicsContext.current?.cgContext else {
        image.unlockFocus()
        return image
    }

    let bounds = CGRect(x: 0, y: 0, width: size, height: size)
    let radius = size * 0.225

    // Rounded background with vertical gradient (indigo → violet)
    let bgPath = CGPath(roundedRect: bounds, cornerWidth: radius, cornerHeight: radius, transform: nil)
    ctx.saveGState()
    ctx.addPath(bgPath)
    ctx.clip()

    let colors = [
        CGColor(srgbRed: 0.35, green: 0.42, blue: 0.95, alpha: 1),
        CGColor(srgbRed: 0.62, green: 0.30, blue: 0.90, alpha: 1)
    ] as CFArray
    let gradient = CGGradient(
        colorsSpace: CGColorSpace(name: CGColorSpace.sRGB),
        colors: colors,
        locations: [0, 1]
    )!
    ctx.drawLinearGradient(
        gradient,
        start: CGPoint(x: 0, y: size),
        end: CGPoint(x: size, y: 0),
        options: []
    )

    // Soft highlight on top-left
    let highlight = CGGradient(
        colorsSpace: CGColorSpace(name: CGColorSpace.sRGB),
        colors: [
            CGColor(srgbRed: 1, green: 1, blue: 1, alpha: 0.24),
            CGColor(srgbRed: 1, green: 1, blue: 1, alpha: 0)
        ] as CFArray,
        locations: [0, 1]
    )!
    ctx.drawRadialGradient(
        highlight,
        startCenter: CGPoint(x: size * 0.25, y: size * 0.78),
        startRadius: 0,
        endCenter: CGPoint(x: size * 0.25, y: size * 0.78),
        endRadius: size * 0.55,
        options: []
    )
    ctx.restoreGState()

    // Phone body — rounded rect centered
    let deviceWidth = size * 0.44
    let deviceHeight = size * 0.66
    let deviceRadius = size * 0.09
    let deviceRect = CGRect(
        x: (size - deviceWidth) / 2,
        y: (size - deviceHeight) / 2,
        width: deviceWidth,
        height: deviceHeight
    )
    let devicePath = CGPath(
        roundedRect: deviceRect,
        cornerWidth: deviceRadius,
        cornerHeight: deviceRadius,
        transform: nil
    )

    ctx.saveGState()
    ctx.setShadow(
        offset: CGSize(width: 0, height: -size * 0.02),
        blur: size * 0.08,
        color: CGColor(srgbRed: 0, green: 0, blue: 0, alpha: 0.28)
    )
    ctx.addPath(devicePath)
    ctx.setFillColor(CGColor(srgbRed: 0.99, green: 0.99, blue: 1, alpha: 1))
    ctx.fillPath()
    ctx.restoreGState()

    // Screen inset
    let screenInset = size * 0.045
    let screenRect = deviceRect.insetBy(dx: screenInset, dy: screenInset * 1.3)
    let screenPath = CGPath(
        roundedRect: screenRect,
        cornerWidth: deviceRadius * 0.55,
        cornerHeight: deviceRadius * 0.55,
        transform: nil
    )
    ctx.addPath(screenPath)
    ctx.setFillColor(CGColor(srgbRed: 0.10, green: 0.14, blue: 0.24, alpha: 1))
    ctx.fillPath()

    // Screen gradient shine
    ctx.saveGState()
    ctx.addPath(screenPath)
    ctx.clip()
    let screenGrad = CGGradient(
        colorsSpace: CGColorSpace(name: CGColorSpace.sRGB),
        colors: [
            CGColor(srgbRed: 0.30, green: 0.55, blue: 0.98, alpha: 0.75),
            CGColor(srgbRed: 0.72, green: 0.36, blue: 0.98, alpha: 0.35)
        ] as CFArray,
        locations: [0, 1]
    )!
    ctx.drawLinearGradient(
        screenGrad,
        start: CGPoint(x: screenRect.minX, y: screenRect.maxY),
        end: CGPoint(x: screenRect.maxX, y: screenRect.minY),
        options: []
    )
    ctx.restoreGState()

    // App tiles inside the screen
    let cols = 3
    let rows = 4
    let tileGap = size * 0.022
    let tileArea = screenRect.insetBy(dx: tileGap * 2, dy: tileGap * 2.4)
    let tileSize = min(
        (tileArea.width - CGFloat(cols - 1) * tileGap) / CGFloat(cols),
        (tileArea.height - CGFloat(rows - 1) * tileGap) / CGFloat(rows)
    )
    let tileRadius = tileSize * 0.24
    let tileColors: [CGColor] = [
        CGColor(srgbRed: 1, green: 0.75, blue: 0.34, alpha: 0.95),
        CGColor(srgbRed: 0.99, green: 0.42, blue: 0.55, alpha: 0.95),
        CGColor(srgbRed: 0.32, green: 0.86, blue: 0.66, alpha: 0.95),
        CGColor(srgbRed: 0.42, green: 0.72, blue: 1, alpha: 0.95)
    ]
    let originX = tileArea.midX - (CGFloat(cols) * tileSize + CGFloat(cols - 1) * tileGap) / 2
    let originY = tileArea.midY - (CGFloat(rows) * tileSize + CGFloat(rows - 1) * tileGap) / 2

    for row in 0..<rows {
        for col in 0..<cols {
            let tileRect = CGRect(
                x: originX + CGFloat(col) * (tileSize + tileGap),
                y: originY + CGFloat(row) * (tileSize + tileGap),
                width: tileSize,
                height: tileSize
            )
            let tilePath = CGPath(
                roundedRect: tileRect,
                cornerWidth: tileRadius,
                cornerHeight: tileRadius,
                transform: nil
            )
            ctx.addPath(tilePath)
            ctx.setFillColor(tileColors[(row * cols + col) % tileColors.count])
            ctx.fillPath()
        }
    }

    // Home indicator
    let indicatorWidth = deviceWidth * 0.32
    let indicatorHeight = size * 0.012
    let indicatorRect = CGRect(
        x: deviceRect.midX - indicatorWidth / 2,
        y: deviceRect.minY + size * 0.028,
        width: indicatorWidth,
        height: indicatorHeight
    )
    ctx.addPath(CGPath(
        roundedRect: indicatorRect,
        cornerWidth: indicatorHeight / 2,
        cornerHeight: indicatorHeight / 2,
        transform: nil
    ))
    ctx.setFillColor(CGColor(srgbRed: 0.60, green: 0.62, blue: 0.72, alpha: 0.9))
    ctx.fillPath()

    // Camera dot
    let dotSize = size * 0.03
    ctx.addEllipse(in: CGRect(
        x: deviceRect.midX - dotSize / 2,
        y: deviceRect.maxY - size * 0.05,
        width: dotSize,
        height: dotSize
    ))
    ctx.setFillColor(CGColor(srgbRed: 0.18, green: 0.20, blue: 0.28, alpha: 1))
    ctx.fillPath()

    image.unlockFocus()
    return image
}

func drawMenuBarIcon(size: CGFloat) -> NSImage {
    let image = NSImage(size: NSSize(width: size, height: size))
    image.lockFocusFlipped(false)
    guard let ctx = NSGraphicsContext.current?.cgContext else {
        image.unlockFocus()
        return image
    }

    let phoneWidth = size * 0.66
    let phoneHeight = size * 0.94
    let outerRect = CGRect(
        x: (size - phoneWidth) / 2,
        y: (size - phoneHeight) / 2,
        width: phoneWidth,
        height: phoneHeight
    )
    let cornerRadius = size * 0.18

    // Solid rounded rectangle body (the whole shape reads even at 18pt).
    ctx.addPath(CGPath(
        roundedRect: outerRect,
        cornerWidth: cornerRadius,
        cornerHeight: cornerRadius,
        transform: nil
    ))
    ctx.setFillColor(CGColor(gray: 0, alpha: 1))
    ctx.fillPath()

    // Screen cutout — clear pixels so template rendering shows the ring.
    let screenInset = size * 0.13
    let screenRect = outerRect.insetBy(dx: screenInset, dy: screenInset * 1.15)
    let screenPath = CGPath(
        roundedRect: screenRect,
        cornerWidth: cornerRadius * 0.55,
        cornerHeight: cornerRadius * 0.55,
        transform: nil
    )
    ctx.setBlendMode(.clear)
    ctx.addPath(screenPath)
    ctx.fillPath()
    ctx.setBlendMode(.normal)

    // Home indicator bar centered near the bottom of the phone.
    let indicatorWidth = phoneWidth * 0.28
    let indicatorHeight = max(1, size * 0.055)
    let indicatorRect = CGRect(
        x: outerRect.midX - indicatorWidth / 2,
        y: outerRect.minY + size * 0.045,
        width: indicatorWidth,
        height: indicatorHeight
    )
    ctx.addPath(CGPath(
        roundedRect: indicatorRect,
        cornerWidth: indicatorHeight / 2,
        cornerHeight: indicatorHeight / 2,
        transform: nil
    ))
    ctx.setFillColor(CGColor(gray: 0, alpha: 1))
    ctx.fillPath()

    image.unlockFocus()
    image.isTemplate = true
    return image
}

func drawFallbackIcon(size: CGFloat) -> NSImage {
    let image = NSImage(size: NSSize(width: size, height: size))
    image.lockFocusFlipped(false)
    guard let ctx = NSGraphicsContext.current?.cgContext else {
        image.unlockFocus()
        return image
    }
    let bounds = CGRect(x: 0, y: 0, width: size, height: size)
    let radius = size * 0.22
    ctx.addPath(CGPath(roundedRect: bounds, cornerWidth: radius, cornerHeight: radius, transform: nil))
    ctx.setFillColor(CGColor(srgbRed: 0.86, green: 0.87, blue: 0.92, alpha: 1))
    ctx.fillPath()

    let glyph = "?" as NSString
    let font = NSFont.systemFont(ofSize: size * 0.6, weight: .semibold)
    let paragraph = NSMutableParagraphStyle()
    paragraph.alignment = .center
    let attributes: [NSAttributedString.Key: Any] = [
        .font: font,
        .foregroundColor: NSColor(srgbRed: 0.55, green: 0.58, blue: 0.72, alpha: 1),
        .paragraphStyle: paragraph
    ]
    let textSize = glyph.size(withAttributes: attributes)
    let textRect = CGRect(
        x: 0,
        y: (size - textSize.height) / 2,
        width: size,
        height: textSize.height
    )
    glyph.draw(in: textRect, withAttributes: attributes)
    image.unlockFocus()
    return image
}

func writeContentsJSON(_ contents: [String: Any], to url: URL) throws {
    let data = try JSONSerialization.data(withJSONObject: contents, options: [.prettyPrinted, .sortedKeys])
    try data.write(to: url)
}

// MARK: - App icon set

let appIconDir = assetsDir.appendingPathComponent("AppIcon.appiconset")
try? FileManager.default.createDirectory(at: appIconDir, withIntermediateDirectories: true)

struct AppIconEntry {
    let size: CGFloat
    let scale: Int
}

let appIconSizes: [AppIconEntry] = [
    .init(size: 16, scale: 1),
    .init(size: 16, scale: 2),
    .init(size: 32, scale: 1),
    .init(size: 32, scale: 2),
    .init(size: 128, scale: 1),
    .init(size: 128, scale: 2),
    .init(size: 256, scale: 1),
    .init(size: 256, scale: 2),
    .init(size: 512, scale: 1),
    .init(size: 512, scale: 2)
]

var appIconImages: [[String: Any]] = []
for entry in appIconSizes {
    let pixelSize = entry.size * CGFloat(entry.scale)
    let image = drawAppIcon(size: pixelSize)
    let filename = "icon_\(Int(entry.size))x\(Int(entry.size))@\(entry.scale)x.png"
    let target = appIconDir.appendingPathComponent(filename)
    writePNG(image, size: CGSize(width: pixelSize, height: pixelSize), to: target)
    appIconImages.append([
        "size": "\(Int(entry.size))x\(Int(entry.size))",
        "idiom": "mac",
        "filename": filename,
        "scale": "\(entry.scale)x"
    ])
}

try writeContentsJSON(
    [
        "images": appIconImages,
        "info": ["author": "xcode", "version": 1]
    ],
    to: appIconDir.appendingPathComponent("Contents.json")
)

// MARK: - Menu bar icon

let menuBarDir = assetsDir.appendingPathComponent("MenuBarIcon.imageset")
try? FileManager.default.createDirectory(at: menuBarDir, withIntermediateDirectories: true)

let menuBar1x = drawMenuBarIcon(size: 18)
let menuBar2x = drawMenuBarIcon(size: 36)
writePNG(menuBar1x, size: CGSize(width: 18, height: 18), to: menuBarDir.appendingPathComponent("MenuBarIcon.png"))
writePNG(menuBar2x, size: CGSize(width: 36, height: 36), to: menuBarDir.appendingPathComponent("MenuBarIcon@2x.png"))
try writeContentsJSON(
    [
        "images": [
            ["idiom": "universal", "filename": "MenuBarIcon.png", "scale": "1x"],
            ["idiom": "universal", "filename": "MenuBarIcon@2x.png", "scale": "2x"]
        ],
        "info": ["author": "xcode", "version": 1],
        "properties": ["template-rendering-intent": "template"]
    ],
    to: menuBarDir.appendingPathComponent("Contents.json")
)

// MARK: - App icon fallback

let fallbackDir = assetsDir.appendingPathComponent("AppIconFallback.imageset")
try? FileManager.default.createDirectory(at: fallbackDir, withIntermediateDirectories: true)

let fallback1x = drawFallbackIcon(size: 48)
let fallback2x = drawFallbackIcon(size: 96)
writePNG(fallback1x, size: CGSize(width: 48, height: 48), to: fallbackDir.appendingPathComponent("Fallback.png"))
writePNG(fallback2x, size: CGSize(width: 96, height: 96), to: fallbackDir.appendingPathComponent("Fallback@2x.png"))
try writeContentsJSON(
    [
        "images": [
            ["idiom": "universal", "filename": "Fallback.png", "scale": "1x"],
            ["idiom": "universal", "filename": "Fallback@2x.png", "scale": "2x"]
        ],
        "info": ["author": "xcode", "version": 1]
    ],
    to: fallbackDir.appendingPathComponent("Contents.json")
)

// MARK: - Root Contents.json

try writeContentsJSON(
    ["info": ["author": "xcode", "version": 1]],
    to: assetsDir.appendingPathComponent("Contents.json")
)

print("[icons] wrote assets to \(assetsDir.path)")
