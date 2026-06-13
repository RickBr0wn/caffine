import AppKit

class IconAnimator {
    private var animationTimer: Timer?

    func animate(toActive: Bool, button: NSStatusBarButton) {
        animationTimer?.invalidate()
        let frames = (0...3).map { makeFrame(wispCount: $0) }
        let sequence = toActive ? Array(frames) : Array(frames.reversed())
        play(sequence, index: 0, button: button)
    }

    private func play(_ frames: [NSImage], index: Int, button: NSStatusBarButton) {
        guard index < frames.count else { return }
        button.image = frames[index]
        animationTimer = Timer.scheduledTimer(withTimeInterval: 0.07, repeats: false) { [weak self] _ in
            self?.play(frames, index: index + 1, button: button)
        }
    }

    private func makeFrame(wispCount: Int) -> NSImage {
        let image = NSImage(size: NSSize(width: 64, height: 64), flipped: false) { _ in
            let path = NSBezierPath()
            path.lineCapStyle = .round
            path.lineJoinStyle = .round
            path.lineWidth = 4

            // Cup body — SVG M8 26h46l-5 32H13z, converted to NS coords (y = 64 - svg_y)
            path.move(to: NSPoint(x: 8,  y: 38))
            path.line(to: NSPoint(x: 54, y: 38))
            path.line(to: NSPoint(x: 49, y: 6))
            path.line(to: NSPoint(x: 13, y: 6))
            path.close()

            // Handle — SVG M54 30 c7 0 8 6 8 11 s-1 11 -8 11
            path.move(to: NSPoint(x: 54, y: 34))
            path.curve(to: NSPoint(x: 62, y: 23),
                       controlPoint1: NSPoint(x: 61, y: 34),
                       controlPoint2: NSPoint(x: 62, y: 28))
            path.curve(to: NSPoint(x: 54, y: 12),
                       controlPoint1: NSPoint(x: 62, y: 18),
                       controlPoint2: NSPoint(x: 61, y: 12))

            NSColor.black.setStroke()
            path.stroke()

            // Steam wisps — SVG positions converted to NS coords
            // Left: M20 22 c-2-4 2-8 0-14  →  NS (20,42) to (20,56)
            // Center: M32 20 c-2-4 2-8 0-14  →  NS (32,44) to (32,58)
            // Right: M44 22 c-2-4 2-8 0-14  →  NS (44,42) to (44,56)
            let wisps: [(x: CGFloat, y: CGFloat)] = [(20, 42), (32, 44), (44, 42)]
            for i in 0..<wispCount {
                let (wx, wy) = (wisps[i].x, wisps[i].y)
                let wisp = NSBezierPath()
                wisp.lineCapStyle = .round
                wisp.lineWidth = 4
                wisp.move(to: NSPoint(x: wx, y: wy))
                wisp.curve(to: NSPoint(x: wx, y: wy + 14),
                           controlPoint1: NSPoint(x: wx - 2, y: wy + 4),
                           controlPoint2: NSPoint(x: wx + 2, y: wy + 8))
                NSColor.black.setStroke()
                wisp.stroke()
            }
            return true
        }
        image.size = NSSize(width: 16, height: 16)
        image.isTemplate = true
        return image
    }
}
