import AppKit

final class WaveformView: NSView {
    var samples: [Float] = [] {
        didSet { needsDisplay = true }
    }

    override func draw(_ dirtyRect: NSRect) {
        RRColor.elevatedBackground.setFill()
        dirtyRect.fill()
        RRColor.border.setStroke()
        NSBezierPath(rect: dirtyRect).stroke()

        guard !samples.isEmpty else { return }
        let centerY = dirtyRect.midY
        let path = NSBezierPath()
        path.lineWidth = 1
        RRColor.accentBlue.setStroke()
        for (index, sample) in samples.enumerated() {
            let x = dirtyRect.minX + (CGFloat(index) / CGFloat(max(samples.count - 1, 1))) * dirtyRect.width
            let amplitude = CGFloat(sample) * dirtyRect.height * 0.45
            path.move(to: NSPoint(x: x, y: centerY - amplitude))
            path.line(to: NSPoint(x: x, y: centerY + amplitude))
        }
        path.stroke()
    }
}
