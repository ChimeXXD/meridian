import Foundation

/// What Show detail's Live Activity switch says will really happen (UX audit #11): it said "Starts 2 hours before"
/// even when nothing would be booked. Checked in order: switched off in iOS Settings, off for this show, no time yet,
/// more than a week away (`ActivityPlanner.horizon`), 3 sooner ones already booked, then booked as usual.
enum LiveActivityStatus {
    enum Line: Equatable, Sendable {
        case starts, off, systemOff, noTime, notThisWeek, waiting
    }

    static func line(isOn: Bool, systemEnabled: Bool, drop: Drop, waiting: Bool, now: Date) -> Line {
        if !systemEnabled { return .systemOff }
        if !isOn { return .off }
        if drop.confidence == .dateOnly { return .noTime }
        if drop.date.timeIntervalSince(now) > ActivityPlanner.horizon { return .notThisWeek }
        if waiting { return .waiting }
        return .starts
    }

    static func text(_ line: Line, leadMinutes: Int) -> String {
        switch line {
        case .starts: "Starts \(LeadTime.phrase(minutes: leadMinutes)) before, on your Lock Screen"
        case .off: "Off for this show"
        case .systemOff: "Live Activities are off in Settings"
        case .noTime: "Starts once a time is announced"
        case .notThisWeek: "Booked once it's within a week"
        case .waiting: "Waiting: \(ActivityPlanner.maxPending) sooner ones are booked"
        }
    }
}
