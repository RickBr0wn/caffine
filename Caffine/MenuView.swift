import SwiftUI
import ServiceManagement

struct MenuView: View {
    @ObservedObject var caffeineManager: CaffeineManager
    @ObservedObject var timerManager: TimerManager
    @State private var showDuration = false
    @State private var settingsExpanded = true
    @AppStorage("activateAtLaunch") private var activateAtLaunch = false
    @State private var loginEnabled = SMAppService.mainApp.status == .enabled

    var body: some View {
        Group {
            if showDuration {
                DurationView(
                    timerManager: timerManager,
                    caffeineManager: caffeineManager,
                    showDuration: $showDuration
                )
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
                Toggle("", isOn: caffeineBinding)
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
            }

            menuDivider

            HoverRow(action: { NSApp.orderFrontStandardAboutPanel(nil) }) {
                Text("About").foregroundStyle(.primary)
            }
            HoverRow(action: { NSApplication.shared.terminate(nil) }) {
                Text("Quit Caffeine").foregroundStyle(.primary)
            }
        }
    }

    private var caffeineBinding: Binding<Bool> {
        Binding(
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
        )
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
