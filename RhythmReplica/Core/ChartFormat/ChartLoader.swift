import Foundation

enum ChartLoadingError: LocalizedError {
    case unsupportedFormat
    case invalidSpecialDirection

    var errorDescription: String? {
        switch self {
        case .unsupportedFormat:
            return "지원하지 않는 채보 형식입니다. 내부 표준 JSON 또는 LUMINA 스타일 JSON 배열을 사용해 주세요."
        case .invalidSpecialDirection:
            return "special 노트의 dir 값은 left 또는 right여야 합니다."
        }
    }
}

public final class ChartLoader {
    public init() {}

    public func load(from url: URL) throws -> Chart {
        try load(data: Data(contentsOf: url), suggestedAudioFileName: "")
    }

    public func load(data: Data, suggestedAudioFileName: String) throws -> Chart {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .useDefaultKeys

        if let chart = try? decoder.decode(Chart.self, from: data) {
            return chart
        }

        if let luminaNotes = try? decoder.decode([LuminaNote].self, from: data) {
            return try convertLuminaNotes(luminaNotes, suggestedAudioFileName: suggestedAudioFileName)
        }

        throw ChartLoadingError.unsupportedFormat
    }

    private func convertLuminaNotes(_ notes: [LuminaNote], suggestedAudioFileName: String) throws -> Chart {
        let bpm = 60.0
        let converted: [Note] = try notes.enumerated().map { _, lumina in
            switch lumina.type {
            case "normal":
                return Note(beat: lumina.time, lane: lumina.lane ?? 0, type: .normal)
            case "long":
                return Note(
                    beat: lumina.time,
                    lane: lumina.lane ?? 0,
                    type: .long,
                    durationBeats: max(0, (lumina.endTime ?? lumina.time) - lumina.time)
                )
            case "special":
                switch lumina.dir {
                case "left":
                    return Note(beat: lumina.time, lane: 0, type: .specialLeft)
                case "right":
                    return Note(beat: lumina.time, lane: 3, type: .specialRight)
                default:
                    throw ChartLoadingError.invalidSpecialDirection
                }
            default:
                throw ChartLoadingError.unsupportedFormat
            }
        }

        let totalBeats = max(converted.map(\.endBeat).max() ?? 0, 32)
        return Chart(
            schemaVersion: 1,
            title: "Imported LUMINA Chart",
            artist: "Unknown",
            audioFileName: suggestedAudioFileName,
            bpm: bpm,
            totalBeats: totalBeats,
            offset: 0,
            difficulty: "Imported",
            notes: converted.sorted { $0.beat < $1.beat }
        )
    }
}

private struct LuminaNote: Decodable {
    let type: String
    let lane: Int?
    let time: Double
    let endTime: Double?
    let dir: String?
}
