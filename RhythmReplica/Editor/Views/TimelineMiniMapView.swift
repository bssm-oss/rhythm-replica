import AppKit

final class TimelineMiniMapView: NSView {
    var chart: Chart = .empty { didSet { needsDisplay = true } }
    var playbackBeat: Double = 0 { didSet { needsDisplay = true } }

    override func draw(_ dirtyRect: NSRect) {
        RRColor.elevatedBackground.setFill()
        dirtyRect.fill()
        RRColor.border.setStroke()
        NSBezierPath(rect: dirtyRect).stroke()

        let laneWidth = dirtyRect.width / 4
        for note in chart.notes {
            let x = CGFloat(note.lane) * laneWidth + 4
            let y = dirtyRect.height - CGFloat(note.beat / max(chart.totalBeats, 1)) * dirtyRect.height
            let rect = CGRect(x: x, y: max(0, y - 3), width: laneWidth - 8, height: 4)
            RRColor.secondaryText.setFill()
            NSBezierPath(roundedRect: rect, xRadius: 2, yRadius: 2).fill()
        }

        RRColor.accentBlue.setStroke()
        let headY = dirtyRect.height - CGFloat(playbackBeat / max(chart.totalBeats, 1)) * dirtyRect.height
        NSBezierPath.strokeLine(from: NSPoint(x: 0, y: headY), to: NSPoint(x: dirtyRect.width, y: headY))
    }
}
