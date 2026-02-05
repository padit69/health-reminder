//
//  MenuBarView.swift
//  HealthReminder
//
//  Created by Dũng Phùng on 3/2/26.
//

import SwiftUI
import AppKit

struct MenuBarView: View {
    @ObservedObject var appState: AppState
    @ObservedObject var timerManager: TimerManager
    @ObservedObject var multiReminderManager: MultiReminderManager
    @EnvironmentObject var updateChecker: UpdateChecker
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "heart.text.square.fill")
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.pink, .red],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                    Text("Health Reminder")
                        .font(.headline)
                }
                
                if multiReminderManager.isRunning {
                    Text("Active reminders")
                        .font(.caption)
                        .foregroundColor(.secondary)
                } else {
                    Text("All reminders paused")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding(12)
            
            Divider()
            
            // Timers Status - Show when running or paused (hide only when stopped)
            if multiReminderManager.isRunning || multiReminderManager.isPaused {
                VStack(spacing: 0) {
                    TimerStatusRow(
                        type: .eyes,
                        timer: multiReminderManager.eyesTimer
                    )
                    
                    Divider()
                    
                    TimerStatusRow(
                        type: .water,
                        timer: multiReminderManager.waterTimer
                    )
                    
                    Divider()
                    
                    TimerStatusRow(
                        type: .standup,
                        timer: multiReminderManager.standupTimer
                    )
                }
            }
            
            Divider()
            
            // Controls
            VStack(spacing: 0) {
                // Show Start button only when completely stopped
                if !multiReminderManager.isRunning && !multiReminderManager.isPaused {
                    Button(action: {
                        multiReminderManager.start()
                    }) {
                        HStack {
                            Image(systemName: "play.fill")
                            Text("Start All")
                            Spacer()
                        }
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color.clear)
                    .onHover { isHovered in
                        if isHovered {
                            NSCursor.pointingHand.push()
                        } else {
                            NSCursor.pop()
                        }
                    }
                }
                
                // Show Pause button when running
                if multiReminderManager.isRunning {
                    Button(action: {
                        multiReminderManager.pause()
                    }) {
                        HStack {
                            Image(systemName: "pause.fill")
                            Text("Pause All")
                            Spacer()
                        }
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color.clear)
                    .onHover { isHovered in
                        if isHovered {
                            NSCursor.pointingHand.push()
                        } else {
                            NSCursor.pop()
                        }
                    }
                }
                
                // Show Resume button when paused
                if !multiReminderManager.isRunning && multiReminderManager.isPaused {
                    Button(action: {
                        multiReminderManager.start()
                    }) {
                        HStack {
                            Image(systemName: "play.fill")
                            Text("Resume All")
                            Spacer()
                        }
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color.clear)
                    .onHover { isHovered in
                        if isHovered {
                            NSCursor.pointingHand.push()
                        } else {
                            NSCursor.pop()
                        }
                    }
                }
                
                // Show Stop button when running or paused (not when stopped)
                if multiReminderManager.isRunning || multiReminderManager.isPaused {
                    Button(action: {
                        multiReminderManager.stop()
                    }) {
                        HStack {
                            Image(systemName: "stop.fill")
                            Text("Stop All")
                            Spacer()
                        }
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color.clear)
                    .onHover { isHovered in
                        if isHovered {
                            NSCursor.pointingHand.push()
                        } else {
                            NSCursor.pop()
                        }
                    }
                }
                
                Divider()
                
                Button(action: {
                    openSettings()
                }) {
                    HStack {
                        Image(systemName: "gearshape")
                        Text("Settings")
                        Spacer()
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .onHover { isHovered in
                    if isHovered {
                        NSCursor.pointingHand.push()
                    } else {
                        NSCursor.pop()
                    }
                }
                
                Divider()
                
                Button(action: {
                    NSApplication.shared.terminate(nil)
                }) {
                    HStack {
                        Image(systemName: "power")
                        Text("Quit")
                        Spacer()
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .onHover { isHovered in
                    if isHovered {
                        NSCursor.pointingHand.push()
                    } else {
                        NSCursor.pop()
                    }
                }
            }
        }
        .frame(width: 280)
    }
    
    private func openSettings() {
        // Close menu bar dropdown first
        closeMenuBarMenu()
        
        // Try to find existing Settings window first
        if let existingWindow = NSApp.windows.first(where: { $0.identifier?.rawValue == "SettingsWindow" }) {
            // Show dock icon
            NSApp.setActivationPolicy(.regular)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                NSApp.activate(ignoringOtherApps: true)
                existingWindow.makeKeyAndOrderFront(nil)
            }
            return
        }
        
        // Create new settings window
        let settingsView = SettingsView(appState: appState, timerManager: timerManager)
            .environmentObject(updateChecker)
        let hostingController = NSHostingController(rootView: settingsView)
        
        let window = NSWindow(contentViewController: hostingController)
        window.title = "Settings"
        window.identifier = NSUserInterfaceItemIdentifier("SettingsWindow")
        window.styleMask = [.titled, .closable, .miniaturizable]
        window.setContentSize(NSSize(width: 700, height: 500))
        window.center()
        window.isReleasedWhenClosed = false
        
        // Setup window delegate to manage dock icon
        let delegate = SettingsWindowDelegate()
        window.delegate = delegate
        
        // Store reference
        SettingsWindowManager.shared.settingsWindow = window
        SettingsWindowManager.shared.windowDelegate = delegate
        
        // Show dock icon FIRST
        NSApp.setActivationPolicy(.regular)
        
        // Small delay to ensure activation policy takes effect
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            NSApp.activate(ignoringOtherApps: true)
            window.makeKeyAndOrderFront(nil)
        }
    }
    
    /// Đóng menu bar dropdown (popup) khi nhấn Settings
    private func closeMenuBarMenu() {
        for window in NSApp.windows {
            if window.level == .popUpMenu {
                window.orderOut(nil)
                window.close()
                break
            }
        }
    }
}

// Timer Status Row Component
struct TimerStatusRow: View {
    let type: ReminderType
    @ObservedObject var timer: SingleReminderTimer
    
    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: type.icon)
                .font(.system(size: 14))
                .foregroundColor(timer.isEnabled ? type.color : .gray)
                .frame(width: 20)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(type.rawValue)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(timer.isEnabled ? .primary : .secondary)
                
                if timer.isEnabled {
                    Text(timer.formatTimeRemaining())
                        .font(.system(size: 11, design: .monospaced))
                        .foregroundColor(.secondary)
                        .monospacedDigit()
                } else {
                    Text("Disabled")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            if timer.isEnabled {
                Circle()
                    .fill(type.color)
                    .frame(width: 6, height: 6)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .animation(.none, value: timer.timeRemaining) // Disable animation for performance
    }
}

// Singleton to keep reference to settings window
class SettingsWindowManager {
    static let shared = SettingsWindowManager()
    var settingsWindow: NSWindow?
    var windowDelegate: SettingsWindowDelegate?
    
    private init() {}
}

// Window delegate to handle Settings window close event
class SettingsWindowDelegate: NSObject, NSWindowDelegate {
    func windowWillClose(_ notification: Notification) {
        print("Settings window closing - hiding dock icon")
        // Hide dock icon when Settings window closes
        NSApp.setActivationPolicy(.accessory)
        // Clean up reference
        SettingsWindowManager.shared.settingsWindow = nil
        SettingsWindowManager.shared.windowDelegate = nil
    }
    
    func windowDidBecomeKey(_ notification: Notification) {
        print("Settings window became key - ensuring dock icon visible")
        // Ensure dock icon is visible when window becomes key
        NSApp.setActivationPolicy(.regular)
    }
}
