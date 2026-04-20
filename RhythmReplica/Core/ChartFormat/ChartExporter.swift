import Foundation

public final class ChartExporter {
    private let encoder: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return encoder
    }()

    public init() {}

    public func exportInternal(_ chart: Chart) throws -> Data {
        try encoder.encode(chart)
    }

    public func exportLumina(_ chart: Chart) throws -> Data {
        let lumina = chart.notes.map { note in
            LuminaExportNote(chart: chart, note: note)
        }
        return try encoder.encode(lumina)
    }
}

private struct LuminaExportNote: Encodable {
    let type: String
    let lane: Int?
    let time: Double
    let endTime: Double?
    let dir: String?

    init(chart: Chart, note: Note) {
        switch note.type {
        case .normal:
            type = "normal"
            lane = note.lane
            dir = nil
            endTime = nil
        case .long:
            type = "long"
            lane = note.lane
            dir = nil
            endTime = TimingConverter.time(forBeat: note.endBeat, bpm: chart.bpm, offset: chart.offset)
        case .specialLeft:
            type = "special"
            lane = nil
            dir = "left"
            endTime = nil
        case .specialRight:
            type = "special"
            lane = nil
            dir = "right"
            endTime = nil
        }

        time = TimingConverter.time(forBeat: note.beat, bpm: chart.bpm, offset: chart.offset)
    }
}
