import AppKit

enum NoteRenderer {
    static func draw(note: Note, rect: CGRect, in laneWidth: CGFloat, yPosition: CGFloat, noteHeight: CGFloat) {
        let x = CGFloat(note.lane) * laneWidth + 8
        let width = laneWidth - 16
        let noteRect = CGRect(x: rect.minX + x, y: yPosition, width: width, height: note.type == .long ? max(36, noteHeight) : 18)
        let color: NSColor
        switch note.type {
        case .normal: color = RRColor.noteNormal
        case .long: color = RRColor.noteLong
        case .specialLeft, .specialRight: color = RRColor.noteSpecial
        }
        color.setFill()
        NSBezierPath(roundedRect: noteRect, xRadius: RRMetrics.cornerRadius, yRadius: RRMetrics.cornerRadius).fill()
    }
}
