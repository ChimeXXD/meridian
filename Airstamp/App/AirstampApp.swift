import SwiftUI

@main
struct AirstampApp: App {
    var body: some Scene {
        WindowGroup {
            #if DEBUG
            if ProcessInfo.processInfo.arguments.contains("-designPreview") {
                DesignPreview()
            } else {
                PlaceholderView()
            }
            #else
            PlaceholderView()
            #endif
        }
    }
}
