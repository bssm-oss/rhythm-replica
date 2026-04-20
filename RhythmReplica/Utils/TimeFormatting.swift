import Foundation

enum TimeFormatting {
    static func clock(_ seconds: Double) -> String {
        let clamped = max(0, Int(seconds.rounded()))
        let minutes = clamped / 60
        let remainder = clamped % 60
        return String(format: "%02d:%02d", minutes, remainder)
    }
}
