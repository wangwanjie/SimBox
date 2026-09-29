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

    // Rounded background with diagonal gradient (indigo → violet)
    let bgPath = CGPath(roundedRect: bounds, cornerWidth: radius, cornerHeight: radius, transform: nil)
    ctx.saveGState()
    ctx.addPath(bgPath)
    ctx.clip()

    let bgColors = [
        CGColor(srgbRed: 0.30, green: 0.38, blue: 0.94, alpha: 1),
        CGColor(srgbRed: 0.60, green: 0.28, blue: 0.90, alpha: 1)
    ] as CFArray
    let bgGradient = CGGradient(
        colorsSpace: CGColorSpace(name: CGColorSpace.sRGB),
        colors: bgColors,
        locations: [0, 1]
    )!
    ctx.drawLinearGradient(
        bgGradient,
        start: CGPoint(x: 0, y: size),
        end: CGPoint(x: size, y: 0),
        options: []
    )

    // Soft top-left highlight
    let highlight = CGGradient(
        colorsSpace: CGColorSpace(name: CGColorSpace.sRGB),
        colors: [
            CGColor(srgbRed: 1, green: 1, blue: 1, alpha: 0.22),
            CGColor(srgbRed: 1, green: 1, blue: 1, alpha: 0)
        ] as CFArray,
        locations: [0, 1]
    )!
    ctx.drawRadialGradient(
        highlight,
        startCenter: CGPoint(x: size * 0.28, y: size * 0.78),
        startRadius: 0,
        endCenter: CGPoint(x: size * 0.28, y: size * 0.78),
        endRadius: size * 0.55,
        options: []
    )
    ctx.restoreGState()

    // Isometric open box + phone poking out.
    let cos30: CGFloat = 0.8660254
    let boxScale = size * 0.34
    let bx = boxScale
    let bz = boxScale
    let by = boxScale * 0.60

    let projHeight = by + (bx + bz) * 0.5
    let originX = size / 2
    let originY = size * 0.44 - projHeight / 2

    func iso(_ x: CGFloat, _ y: CGFloat, _ z: CGFloat) -> CGPoint {
        return CGPoint(
            x: originX + (x - z) * cos30,
            y: originY + y + (x + z) * 0.5
        )
    }

    // Ground shadow beneath the box
    ctx.saveGState()
    ctx.setShadow(
        offset: .zero,
        blur: size * 0.06,
        color: CGColor(srgbRed: 0, green: 0, blue: 0, alpha: 0.55)
    )
    let shadowRect = CGRect(
        x: originX - (bx + bz) * cos30 * 0.55,
        y: originY - size * 0.045,
        width: (bx + bz) * cos30 * 1.10,
        height: size * 0.055
    )
    ctx.setFillColor(CGColor(srgbRed: 0, green: 0, blue: 0, alpha: 0.35))
    ctx.fillEllipse(in: shadowRect)
    ctx.restoreGState()

    // Box palette — warm cream tones.
    let cFront = CGColor(srgbRed: 0.98, green: 0.87, blue: 0.66, alpha: 1)
    let cSide = CGColor(srgbRed: 0.83, green: 0.69, blue: 0.46, alpha: 1)
    let cRim = CGColor(srgbRed: 1.00, green: 0.93, blue: 0.75, alpha: 1)
    let cInside = CGColor(srgbRed: 0.16, green: 0.11, blue: 0.22, alpha: 1)

    let fp0 = iso(0, 0, 0)
    let fp1 = iso(bx, 0, 0)
    let bp3 = iso(0, 0, bz)
    let fp2 = iso(bx, by, 0)
    let fp3 = iso(0, by, 0)
    let sp2 = iso(bx, by, bz)
    let rp3 = iso(0, by, bz)

    // Front-right face (facing camera on the right).
    ctx.beginPath()
    ctx.move(to: fp0); ctx.addLine(to: fp1); ctx.addLine(to: fp2); ctx.addLine(to: fp3); ctx.closePath()
    ctx.setFillColor(cFront); ctx.fillPath()

    // Front-left face (facing camera on the left) — darker for depth.
    ctx.beginPath()
    ctx.move(to: fp0); ctx.addLine(to: bp3); ctx.addLine(to: rp3); ctx.addLine(to: fp3); ctx.closePath()
    ctx.setFillColor(cSide); ctx.fillPath()

    // Top rim.
    ctx.beginPath()
    ctx.move(to: fp3); ctx.addLine(to: fp2); ctx.addLine(to: sp2); ctx.addLine(to: rp3); ctx.closePath()
    ctx.setFillColor(cRim); ctx.fillPath()

    // Interior opening — inset rhombus, dark.
    let wallT = boxScale * 0.09
    let ip0 = iso(wallT, by, wallT)
    let ip1 = iso(bx - wallT, by, wallT)
    let ip2 = iso(bx - wallT, by, bz - wallT)
    let ip3 = iso(wallT, by, bz - wallT)
    ctx.beginPath()
    ctx.move(to: ip0); ctx.addLine(to: ip1); ctx.addLine(to: ip2); ctx.addLine(to: ip3); ctx.closePath()
    ctx.setFillColor(cInside); ctx.fillPath()

    // Phone rising from the opening (billboard, facing viewer).
    let openingCenter = iso(bx / 2, by, bz / 2)
    let phoneW = size * 0.19
    let phoneH = size * 0.40
    let phoneBottomY = openingCenter.y - phoneH * 0.06
    let phoneRect = CGRect(
        x: openingCenter.x - phoneW / 2,
        y: phoneBottomY,
        width: phoneW,
        height: phoneH
    )
    let phoneRadius = phoneW * 0.22
    let phonePath = CGPath(
        roundedRect: phoneRect,
        cornerWidth: phoneRadius,
        cornerHeight: phoneRadius,
        transform: nil
    )

    // Phone drop shadow onto the box interior.
    ctx.saveGState()
    ctx.setShadow(
        offset: CGSize(width: 0, height: -size * 0.010),
        blur: size * 0.025,
        color: CGColor(srgbRed: 0, green: 0, blue: 0, alpha: 0.55)
    )
    ctx.addPath(phonePath)
    ctx.setFillColor(CGColor(srgbRed: 0.10, green: 0.12, blue: 0.22, alpha: 1))
    ctx.fillPath()
    ctx.restoreGState()

    // Phone screen inset.
    let screenInset = phoneW * 0.075
    let screenRect = phoneRect.insetBy(dx: screenInset, dy: screenInset * 1.4)
    let screenPath = CGPath(
        roundedRect: screenRect,
        cornerWidth: phoneRadius * 0.62,
        cornerHeight: phoneRadius * 0.62,
        transform: nil
    )
    ctx.addPath(screenPath)
    ctx.setFillColor(CGColor(srgbRed: 0.09, green: 0.12, blue: 0.22, alpha: 1))
    ctx.fillPath()

    // Screen gradient wallpaper.
    ctx.saveGState()
    ctx.addPath(screenPath); ctx.clip()
    let screenGrad = CGGradient(
        colorsSpace: CGColorSpace(name: CGColorSpace.sRGB),
        colors: [
            CGColor(srgbRed: 0.32, green: 0.58, blue: 0.99, alpha: 0.95),
            CGColor(srgbRed: 0.72, green: 0.36, blue: 0.98, alpha: 0.70)
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

    // A small row of app dots on the screen (visual anchor without noise).
    let dotCount = 3
    let dotSize = phoneW * 0.16
    let dotGap = phoneW * 0.09
    let dotRowWidth = CGFloat(dotCount) * dotSize + CGFloat(dotCount - 1) * dotGap
    let dotStartX = screenRect.midX - dotRowWidth / 2
    let dotY = screenRect.minY + phoneH * 0.10
    let dotColors: [CGColor] = [
        CGColor(srgbRed: 1.00, green: 0.78, blue: 0.32, alpha: 1),
        CGColor(srgbRed: 0.99, green: 0.42, blue: 0.55, alpha: 1),
        CGColor(srgbRed: 0.34, green: 0.86, blue: 0.66, alpha: 1)
    ]
    for i in 0..<dotCount {
        let r = CGRect(
            x: dotStartX + CGFloat(i) * (dotSize + dotGap),
            y: dotY,
            width: dotSize,
            height: dotSize
        )
        ctx.addPath(CGPath(
            roundedRect: r,
            cornerWidth: dotSize * 0.28,
            cornerHeight: dotSize * 0.28,
            transform: nil
        ))
        ctx.setFillColor(dotColors[i])
        ctx.fillPath()
    }

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

    // A shipping-box glyph, front view. Two open flaps kicked outward on top
    // read as "open box" even at 18pt.
    let boxW = size * 0.72
    let boxH = size * 0.52
    let boxX = (size - boxW) / 2
    let boxY = size * 0.10
    let corner = size * 0.09
    let strokeW: CGFloat = max(size * 0.11, 2)

    // Box body — outlined rounded rect.
    let body = CGPath(
        roundedRect: CGRect(x: boxX, y: boxY, width: boxW, height: boxH),
        cornerWidth: corner,
        cornerHeight: corner,
        transform: nil
    )
    ctx.addPath(body)
    ctx.setStrokeColor(CGColor(gray: 0, alpha: 1))
    ctx.setLineWidth(strokeW)
    ctx.setLineJoin(.round)
    ctx.strokePath()

    // Center seam on the box front (short vertical tick).
    let seamW: CGFloat = max(strokeW * 0.6, 1.5)
    let seamH = boxH * 0.32
    ctx.setFillColor(CGColor(gray: 0, alpha: 1))
    ctx.fill(CGRect(
        x: size / 2 - seamW / 2,
        y: boxY + boxH - seamH,
        width: seamW,
        height: seamH
    ))

    // Two lid flaps kicked outward from the top corners of the box.
    let flapLen = boxW * 0.40
    let flapAngle: CGFloat = .pi / 3.6 // ~50° from vertical
    let leftAnchor = CGPoint(x: boxX + corner * 0.5, y: boxY + boxH - strokeW * 0.4)
    let rightAnchor = CGPoint(x: boxX + boxW - corner * 0.5, y: boxY + boxH - strokeW * 0.4)

    ctx.beginPath()
    ctx.move(to: leftAnchor)
    ctx.addLine(to: CGPoint(
        x: leftAnchor.x - sin(flapAngle) * flapLen,
        y: leftAnchor.y + cos(flapAngle) * flapLen
    ))
    ctx.setLineCap(.round)
    ctx.strokePath()

    ctx.beginPath()
    ctx.move(to: rightAnchor)
    ctx.addLine(to: CGPoint(
        x: rightAnchor.x + sin(flapAngle) * flapLen,
        y: rightAnchor.y + cos(flapAngle) * flapLen
    ))
    ctx.strokePath()

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
