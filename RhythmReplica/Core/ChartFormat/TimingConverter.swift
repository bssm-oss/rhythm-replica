import Foundation

public enum TimingConverter {
    public static func secondsPerBeat(bpm: Double) -> Double {
        60.0 / bpm
    }

    public static func time(forBeat beat: Double, bpm: Double, offset: Double) -> Double {
        offset + (beat * secondsPerBeat(bpm: bpm))
    }

    public static func beat(forTime time: Double, bpm: Double, offset: Double) -> Double {
        max(0, (time - offset) / secondsPerBeat(bpm: bpm))
    }
}
