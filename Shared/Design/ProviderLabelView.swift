import SwiftUI
import WidgetKit

/// "HBO · US" (D-20). When the rules file marks the viewer's country, "No official stream in your country"
/// is added under it (#53 Grab); the network stays, because "where is it on" is the question we answer.
struct ProviderLabelView: View {
    let provider: ProviderLabel?

    @Environment(\.widgetRenderingMode) private var renderingMode

    var body: some View {
        if let provider {
            VStack(alignment: .leading, spacing: 2) {
                Text(provider.display).foregroundStyle(.secondary)
                if provider.noOfficialStream {
                    Label("No official stream in your country", systemImage: "exclamationmark.circle")
                        .foregroundStyle(noStreamInk)
                }
            }
            .font(.footnote)
            .accessibilityElement(children: .combine)
            .accessibilityIdentifier("provider-label")
        }
    }

    /// In tinted or accented widgets colour is replaced by the system tint, so the glyph and words carry it.
    private var noStreamInk: Color {
        renderingMode == .fullColor ? Color(uiColor: Tokens.Ink.noStream) : .primary
    }
}

#Preview("Provider labels") {
    VStack(alignment: .leading, spacing: Tokens.Space.s) {
        ProviderLabelView(provider: ProviderLabel(name: "Apple TV", countryCode: nil, noOfficialStream: false))
        ProviderLabelView(provider: ProviderLabel(name: "HBO", countryCode: "US", noOfficialStream: false))
        ProviderLabelView(provider: ProviderLabel(name: "HBO", countryCode: "US", noOfficialStream: true))
    }
    .padding()
}
