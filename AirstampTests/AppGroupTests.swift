import Foundation
import Testing
@testable import Airstamp

@Suite("App Group")
struct AppGroupTests {
    @Test("identifier comes from the build settings")
    func identifierFromInfoPlist() {
        #expect(AppGroup.identifier.hasPrefix("group."))
        #expect(AppGroup.identifier.hasSuffix(".airstamp"))
    }

    @Test("the shared container is reachable")
    func sharedDefaultsExist() {
        #expect(AppGroup.defaults != nil)
    }

    @Test("a value written by the app reads back through the shared container")
    func setupCheckRoundTrip() throws {
        let defaults = try #require(AppGroup.defaults)
        let written = Date(timeIntervalSince1970: 1_793_000_000)
        SetupCheck.write(written, to: defaults)
        #expect(SetupCheck.read(from: defaults) == written)
    }
}
