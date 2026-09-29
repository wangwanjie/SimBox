import AppKit

extension NSImage {
    func scaled(to size: NSSize) -> NSImage {
        guard isValid else { return self }
        let result = NSImage(size: size)
        result.lockFocus()
        NSGraphicsContext.current?.imageInterpolation = .high
        draw(
            in: NSRect(origin: .zero, size: size),
            from: .zero,
            operation: .copy,
            fraction: 1
        )
        result.unlockFocus()
        return result
    }

    func withRoundedCorners(radius: CGFloat) -> NSImage {
        let result = NSImage(size: size)
        result.lockFocus()
        NSGraphicsContext.current?.imageInterpolation = .high
        let rect = NSRect(origin: .zero, size: size)
        let clip = NSBezierPath(roundedRect: rect, xRadius: radius, yRadius: radius)
        clip.addClip()
        draw(in: rect, from: .zero, operation: .sourceOver, fraction: 1)
        result.unlockFocus()
        return result
    }
}
