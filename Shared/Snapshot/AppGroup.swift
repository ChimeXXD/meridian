import Foundation

/// The App Group shared by the app and the widget extension.
/// Its ID comes from `APP_GROUP_ID` in Config/Base.xcconfig, via each target's Info.plist.
enum AppGroup {
    static let identifier: String = {
        guard let id = Bundle.main.object(forInfoDictionaryKey: "MeridianAppGroup") as? String, !id.isEmpty else {
            preconditionFailure("MeridianAppGroup is missing from Info.plist")
        }
        return id
    }()
}
