import AppKit

class AppDelegate: NSObject, NSApplicationDelegate {
    private var menuBarManager: MenuBarManager!
    private let caffeineManager = CaffeineManager()
    private let timerManager = TimerManager()

    func applicationDidFinishLaunching(_ notification: Notification) {
        menuBarManager = MenuBarManager(caffeineManager: caffeineManager, timerManager: timerManager)
        timerManager.onExpiry = { [weak self] in
            self?.caffeineManager.deactivate()
        }
        if UserDefaults.standard.bool(forKey: "activateAtLaunch") {
            caffeineManager.activate()
            timerManager.start(duration: timerManager.selectedDuration)
        }
    }

    func applicationShouldTerminate(_ sender: NSApplication) -> NSApplication.TerminateReply {
        caffeineManager.deactivate()
        return .terminateNow
    }
}
