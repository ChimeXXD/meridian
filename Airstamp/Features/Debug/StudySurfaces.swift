import SwiftUI

// Mock-ups of the surfaces outside the app at their real point sizes, used only by `NumeralStudyBoard`.
// Lock Screen and Dynamic Island are always dark; Home Screen widgets follow the colour scheme.

private let wallpaper = LinearGradient(colors: [Color(white: 0.22), Color(white: 0.08)], startPoint: .top, endPoint: .bottom)

private func providerName(_ drop: Drop) -> String { drop.provider?.display ?? "" }

/// Inline + circular + rectangular widgets and the Lock Screen Live Activity.
struct StudyLockScreen: View {
    let next: Drop
    let later: Drop
    let now: Date
    let formatter: DropFormatter

    @Environment(\.numeralStudy) private var study

    var body: some View {
        VStack(spacing: Tokens.Space.m) {
            // accessoryInline: the system draws it in its own font, so it looks the same in every study.
            Text("\(next.showName) · \(CountdownFormatter.text(CountdownFormatter.parts(from: now, to: next.date, maxUnits: 2)))")
                .font(.system(size: 17, weight: .semibold))
            Text(formatter.localTime(now))
                .font(.system(size: 92, weight: .semibold, design: .rounded))
                .padding(.top, -Tokens.Space.s)
            HStack(spacing: Tokens.Space.s) {
                circular(next)
                circular(later)
                rectangular(next)
            }
            liveActivity(next)
                .padding(.top, Tokens.Space.l)
        }
        .foregroundStyle(.white)
        .padding(.vertical, Tokens.Space.l)
        .padding(.horizontal, Tokens.Space.s)
        .frame(maxWidth: .infinity)
        .background(wallpaper, in: RoundedRectangle(cornerRadius: Tokens.Radius.sheet))
        .environment(\.colorScheme, .dark)
    }

    /// accessoryCircular, 76 × 76: big number, small unit, a ring over the last 7 days.
    private func circular(_ drop: Drop) -> some View {
        let part = CountdownFormatter.parts(from: now, to: drop.date, maxUnits: 1).first
        let progress = 1 - min(1, drop.date.timeIntervalSince(now) / (7 * 86_400))
        return ZStack {
            Circle().stroke(.white.opacity(0.25), lineWidth: 5)
            Circle().trim(from: 0, to: progress).stroke(.white, style: StrokeStyle(lineWidth: 5, lineCap: .round))
                .rotationEffect(.degrees(-90))
            if let part {
                Text("\(Text(verbatim: "\(part.value)").font(study.font(size: 26)))\(Text(verbatim: part.unit.rawValue).font(study.font(size: 13)).foregroundStyle(.white.opacity(0.6)))")
            }
        }
        .padding(4)
        .frame(width: 76, height: 76)
    }

    /// accessoryRectangular, 172 × 76: name, countdown, "Wed 02:00 · Apple TV".
    private func rectangular(_ drop: Drop) -> some View {
        VStack(alignment: .leading, spacing: 1) {
            Text(drop.showName).font(.system(size: 15, weight: .semibold)).lineLimit(1)
            CountdownText(drop: drop.date, confidence: drop.confidence, now: now, size: 24, tint: .white)
            Text("\(formatter.weekdayTime(drop.date)) · \(providerName(drop))")
                .font(.system(size: 12)).foregroundStyle(.white.opacity(0.7)).lineLimit(1)
        }
        .frame(width: 172, height: 76, alignment: .leading)
    }

    /// Lock Screen Live Activity, at most 160 pt tall: breadcrumb, relative countdown big, absolute time below.
    private func liveActivity(_ drop: Drop) -> some View {
        VStack(alignment: .leading, spacing: Tokens.Space.xs) {
            Text([drop.showName, drop.episodeLabel, drop.provider?.display].compactMap(\.self).joined(separator: " · "))
                .font(.footnote.weight(.semibold)).foregroundStyle(.white.opacity(0.6))
            HStack(alignment: .lastTextBaseline) {
                VStack(alignment: .leading, spacing: 0) {
                    Text("Out in").font(.caption).foregroundStyle(.white.opacity(0.6))
                    CountdownText(drop: drop.date, confidence: drop.confidence, now: now, size: 46, tint: study.accent)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 0) {
                    Text(formatter.relativeDay(drop.date, now: now)).font(.caption).foregroundStyle(.white.opacity(0.6))
                    Text(formatter.localTime(drop.date)).font(study.font(size: 22))
                }
            }
        }
        .padding(Tokens.Space.m)
        .frame(width: 370, alignment: .leading)
        .frame(maxHeight: 160)
        .background(.black.opacity(0.55), in: RoundedRectangle(cornerRadius: 24))
    }
}

/// Compact, minimal and expanded Dynamic Island presentations.
struct StudyDynamicIsland: View {
    let drop: Drop
    let now: Date
    let formatter: DropFormatter

    @Environment(\.numeralStudy) private var study

    var body: some View {
        VStack(spacing: Tokens.Space.m) {
            HStack(spacing: Tokens.Space.l) {
                compact
                minimal
            }
            expanded
        }
        .foregroundStyle(.white)
        .padding(Tokens.Space.m)
        .frame(maxWidth: .infinity)
        .background(wallpaper, in: RoundedRectangle(cornerRadius: Tokens.Radius.sheet))
        .environment(\.colorScheme, .dark)
    }

    private var monogram: some View {
        Text(String(drop.showName.prefix(1)))
            .font(.system(size: 13, weight: .bold))
            .foregroundStyle(.black)
            .frame(width: 22, height: 22)
            .background(study.accent, in: Circle())
    }

    private var compact: some View {
        HStack {
            monogram
            Spacer()
            CountdownText(drop: drop.date, confidence: drop.confidence, now: now, size: 16, tint: study.accent)
        }
        .padding(.horizontal, 8)
        .frame(width: 236, height: 37)
        .background(.black, in: Capsule())
    }

    /// Minimal: must fit 28 pt when the island is limited in width (SPEC).
    private var minimal: some View {
        let part = CountdownFormatter.parts(from: now, to: drop.date, maxUnits: 1).first
        // Past the drop there are no parts; show "Out" rather than a misleading "0".
        let value = part.map { "\($0.value)" } ?? "Out"
        return Text("\(Text(verbatim: value).font(study.font(size: 14)))\(Text(verbatim: part?.unit.rawValue ?? "").font(study.font(size: 9)))")
            .foregroundStyle(study.accent)
            .frame(width: 28, height: 28)
            .padding(4)
            .background(.black, in: Circle())
    }

    private var expanded: some View {
        VStack(alignment: .leading, spacing: Tokens.Space.s) {
            HStack(alignment: .top) {
                monogram
                VStack(alignment: .leading, spacing: 0) {
                    Text(drop.showName).font(.headline)
                    Text(drop.episodeLabel ?? "").font(.caption).foregroundStyle(.white.opacity(0.6))
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 0) {
                    Text("Out in").font(.caption2).foregroundStyle(.white.opacity(0.6))
                    CountdownText(drop: drop.date, confidence: drop.confidence, now: now, size: 30, tint: study.accent)
                }
            }
            Text("\(providerName(drop)) · \(formatter.localTime(drop.date))")
                .font(.footnote).foregroundStyle(.white.opacity(0.7))
        }
        .padding(Tokens.Space.l)
        .frame(width: 370)
        .background(.black, in: RoundedRectangle(cornerRadius: 44))
    }
}

/// systemSmall, 170 × 170: huge countdown, the show name small, the source chip.
struct StudySmallWidget: View {
    let drop: Drop
    let now: Date

    var body: some View {
        VStack(alignment: .leading, spacing: Tokens.Space.xxs) {
            Text("UP NEXT").font(.caption2.weight(.semibold)).foregroundStyle(.secondary)
            Spacer(minLength: 0)
            CountdownText(drop: drop.date, confidence: drop.confidence, now: now, size: 40)
            Text(drop.showName).font(.footnote.weight(.semibold)).lineLimit(1)
            SourceChip(source: drop.source, confidence: drop.confidence)
        }
        .padding(Tokens.Space.m)
        .frame(width: 170, height: 170, alignment: .leading)
        .background(Tokens.card, in: RoundedRectangle(cornerRadius: Tokens.Radius.widget))
    }
}

/// systemMedium, 364 × 170: the next 3 drops as rows.
struct StudyMediumWidget: View {
    let drops: [Drop]
    let now: Date
    let formatter: DropFormatter

    var body: some View {
        VStack(alignment: .leading, spacing: Tokens.Space.xs) {
            Text("UP NEXT").font(.caption2.weight(.semibold)).foregroundStyle(.secondary)
            ForEach(drops) { drop in
                HStack {
                    VStack(alignment: .leading, spacing: 0) {
                        Text(drop.showName).font(.subheadline.weight(.semibold)).lineLimit(1)
                        Text("\(formatter.weekdayTime(drop.date)) · \(providerName(drop))")
                            .font(.caption).foregroundStyle(.secondary).lineLimit(1)
                    }
                    Spacer()
                    CountdownText(drop: drop.date, confidence: drop.confidence, now: now, size: 22)
                        .fixedSize()
                }
            }
        }
        .padding(Tokens.Space.m)
        .frame(width: 364, height: 170, alignment: .topLeading)
        .background(Tokens.card, in: RoundedRectangle(cornerRadius: Tokens.Radius.widget))
    }
}
