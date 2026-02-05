//
//  AppState.swift
//  HealthReminder
//
//  Created by Dũng Phùng on 3/2/26.
//

import Foundation
import SwiftUI
import Combine

@MainActor
class AppState: ObservableObject {
    @Published var isReminderActive: Bool = false
    @Published var settings: AppSettings
    @Published var showingSettings: Bool = false
    @Published var showingReminder: Bool = false
    @Published var currentReminderType: ReminderType = .eyes
    /// True when reminder is shown from Settings preview (cho phép hiển thị overlay dù timer chưa chạy)
    @Published var isPreviewMode: Bool = false
    
    static let shared = AppState()
    
    private init() {
        self.settings = AppSettings.load()
    }
    
    func toggleReminder() {
        isReminderActive.toggle()
    }
    
    func updateSettings(_ newSettings: AppSettings) {
        settings = newSettings
        newSettings.save()
    }
    
    func showReminder(type: ReminderType, preview: Bool = false) {
        currentReminderType = type
        isPreviewMode = preview
        showingReminder = true
    }
}
