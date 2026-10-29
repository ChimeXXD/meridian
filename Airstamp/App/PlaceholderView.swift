import SwiftUI
import WidgetKit

/// Day 0 placeholder. On appear it writes the setup check to the App Group
/// and reloads widgets, so the widget can prove it reads shared storage.
struct PlaceholderView: View {
    @State private var writtenAt: Date?
    @State private var groupAvailable = true

    var body: some View {
        VStack(spacing: 12) {
            Text("Airstamp")
                .font(.system(.largeTitle, design: .rounded, weight: .bold))
            if let writtenAt {
                Text("App Group OK · wrote \(writtenAt.formatted(date: .omitted, time: .shortened))")
                    .accessibilityIdentifier("setupCheck.ok")
            } else if !groupAvailable {
                Text("App Group unavailable. Check signing.")
                    .foregroundStyle(.red)
                    .accessibilityIdentifier("setupCheck.failed")
            }
        }
        .padding()
        .onAppear(perform: writeSetupCheck)
    }

    private func writeSetupCheck() {
        guard let defaults = AppGroup.defaults else {
            groupAvailable = false
            return
        }
        let now = Date.now
        SetupCheck.write(now, to: defaults)
        writtenAt = now
        WidgetCenter.shared.reloadAllTimelines()
    }
}

#Preview {
    PlaceholderView()
}
