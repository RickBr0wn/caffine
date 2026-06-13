import AppKit

class AppDelegate: NSObject, NSApplicationDelegate {
    private var menuBarManager: MenuBarManager!
    private let caffeineManager = CaffeineManager.shared
    private let timerManager = TimerManager.shared

    func applicationDidFinishLaunching(_ notification: Notification) {
        CaffeineShortcutsProvider.updateAppShortcutParameters()
        NotificationManager.requestPermission()
        menuBarManager = MenuBarManager(caffeineManager: caffeineManager, timerManager: timerManager)
        timerManager.onExpiry = { [weak self] in
            self?.caffeineManager.deactivate()
            NotificationManager.sendExpiryNotification()
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
