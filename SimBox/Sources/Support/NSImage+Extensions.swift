import AppKit

extension NSImage {
    /// 使用 drawingHandler 生成新图，替代已废弃的 lockFocus，并在 Retina 屏上按需以高分辨率绘制。
    func scaled(to size: NSSize) -> NSImage {
        guard isValid else {
            return self
        }
        return NSImage(size: size, flipped: false) { rect in
            NSGraphicsContext.current?.imageInterpolation = .high
            self.draw(in: rect, from: .zero, operation: .copy, fraction: 1)
            return true
        }
    }

    func withRoundedCorners(radius: CGFloat) -> NSImage {
        NSImage(size: size, flipped: false) { rect in
            NSGraphicsContext.current?.imageInterpolation = .high
            NSBezierPath(roundedRect: rect, xRadius: radius, yRadius: radius).addClip()
            self.draw(in: rect, from: .zero, operation: .sourceOver, fraction: 1)
            return true
        }
    }
}
