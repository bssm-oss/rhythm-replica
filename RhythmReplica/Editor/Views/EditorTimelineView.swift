import AppKit

final class EditorTimelineView: NSView {
    enum PlacementKind: String, CaseIterable {
        case normal = "Normal"
        case specialLeft = "Special Left"
        case specialRight = "Special Right"
    }

    private enum DragOperation {
        case move(ids: Set<UUID>, originalNotes: [UUID: Note], startBeat: Double, startLane: Int)
        case resizeLong(id: UUID, original: Note)
    }

    var chart: Chart = .empty { didSet { needsDisplay = true } }
    var snapDivisor: Double = 4
    var mode: EditorMode = .normal
    var placementKind: PlacementKind = .normal
    var playbackBeat: Double = 0 { didSet { needsDisplay = true } }
    var zoomScale: Double = 1.0 { didSet { needsDisplay = true } }
    var selectedNoteIDs: Set<UUID> = [] { didSet { needsDisplay = true } }
    var onChartWillChange: ((Chart) -> Void)?
    var onChartChanged: ((Chart) -> Void)?
    var onSeek: ((Double) -> Void)?
    private var selectionStartPoint: NSPoint?
    private var selectionRect: CGRect?
    private var dragOperation: DragOperation?

    private var visibleBeatRange: ClosedRange<Double> {
        0...max(4, chart.totalBeats / zoomScale)
    }

    private var visibleBeats: Double {
        visibleBeatRange.upperBound - visibleBeatRange.lowerBound
    }

    override func draw(_ dirtyRect: NSRect) {
        RRColor.elevatedBackground.setFill()
        dirtyRect.fill()

        let laneWidth = dirtyRect.width / 4
        for lane in 0...4 {
            let x = CGFloat(lane) * laneWidth
            RRColor.border.setStroke()
            NSBezierPath.strokeLine(from: NSPoint(x: x, y: 0), to: NSPoint(x: x, y: dirtyRect.height))
        }

        let pixelsPerBeat = dirtyRect.height / CGFloat(visibleBeats)
        let subdivisions = Int(visibleBeatRange.upperBound * snapDivisor)
        if subdivisions > 0 {
            for index in 0...subdivisions {
                let beat = Double(index) / snapDivisor
                let y = yPosition(forBeat: beat, in: dirtyRect.height)
                guard y >= 0, y <= dirtyRect.height else { continue }
                let color = index % Int(snapDivisor) == 0 ? RRColor.secondaryText : RRColor.border
                color.setStroke()
                NSBezierPath.strokeLine(from: NSPoint(x: 0, y: y), to: NSPoint(x: dirtyRect.width, y: y))
            }
        }

        for note in chart.notes {
            let rect = rect(for: note, laneWidth: laneWidth, pixelsPerBeat: pixelsPerBeat, in: dirtyRect)
            let color = selectedNoteIDs.contains(note.id) ? RRColor.warning : color(for: note.type)
            color.setFill()
            NSBezierPath(roundedRect: rect, xRadius: RRMetrics.cornerRadius, yRadius: RRMetrics.cornerRadius).fill()
        }

        if let selectionRect {
            RRColor.accentBlue.setStroke()
            let path = NSBezierPath(rect: selectionRect)
            path.lineWidth = 2
            path.stroke()
        }

        RRColor.accentBlue.setStroke()
        let headY = yPosition(forBeat: playbackBeat, in: dirtyRect.height)
        NSBezierPath.strokeLine(from: NSPoint(x: 0, y: headY), to: NSPoint(x: dirtyRect.width, y: headY))
    }

    override func mouseDown(with event: NSEvent) {
        let point = convert(event.locationInWindow, from: nil)
        let laneWidth = bounds.width / 4
        let lane = max(0, min(3, Int(point.x / laneWidth)))
        let beat = snappedBeat(for: point.y)

        if event.modifierFlags.contains(.shift) {
            onSeek?(beat)
            return
        }

        onChartWillChange?(chart)
        switch mode {
        case .normal:
            let note = Note(beat: beat, lane: lane, type: noteType(for: placementKind, lane: lane))
            chart.notes.append(note)
            selectedNoteIDs = [chart.notes.last!.id]
        case .long:
            chart.notes.append(Note(beat: beat, lane: lane, type: .long, durationBeats: 1))
            selectedNoteIDs = [chart.notes.last!.id]
        case .delete:
            chart.notes.removeAll { hitTest(note: $0, beat: beat, lane: lane) }
            selectedNoteIDs.removeAll()
        case .edit, .select:
            if mode == .select {
                selectionStartPoint = point
                selectionRect = CGRect(origin: point, size: .zero)
                if let id = chart.notes.first(where: { hitTest(note: $0, beat: beat, lane: lane) })?.id {
                    selectedNoteIDs = [id]
                }
            } else if let note = chart.notes.first(where: { hitTest(note: $0, beat: beat, lane: lane) }) {
                selectedNoteIDs = [note.id]
                let laneWidth = bounds.width / 4
                let pixelsPerBeat = bounds.height / CGFloat(visibleBeats)
                let noteRect = rect(for: note, laneWidth: laneWidth, pixelsPerBeat: pixelsPerBeat, in: bounds)
                let originals = Dictionary(uniqueKeysWithValues: chart.notes.filter { selectedNoteIDs.contains($0.id) }.map { ($0.id, $0) })
                if note.type == .long && abs(point.y - noteRect.minY) < 12 {
                    dragOperation = .resizeLong(id: note.id, original: note)
                } else {
                    dragOperation = .move(ids: selectedNoteIDs, originalNotes: originals, startBeat: beat, startLane: lane)
                }
            }
        }

        chart.notes.sort { $0.beat < $1.beat }
        onChartChanged?(chart)
        needsDisplay = true
    }

    override func mouseDragged(with event: NSEvent) {
        let point = convert(event.locationInWindow, from: nil)
        if mode == .select, let start = selectionStartPoint {
            selectionRect = CGRect(x: min(start.x, point.x), y: min(start.y, point.y), width: abs(point.x - start.x), height: abs(point.y - start.y))
            updateSelectionFromRect()
            return
        }

        guard mode == .edit, let dragOperation else { return }
        let laneWidth = bounds.width / 4
        let lane = max(0, min(3, Int(point.x / laneWidth)))
        let beat = snappedBeat(for: point.y)
        let step = 1 / snapDivisor

        switch dragOperation {
        case .move(let ids, let originalNotes, let startBeat, let startLane):
            let laneDelta = lane - startLane
            let beatDelta = beat - startBeat
            chart.notes = chart.notes.map { note in
                guard ids.contains(note.id), let original = originalNotes[note.id] else { return note }
                var edited = original
                edited.lane = min(max(0, original.lane + laneDelta), 3)
                edited.beat = min(max(0, original.beat + beatDelta), chart.totalBeats)
                return edited
            }
        case .resizeLong(let id, let original):
            chart.notes = chart.notes.map { note in
                guard note.id == id else { return note }
                var edited = original
                edited.durationBeats = max(step, min(chart.totalBeats - original.beat, beat - original.beat))
                return edited
            }
        }
        chart.notes.sort { $0.beat < $1.beat }
        onChartChanged?(chart)
        needsDisplay = true
    }

    override func mouseUp(with event: NSEvent) {
        if mode == .select {
            updateSelectionFromRect()
            selectionStartPoint = nil
            selectionRect = nil
            needsDisplay = true
        }
        dragOperation = nil
    }

    func selectAllNotes() {
        selectedNoteIDs = Set(chart.notes.map(\.id))
    }

    func clearSelection() {
        selectedNoteIDs.removeAll()
    }

    func deleteSelectedNotes() {
        guard !selectedNoteIDs.isEmpty else { return }
        onChartWillChange?(chart)
        chart.notes.removeAll { selectedNoteIDs.contains($0.id) }
        selectedNoteIDs.removeAll()
        onChartChanged?(chart)
        needsDisplay = true
    }

    func selectedNotes() -> [Note] {
        chart.notes.filter { selectedNoteIDs.contains($0.id) }
    }

    func paste(notes: [Note], at beatOffset: Double) {
        guard !notes.isEmpty else { return }
        onChartWillChange?(chart)
        let minimumBeat = notes.map(\.beat).min() ?? 0
        let translated = notes.map { note in
            Note(beat: note.beat - minimumBeat + beatOffset, lane: note.lane, type: note.type, durationBeats: note.durationBeats)
        }
        chart.notes.append(contentsOf: translated)
        selectedNoteIDs = Set(translated.map(\.id))
        chart.notes.sort { $0.beat < $1.beat }
        onChartChanged?(chart)
        needsDisplay = true
    }

    func stampNote(at beat: Double, lane: Int, mode: EditorMode) {
        onChartWillChange?(chart)
        switch mode {
        case .normal:
            let note = Note(beat: beat, lane: lane, type: noteType(for: placementKind, lane: lane))
            chart.notes.append(note)
            selectedNoteIDs = [note.id]
        case .long:
            let note = Note(beat: beat, lane: lane, type: .long, durationBeats: 1)
            chart.notes.append(note)
            selectedNoteIDs = [note.id]
        default:
            break
        }
        chart.notes.sort { $0.beat < $1.beat }
        onChartChanged?(chart)
        needsDisplay = true
    }

    private func snappedBeat(for y: CGFloat) -> Double {
        let ratio = max(0, min(1, 1 - (y / bounds.height)))
        let rawBeat = visibleBeatRange.lowerBound + ratio * visibleBeats
        let step = 1 / snapDivisor
        return (rawBeat / step).rounded() * step
    }

    private func hitTest(note: Note, beat: Double, lane: Int) -> Bool {
        note.lane == lane && abs(note.beat - beat) <= (1 / snapDivisor)
    }

    private func rect(for note: Note, laneWidth: CGFloat, pixelsPerBeat: CGFloat, in dirtyRect: CGRect) -> CGRect {
        let x = CGFloat(note.lane) * laneWidth + 8
        let y = yPosition(forBeat: note.beat, in: dirtyRect.height) - 16
        let height = max(18, CGFloat(note.durationBeats) * pixelsPerBeat)
        return CGRect(x: x, y: y - height, width: laneWidth - 16, height: height)
    }

    private func updateSelectionFromRect() {
        guard let selectionRect else { return }
        let laneWidth = bounds.width / 4
        let pixelsPerBeat = bounds.height / CGFloat(visibleBeats)
        let selected = chart.notes.filter { rect(for: $0, laneWidth: laneWidth, pixelsPerBeat: pixelsPerBeat, in: bounds).intersects(selectionRect) }
        selectedNoteIDs = Set(selected.map(\.id))
    }

    private func yPosition(forBeat beat: Double, in height: CGFloat) -> CGFloat {
        let relativeBeat = beat - visibleBeatRange.lowerBound
        return height - CGFloat(relativeBeat / visibleBeats) * height
    }

    private func color(for type: NoteType) -> NSColor {
        switch type {
        case .normal: return RRColor.noteNormal
        case .long: return RRColor.noteLong
        case .specialLeft, .specialRight: return RRColor.noteSpecial
        }
    }

    private func noteType(for placementKind: PlacementKind, lane: Int) -> NoteType {
        switch placementKind {
        case .normal:
            return .normal
        case .specialLeft:
            return .specialLeft
        case .specialRight:
            return .specialRight
        }
    }
}
