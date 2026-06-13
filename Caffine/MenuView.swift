import SwiftUI
import ServiceManagement

struct MenuView: View {
    @ObservedObject var caffeineManager: CaffeineManager
    @ObservedObject var timerManager: TimerManager
    @State private var showDuration = false
    @State private var showAbout = false
    @State private var settingsExpanded = true
    @AppStorage("activateAtLaunch") private var activateAtLaunch = false
    @AppStorage("deactivateOnLock") private var deactivateOnLock = false
    @State private var loginEnabled = SMAppService.mainApp.status == .enabled

    var body: some View {
        Group {
            if showDuration {
                DurationView(
                    timerManager: timerManager,
                    caffeineManager: caffeineManager,
                    showDuration: $showDuration
                )
            } else if showAbout {
                AboutView(showAbout: $showAbout)
            } else {
                mainView
            }
        }
        .frame(width: 280)
        .background(Color(nsColor: .windowBackgroundColor))
    }

    private var mainView: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text("Caffeine")
                    .font(.headline)
                    .fontWeight(.bold)
                Spacer()
                Toggle("", isOn: Binding(
                    get: { caffeineManager.isActive },
                    set: { newValue in
                        if newValue {
                            caffeineManager.activate()
                            timerManager.start(duration: timerManager.selectedDuration)
                        } else {
                            caffeineManager.deactivate()
                            timerManager.stop()
                        }
                    }
                ))
                .toggleStyle(.switch)
                .labelsHidden()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)

            menuDivider

            HoverRow(action: { showDuration = true }) {
                HStack {
                    Text("Duration")
                        .foregroundStyle(.secondary)
                    Spacer()
                    if caffeineManager.isActive {
                        Text(timerManager.formattedRemaining ?? timerManager.selectedDuration.label)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Image(systemName: "chevron.right")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
            }

            menuDivider

            HoverRow(action: { settingsExpanded.toggle() }) {
                HStack {
                    Text("Settings")
                        .foregroundStyle(.secondary)
                    Spacer()
                    Image(systemName: settingsExpanded ? "chevron.down" : "chevron.right")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
            }

            if settingsExpanded {
                SettingsRow(icon: "power", active: loginEnabled, title: "Launch at login", action: toggleLogin)
                SettingsRow(icon: "bolt.fill", active: activateAtLaunch, title: "Activate at launch") {
                    activateAtLaunch.toggle()
                }
                SettingsRow(icon: "lock.fill", active: deactivateOnLock, title: "Deactivate on lock") {
                    deactivateOnLock.toggle()
                }
            }

            menuDivider

            HoverRow(action: { showAbout = true }) {
                Text("About").foregroundStyle(.primary)
            }
            HoverRow(action: { NSApplication.shared.terminate(nil) }) {
                Text("Quit Caffeine").foregroundStyle(.primary)
            }
        }
    }

    private func toggleLogin() {
        do {
            if loginEnabled {
                try SMAppService.mainApp.unregister()
            } else {
                try SMAppService.mainApp.register()
            }
            loginEnabled.toggle()
        } catch {
            // operation failed; loginEnabled stays unchanged so icon stays correct
        }
    }

    private var menuDivider: some View { Divider().opacity(0.3) }
}

struct DurationView: View {
    @ObservedObject var timerManager: TimerManager
    @ObservedObject var caffeineManager: CaffeineManager
    @Binding var showDuration: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HoverRow(action: { showDuration = false }) {
                HStack(spacing: 6) {
                    Image(systemName: "chevron.left").font(.caption)
                    Text("Duration").font(.headline).fontWeight(.bold)
                }
                .foregroundStyle(.primary)
            }

            Divider().opacity(0.3)

            ForEach(Duration.allCases, id: \.self) { duration in
                HoverRow(action: {
                    timerManager.start(duration: duration)
                    if !caffeineManager.isActive { caffeineManager.activate() }
                    showDuration = false
                }) {
                    HStack {
                        Text(duration.label).foregroundStyle(.primary)
                        Spacer()
                        if caffeineManager.isActive && timerManager.selectedDuration == duration {
                            Image(systemName: "checkmark").font(.caption).foregroundStyle(.blue)
                        }
                    }
                }
            }
        }
    }
}

struct SettingsRow: View {
    let icon: String
    let active: Bool
    let title: String
    let action: () -> Void

    var body: some View {
        HoverRow(action: action) {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(active ? Color.blue : Color.primary.opacity(0.18))
                        .frame(width: 28, height: 28)
                    Image(systemName: icon)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(.white)
                }
                Text(title).foregroundStyle(.primary)
                Spacer()
            }
        }
    }
}

struct AboutView: View {
    @Binding var showAbout: Bool

    private let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"

    var body: some View {
        VStack(spacing: 0) {
            HoverRow(action: { showAbout = false }) {
                HStack(spacing: 6) {
                    Image(systemName: "chevron.left").font(.caption)
                    Text("About").font(.headline).fontWeight(.bold)
                }
                .foregroundStyle(.primary)
            }

            Divider().opacity(0.3)

            VStack(spacing: 16) {
                VStack(spacing: 6) {
                    Text("☕").font(.system(size: 40))
                    Text("Caffeine")
                        .font(.title2)
                        .fontWeight(.bold)
                    Text("v\(version)")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
                .padding(.top, 8)

                Text("Keeps your Mac wide awake,\none cup at a time.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)

                Divider().opacity(0.3)

                VStack(spacing: 0) {
                    AboutLink(
                        systemIcon: "chevron.left.forwardslash.chevron.right",
                        label: "Source on GitHub",
                        url: "https://github.com/RickBr0wn/caffeine"
                    )
                    AboutLink(
                        systemIcon: "cup.and.saucer.fill",
                        label: "Buy me a coffee",
                        url: "https://buymeacoffee.com/RickBrown"
                    )
                    AboutLink(
                        systemIcon: "briefcase.fill",
                        label: "Hire me. No seriously.",
                        url: "mailto:ricky.brown.00@gmail.com"
                    )
                }

                Text("Built with ☕ and SwiftUI")
                    .font(.caption2)
                    .foregroundStyle(.quaternary)
                    .padding(.bottom, 8)
            }
            .padding(.horizontal, 16)
        }
    }
}

struct AboutLink: View {
    let systemIcon: String
    let label: String
    let url: String

    var body: some View {
        HoverRow(action: {
            if let u = URL(string: url) { NSWorkspace.shared.open(u) }
        }) {
            HStack(spacing: 10) {
                Image(systemName: systemIcon)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(.secondary)
                    .frame(width: 18)
                Text(label).foregroundStyle(.primary)
                Spacer()
                Image(systemName: "arrow.up.right")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
        }
    }
}

struct HoverRow<Content: View>: View {
    let action: () -> Void
    @ViewBuilder let content: Content
    @State private var isHovered = false

    var body: some View {
        Button(action: action) {
            content
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(isHovered ? Color.primary.opacity(0.08) : Color.clear)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .onHover { isHovered = $0 }
    }
}
