import AppKit
import Combine
import SwiftUI

class MenuBarManager: NSObject, NSPopoverDelegate {
    private var statusItem: NSStatusItem
    private var popover: NSPopover
    private let caffeineManager: CaffeineManager
    private let timerManager: TimerManager
    private var cancellables = Set<AnyCancellable>()
    private var popoverClosedAt: Date = .distantPast

    init(caffeineManager: CaffeineManager, timerManager: TimerManager) {
        self.caffeineManager = caffeineManager
        self.timerManager = timerManager

        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

        let menuView = MenuView(caffeineManager: caffeineManager, timerManager: timerManager)
            .preferredColorScheme(.dark)
        let hosting = NSHostingController(rootView: menuView)
        hosting.sizingOptions = .preferredContentSize

        popover = NSPopover()
        popover.behavior = .transient
        popover.appearance = NSAppearance(named: .darkAqua)
        popover.contentViewController = hosting

        super.init()

        popover.delegate = self

        if let button = statusItem.button {
            button.image = NSImage(systemSymbolName: "cup.and.saucer", accessibilityDescription: "Caffeine")
            button.image?.isTemplate = true
            button.action = #selector(togglePopover)
            button.target = self
        }

        subscribeToChanges()
    }

    private func subscribeToChanges() {
        caffeineManager.$isActive
            .receive(on: DispatchQueue.main)
            .sink { [weak self] active in self?.updateIcon(active: active) }
            .store(in: &cancellables)

        timerManager.$remainingSeconds
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in self?.updateTitle() }
            .store(in: &cancellables)
    }

    private func updateIcon(active: Bool) {
        let name = active ? "cup.and.saucer.fill" : "cup.and.saucer"
        let image = NSImage(systemSymbolName: name, accessibilityDescription: "Caffeine")
        image?.isTemplate = true
        statusItem.button?.image = image
        updateTitle()
    }

    private func updateTitle() {
        if let remaining = timerManager.formattedRemaining {
            statusItem.button?.title = " \(remaining)"
        } else {
            statusItem.button?.title = ""
        }
    }

    @objc private func togglePopover() {
        if popover.isShown {
            popover.performClose(nil)
        } else if Date().timeIntervalSince(popoverClosedAt) > 0.15 {
            if let button = statusItem.button {
                popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
            }
        }
    }

    func popoverDidClose(_ notification: Notification) {
        popoverClosedAt = Date()
    }
}
