import Foundation

/// Launch arguments that make the app easy to drive from scripts and QA.
/// Example: `xcrun simctl launch <udid> com.tinkercademy.dabao -dabaoSkipSplash -dabaoNoDelay -dabaoFixture history-laksa`
nonisolated enum LaunchOptions {

    /// Delete saved state before loading.
    static var reset: Bool { has("-dabaoReset") }

    /// Go straight to the tab bar.
    static var skipSplash: Bool { has("-dabaoSkipSplash") }

    /// Skip the simulated network delay.
    static var noDelay: Bool { has("-dabaoNoDelay") }

    /// Make 1 delivery minute last 1 second, for demos and QA.
    static var fastDelivery: Bool { has("-dabaoFastDelivery") }

    /// The name of a fixture from `Fixtures` to load over the saved state.
    static var fixture: String? {
        let arguments = ProcessInfo.processInfo.arguments
        guard let index = arguments.firstIndex(of: "-dabaoFixture"),
              arguments.indices.contains(index + 1) else { return nil }
        return arguments[index + 1]
    }

    private static func has(_ flag: String) -> Bool {
        ProcessInfo.processInfo.arguments.contains(flag)
    }
}
