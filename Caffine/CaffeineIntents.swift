import AppIntents

struct DeactivateCaffeineIntent: AppIntent {
    static var title: LocalizedStringResource = "Turn Off Caffine"
    static var description = IntentDescription("Allows your Mac display to sleep normally.")
    static var openAppWhenRun: Bool = false

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        CaffeineManager.shared.deactivate()
        TimerManager.shared.stop()
        return .result(dialog: "Caffine is off.")
    }
}

struct CaffeineShortcutsProvider: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: DeactivateCaffeineIntent(),
            phrases: ["Turn off \(.applicationName)", "Deactivate \(.applicationName)"],
            shortTitle: "Turn Off Caffine",
            systemImageName: "cup.and.saucer"
        )
    }
}
