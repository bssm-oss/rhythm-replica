import Foundation

public struct ChartValidationIssue: Equatable {
    public let message: String

    public init(message: String) {
        self.message = message
    }
}

public final class ChartValidator {
    public init() {}

    public func validate(_ chart: Chart) -> [ChartValidationIssue] {
        var issues: [ChartValidationIssue] = []

        if chart.bpm <= 0 {
            issues.append(.init(message: "bpm은 0보다 커야 합니다."))
        }
        if chart.totalBeats <= 0 {
            issues.append(.init(message: "totalBeats는 0보다 커야 합니다."))
        }

        for note in chart.notes {
            if !(0...3).contains(note.lane) {
                issues.append(.init(message: "lane는 0부터 3 사이여야 합니다."))
            }
            if note.beat < 0 {
                issues.append(.init(message: "beat는 음수가 될 수 없습니다."))
            }
            if note.beat > chart.totalBeats {
                issues.append(.init(message: "note beat가 totalBeats를 초과했습니다."))
            }
            if note.type == .long && note.durationBeats <= 0 {
                issues.append(.init(message: "long note는 0보다 큰 durationBeats가 필요합니다."))
            }
            if note.endBeat > chart.totalBeats {
                issues.append(.init(message: "long note 끝 beat가 totalBeats를 초과했습니다."))
            }
        }

        let groupedLongs = chart.notes.filter { $0.type == .long }.sorted { $0.beat < $1.beat }.reduce(into: [Int: [Note]]()) { partial, note in
            partial[note.lane, default: []].append(note)
        }

        for notes in groupedLongs.values {
            for index in 1..<notes.count where notes[index - 1].endBeat > notes[index].beat {
                issues.append(.init(message: "같은 lane의 long note가 겹칩니다."))
            }
        }

        return issues
    }
}
