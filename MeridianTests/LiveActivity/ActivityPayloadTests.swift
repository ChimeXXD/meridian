import Foundation
import Testing
@testable import Meridian

/// SPEC acceptance: the Live Activity payload is under 4 KB (CLAUDE.md rule 7). The largest realistic attributes and
/// state, encoded with `JSONEncoder`, must stay under 2 KB, so there's plenty of room left.
@Suite("Live Activity payload")
struct ActivityPayloadTests {
    @Test("the largest realistic attributes and state encode to under 2 KB")
    func underTwoKilobytes() throws {
        let name = "The Lord of the Rings: The Rings of Power, Season Two Finale"
        #expect(name.count == 60)
        let attributes = DropActivityAttributes(
            dropIDs: ["tvmaze:38052:s3e1", "tvmaze:44778:s2e10", "anilist:154587:s2e12"],
            showName: name, episodeLabel: "S12E104", provider: "Paramount+ · US", verb: .airsInJapan,
            noOfficialStream: true, showID: "anilist:154587", windowStart: Date(iso: "2026-11-05T23:00:00Z"))
        let state = DropActivityAttributes.ContentState(phase: .upcoming, dropDate: Date(iso: "2026-11-06T01:00:00Z"),
                                                        delayedFrom: Date(iso: "2026-11-05T23:00:00Z"))

        let encoder = JSONEncoder()
        let attributeBytes = try encoder.encode(attributes).count
        let stateBytes = try encoder.encode(state).count
        #expect(attributeBytes + stateBytes < 2_048, "payload is \(attributeBytes + stateBytes) bytes")
        // The content state is what each update sends; it stays tiny.
        #expect(stateBytes < 256, "state is \(stateBytes) bytes")
    }

    @Test("attributes and state survive a round trip")
    func roundTrip() throws {
        let attributes = LiveActivitySamples.attributes(.merged)
        let state = LiveActivitySamples.state(.delayed, now: Date(iso: "2026-11-05T23:00:00Z"))
        let decodedAttributes = try JSONDecoder().decode(DropActivityAttributes.self,
                                                         from: JSONEncoder().encode(attributes))
        #expect(decodedAttributes.dropIDs == attributes.dropIDs)
        #expect(decodedAttributes.showName == attributes.showName)
        #expect(decodedAttributes.provider == attributes.provider)
        #expect(decodedAttributes.verb == attributes.verb)
        #expect(decodedAttributes.showID == attributes.showID)
        #expect(decodedAttributes.windowStart == attributes.windowStart)
        #expect(try JSONDecoder().decode(DropActivityAttributes.ContentState.self, from: JSONEncoder().encode(state))
            == state)
    }

    /// The JSON a pending activity was written with, byte for byte: a later build must write the same and read it back.
    @Test("attributes encode to the same JSON as before", arguments: ["Out", "Expected", "Airs in Japan"])
    func encodedJSON(verb: String) throws {
        let json = """
        {"dropIDs":["tvmaze:44778:s2e5"],"episodeLabel":"S2E5","noOfficialStream":false,"provider":"Apple TV",\
        "showID":"44778","showName":"Silo","verb":"\(verb)"}
        """
        let attributes = try JSONDecoder().decode(DropActivityAttributes.self, from: Data(json.utf8))
        let encoder = JSONEncoder()
        encoder.outputFormatting = .sortedKeys
        #expect(try String(decoding: encoder.encode(attributes), as: UTF8.self) == json)
    }

    /// An activity written before the verb had a type, with an empty, blank or missing verb, still reads as "Out", as
    /// the views read it then.
    @Test("an empty, blank or missing verb decodes as Out", arguments: [",\"verb\":\"\"", ",\"verb\":\" \"", ""])
    func emptyVerb(field: String) throws {
        let json = #"{"dropIDs":["tvmaze:44778:s2e5"],"showName":"Silo"\#(field)}"#
        #expect(try JSONDecoder().decode(DropActivityAttributes.self, from: Data(json.utf8)).verb == .out)
    }
}
