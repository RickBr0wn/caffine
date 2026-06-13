import Foundation

enum Duration: String, CaseIterable, Hashable {
    case fifteenMinutes, thirtyMinutes, oneHour, twoHours, fiveHours, indefinite

    var seconds: TimeInterval? {
        switch self {
        case .fifteenMinutes: return 15 * 60
        case .thirtyMinutes: return 30 * 60
        case .oneHour: return 60 * 60
        case .twoHours: return 2 * 60 * 60
        case .fiveHours: return 5 * 60 * 60
        case .indefinite: return nil
        }
    }

    var label: String {
        switch self {
        case .fifteenMinutes: return "15 minutes"
        case .thirtyMinutes: return "30 minutes"
        case .oneHour: return "1 hour"
        case .twoHours: return "2 hours"
        case .fiveHours: return "5 hours"
        case .indefinite: return "Indefinitely"
        }
    }
}

class TimerManager: ObservableObject {
    static let shared = TimerManager()
    @Published var selectedDuration: Duration
    @Published var remainingSeconds: Int? = nil
    var onExpiry: (() -> Void)?

    private var timer: Timer?
    private static let durationKey = "lastUsedDuration"

    init() {
        if let raw = UserDefaults.standard.string(forKey: Self.durationKey),
           let saved = Duration(rawValue: raw) {
            selectedDuration = saved
        } else {
            selectedDuration = .indefinite
        }
    }

    func start(duration: Duration) {
        UserDefaults.standard.set(duration.rawValue, forKey: Self.durationKey)
        selectedDuration = duration
        timer?.invalidate()
        timer = nil

        if let seconds = duration.seconds {
            remainingSeconds = Int(seconds)
            timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
                self?.tick()
            }
        } else {
            remainingSeconds = nil
        }
    }

    func stop() {
        timer?.invalidate()
        timer = nil
        remainingSeconds = nil
    }

    private func tick() {
        guard let remaining = remainingSeconds else { return }
        let next = remaining - 1
        if next <= 0 {
            timer?.invalidate()
            timer = nil
            remainingSeconds = nil
            selectedDuration = .indefinite
            onExpiry?()
        } else {
            remainingSeconds = next
        }
    }

    var formattedRemaining: String? {
        guard let secs = remainingSeconds else { return nil }
        let h = secs / 3600
        let m = (secs % 3600) / 60
        let s = secs % 60
        if h > 0 {
            return String(format: "%d:%02d:%02d", h, m, s)
        } else {
            return String(format: "%d:%02d", m, s)
        }
    }
}
