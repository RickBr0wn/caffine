import AppKit

class AppDelegate: NSObject, NSApplicationDelegate {
    private var menuBarManager: MenuBarManager!
    private let caffeineManager = CaffeineManager.shared
    private let timerManager = TimerManager.shared
    private var screenLockObserver: Any?

    func applicationDidFinishLaunching(_ notification: Notification) {
        CaffeineShortcutsProvider.updateAppShortcutParameters()
        NotificationManager.requestPermission()
        menuBarManager = MenuBarManager(caffeineManager: caffeineManager, timerManager: timerManager)
        timerManager.onExpiry = { [weak self] in
            self?.caffeineManager.deactivate()
            NotificationManager.sendExpiryNotification()
        }
        screenLockObserver = DistributedNotificationCenter.default().addObserver(
            forName: NSNotification.Name("com.apple.screenIsLocked"),
            object: nil,
            queue: .main
        ) { [weak self] _ in
            guard UserDefaults.standard.bool(forKey: "deactivateOnLock") else { return }
            self?.caffeineManager.deactivate()
            self?.timerManager.stop()
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
