import SwiftUI

/// One line that may end with a provider's country ("HBO · US", "S12E104 · Paramount+ with Showtime · US"). When
/// it's too long, the words before the country shorten and " · US" stays (D-20, CLAUDE.md rule 11): break-ui found
/// "Paramount+ with Show…" on the widgets and the Lock Screen. The caller sets the font and colour; a line without a
/// country is one plain text, which keeps the caller's `minimumScaleFactor`.
struct CountryKeepingText: View {
    let line: String

    var body: some View {
        let split = ProviderLabel.splitCountry(line)
        if let country = split.country {
            HStack(alignment: .firstTextBaseline, spacing: 0) {
                // Neither part shrinks, so the two never differ in size: the words truncate instead.
                Text(verbatim: split.lead)
                    .lineLimit(1)
                    .truncationMode(.tail)
                    .minimumScaleFactor(1)
                Text(verbatim: country)
                    .lineLimit(1)
                    .fixedSize()
            }
        } else {
            Text(verbatim: line).lineLimit(1)
        }
    }
}

#Preview("A long provider") {
    VStack(alignment: .leading, spacing: Tokens.Space.s) {
        CountryKeepingText(line: "Paramount+ with Showtime · US").frame(width: 120, alignment: .leading)
        CountryKeepingText(line: "S12E104 · Paramount+ with Showtime · US").frame(width: 200, alignment: .leading)
        CountryKeepingText(line: "HBO · US")
        CountryKeepingText(line: "Apple TV")
    }
    .font(.system(size: 13, weight: .medium))
    .padding()
}
