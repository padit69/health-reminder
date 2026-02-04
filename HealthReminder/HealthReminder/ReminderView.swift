//
//  ReminderView.swift
//  HealthReminder
//
//  Created by Dũng Phùng on 3/2/26.
//

import SwiftUI
import Combine

struct ReminderView: View {
    @ObservedObject var appState: AppState
    @ObservedObject var timerManager: TimerManager
    @State private var countdown: Int = 0
    @State private var opacity: Double = 0
    @State private var scale: CGFloat = 0.8
    @State private var breathingScale: CGFloat = 1.0
    @State private var blurRadius: CGFloat = 0
    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    private var reminderType: ReminderType {
        appState.currentReminderType
    }
    
    private var reminderSettings: ReminderSettings {
        appState.settings.settings(for: reminderType)
    }
    
    private var displayStyle: DisplayStyle {
        appState.settings.displayStyle
    }
    
    private var forceFocusMode: Bool {
        appState.settings.forceFocusMode
    }
    
    private var canDismiss: Bool {
        !forceFocusMode || countdown == 0
    }
    
    var progress: Double {
        guard reminderSettings.durationSeconds > 0 else { return 0 }
        return Double(countdown) / Double(reminderSettings.durationSeconds)
    }
    
    var body: some View {
        Group {
            switch displayStyle {
            case .modern:
                ModernStyleView(
                    reminderType: reminderType,
                    countdown: countdown,
                    progress: progress,
                    opacity: opacity,
                    scale: scale,
                    breathingScale: breathingScale,
                    blurRadius: blurRadius,
                    canDismiss: canDismiss,
                    onDismiss: dismissReminder
                )
            case .minimal:
                MinimalStyleView(
                    reminderType: reminderType,
                    countdown: countdown,
                    progress: progress,
                    opacity: opacity,
                    scale: scale,
                    canDismiss: canDismiss,
                    onDismiss: dismissReminder
                )
            case .bold:
                BoldStyleView(
                    reminderType: reminderType,
                    countdown: countdown,
                    progress: progress,
                    opacity: opacity,
                    scale: scale,
                    breathingScale: breathingScale,
                    canDismiss: canDismiss,
                    onDismiss: dismissReminder
                )
            }
        }
        .onAppear {
            countdown = reminderSettings.durationSeconds
            
            // Entrance animation
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                opacity = 1.0
                scale = 1.0
            }
            
            if displayStyle == .modern || displayStyle == .bold {
                withAnimation(.easeOut(duration: 0.5)) {
                    blurRadius = 30
                }
            }
            
            // Start breathing animation for modern and bold styles
            if displayStyle == .modern || displayStyle == .bold {
                startBreathingAnimation()
            }
        }
        .onReceive(timer) { _ in
            if countdown > 0 {
                countdown -= 1
            } else {
                dismissReminder()
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("DismissReminder"))) { _ in
            dismissReminder()
        }
        .background(KeyEventHandlingView(onEscape: dismissReminder))
    }
    
    private func startBreathingAnimation() {
        withAnimation(
            Animation.easeInOut(duration: 3.0)
                .repeatForever(autoreverses: true)
        ) {
            breathingScale = 1.15
        }
    }
    
    private func dismissReminder() {
        // Don't allow dismissal in focus mode unless countdown is complete
        guard canDismiss else { return }
        
        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
            opacity = 0.0
            scale = 0.9
        }
        
        withAnimation(.easeIn(duration: 0.3)) {
            blurRadius = 0
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            timerManager.dismissReminder()
        }
    }
}

// MARK: - Modern Style View
struct ModernStyleView: View {
    let reminderType: ReminderType
    let countdown: Int
    let progress: Double
    let opacity: Double
    let scale: CGFloat
    let breathingScale: CGFloat
    let blurRadius: CGFloat
    let canDismiss: Bool
    let onDismiss: () -> Void
    
    var body: some View {
        ZStack {
            // Soft gradient background - reduced brightness for eye comfort
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(red: 0.12, green: 0.18, blue: 0.35).opacity(0.96),
                    Color(red: 0.16, green: 0.22, blue: 0.38).opacity(0.96)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            .blur(radius: blurRadius)
            
            // Floating particles effect (subtle)
            ForEach(0..<8, id: \.self) { index in
                Circle()
                    .fill(Color.white.opacity(0.03))
                    .frame(width: CGFloat.random(in: 40...80))
                    .offset(
                        x: CGFloat.random(in: -400...400),
                        y: CGFloat.random(in: -300...300)
                    )
                    .blur(radius: 20)
            }
            
            // Main content card with glassmorphism
            VStack(spacing: 32) {
                Spacer()
                
                // Breathing icon with soft gradient
                ZStack {
                    // Gentle glow effect - reduced for eye comfort
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [
                                    reminderType.color.opacity(0.2),
                                    reminderType.color.opacity(0.08),
                                    Color.clear
                                ],
                                center: .center,
                                startRadius: 20,
                                endRadius: 80
                            )
                        )
                        .frame(width: 160, height: 160)
                        .blur(radius: 20)
                        .scaleEffect(breathingScale)
                    
                    // Icon with comfortable brightness
                    Image(systemName: reminderType.icon)
                        .font(.system(size: 80, weight: .light))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [reminderType.color.opacity(0.9), reminderType.color.opacity(0.7)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .scaleEffect(breathingScale)
                        .shadow(color: reminderType.color.opacity(0.3), radius: 15, x: 0, y: 0)
                }
                .padding(.bottom, 8)
                
                // Main title with better typography
                VStack(spacing: 12) {
                    Text(reminderType.title)
                        .font(.system(size: 40, weight: .bold))
                        .foregroundColor(.white)
                        .shadow(color: .black.opacity(0.3), radius: 10, x: 0, y: 5)
                    
                    Text(reminderType.subtitle)
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(.white.opacity(0.9))
                    
                    Text(reminderType.helper)
                        .font(.system(size: 16))
                        .foregroundColor(.white.opacity(0.7))
                }
                .multilineTextAlignment(.center)
                
                // Enhanced countdown circle with comfortable brightness
                ZStack {
                    // Subtle outer glow ring
                    Circle()
                        .stroke(reminderType.color.opacity(0.12), lineWidth: 3)
                        .frame(width: 180, height: 180)
                        .blur(radius: 8)
                    
                    // Background ring
                    Circle()
                        .stroke(
                            Color.white.opacity(0.12),
                            style: StrokeStyle(lineWidth: 12, lineCap: .round)
                        )
                        .frame(width: 180, height: 180)
                    
                    // Progress ring with soft gradient
                    Circle()
                        .trim(from: 0, to: progress)
                        .stroke(
                            AngularGradient(
                                gradient: Gradient(colors: [reminderType.color.opacity(0.9), reminderType.color.opacity(0.7), reminderType.color.opacity(0.9)]),
                                center: .center,
                                startAngle: .degrees(0),
                                endAngle: .degrees(360)
                            ),
                            style: StrokeStyle(lineWidth: 12, lineCap: .round)
                        )
                        .frame(width: 180, height: 180)
                        .rotationEffect(.degrees(-90))
                        .animation(.linear(duration: 1), value: countdown)
                        .shadow(color: reminderType.color.opacity(0.4), radius: 8, x: 0, y: 0)
                    
                    // Inner content with comfortable contrast
                    VStack(spacing: 8) {
                        Text("\(countdown)")
                            .font(.system(size: 64, weight: .bold, design: .rounded))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [.white.opacity(0.95), .white.opacity(0.85)],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                            .shadow(color: reminderType.color.opacity(0.3), radius: 8, x: 0, y: 0)
                            .contentTransition(.numericText())
                        
                        Text("seconds")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.white.opacity(0.7))
                            .textCase(.uppercase)
                            .tracking(2)
                    }
                }
                .padding(.vertical, 24)
                
                Spacer()
                
                // Modern dismiss button
                Button(action: onDismiss) {
                    HStack(spacing: 10) {
                        Image(systemName: canDismiss ? "xmark.circle.fill" : "lock.fill")
                            .font(.system(size: 18))
                        Text(canDismiss ? "Skip Break" : "Focus Mode")
                            .font(.system(size: 17, weight: .semibold))
                        if canDismiss {
                            Text("(ESC)")
                                .font(.system(size: 14, weight: .regular))
                                .opacity(0.7)
                        }
                    }
                    .foregroundColor(canDismiss ? .white : .white.opacity(0.5))
                    .padding(.horizontal, 32)
                    .padding(.vertical, 16)
                    .background(
                        Capsule()
                            .fill(Color.white.opacity(canDismiss ? 0.15 : 0.08))
                            .overlay(
                                Capsule()
                                    .stroke(Color.white.opacity(canDismiss ? 0.3 : 0.15), lineWidth: 1)
                            )
                            .shadow(color: .black.opacity(0.2), radius: 10, x: 0, y: 5)
                    )
                    .background(
                        Capsule()
                            .fill(Color.white.opacity(0.05))
                            .blur(radius: 20)
                            .padding(-10)
                    )
                }
                .buttonStyle(.plain)
                .disabled(!canDismiss)
                .scaleEffect(opacity > 0.5 ? 1.0 : 0.9)
                
                Spacer()
                    .frame(height: 40)
            }
            .padding(60)
            .scaleEffect(scale)
        }
        .opacity(opacity)
    }
}

// MARK: - Minimal Style View
struct MinimalStyleView: View {
    let reminderType: ReminderType
    let countdown: Int
    let progress: Double
    let opacity: Double
    let scale: CGFloat
    let canDismiss: Bool
    let onDismiss: () -> Void
    
    var body: some View {
        ZStack {
            // Soft warm background - easier on eyes than pure white
            Color(red: 0.98, green: 0.97, blue: 0.95)
                .ignoresSafeArea()
            
            // Subtle vignette effect to reduce brightness at edges
            RadialGradient(
                colors: [
                    Color.clear,
                    Color.black.opacity(0.03)
                ],
                center: .center,
                startRadius: 200,
                endRadius: 600
            )
            .ignoresSafeArea()
            
            VStack(spacing: 40) {
                Spacer()
                
                // Simple icon with soft color
                Image(systemName: reminderType.icon)
                    .font(.system(size: 80, weight: .regular))
                    .foregroundColor(reminderType.color.opacity(0.85))
                
                // Clean title with comfortable contrast
                VStack(spacing: 16) {
                    Text(reminderType.title)
                        .font(.system(size: 36, weight: .semibold))
                        .foregroundColor(Color(red: 0.2, green: 0.2, blue: 0.2))
                    
                    Text(reminderType.subtitle)
                        .font(.system(size: 18, weight: .regular))
                        .foregroundColor(Color(red: 0.4, green: 0.4, blue: 0.4))
                        .multilineTextAlignment(.center)
                }
                
                // Simple countdown with progress bar
                VStack(spacing: 20) {
                    Text("\(countdown)")
                        .font(.system(size: 80, weight: .light, design: .rounded))
                        .foregroundColor(Color(red: 0.25, green: 0.25, blue: 0.25))
                        .contentTransition(.numericText())
                    
                    // Linear progress bar with rounded ends
                    GeometryReader { geometry in
                        ZStack(alignment: .leading) {
                            Capsule()
                                .fill(Color.gray.opacity(0.15))
                                .frame(height: 6)
                            
                            Capsule()
                                .fill(reminderType.color.opacity(0.8))
                                .frame(width: max(6, geometry.size.width * progress), height: 6)
                                .animation(.linear(duration: 1), value: countdown)
                        }
                    }
                    .frame(width: 300, height: 6)
                }
                
                Spacer()
                
                // Simple text button with soft colors
                Button(action: onDismiss) {
                    HStack(spacing: 6) {
                        if !canDismiss {
                            Image(systemName: "lock.fill")
                                .font(.system(size: 13))
                        }
                        Text(canDismiss ? "Skip (ESC)" : "Focus Mode")
                            .font(.system(size: 16, weight: .medium))
                    }
                    .foregroundColor(canDismiss ? Color(red: 0.5, green: 0.5, blue: 0.5) : Color(red: 0.7, green: 0.7, blue: 0.7))
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.gray.opacity(canDismiss ? 0.25 : 0.15), lineWidth: 1)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(Color.white.opacity(canDismiss ? 0.5 : 0.3))
                            )
                    )
                }
                .buttonStyle(.plain)
                .disabled(!canDismiss)
                
                Spacer()
                    .frame(height: 40)
            }
            .scaleEffect(scale)
        }
        .opacity(opacity)
    }
}

// MARK: - Bold Style View
struct BoldStyleView: View {
    let reminderType: ReminderType
    let countdown: Int
    let progress: Double
    let opacity: Double
    let scale: CGFloat
    let breathingScale: CGFloat
    let canDismiss: Bool
    let onDismiss: () -> Void
    
    var body: some View {
        ZStack {
            // Rich but comfortable background - reduced saturation for eye comfort
            reminderType.color.opacity(0.85)
                .ignoresSafeArea()
            
            // Soft gradient overlay to reduce brightness
            LinearGradient(
                colors: [
                    reminderType.color.opacity(0.7),
                    reminderType.color.opacity(0.65),
                    reminderType.color.opacity(0.75)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            // Subtle dark overlay to reduce overall brightness
            Color.black.opacity(0.1)
                .ignoresSafeArea()
            
            // Subtle diagonal stripes pattern - very low opacity
            GeometryReader { geometry in
                Path { path in
                    let stripeWidth: CGFloat = 100
                    let spacing: CGFloat = 200
                    for i in stride(from: -geometry.size.height, to: geometry.size.width + geometry.size.height, by: spacing) {
                        path.move(to: CGPoint(x: i, y: 0))
                        path.addLine(to: CGPoint(x: i + geometry.size.height, y: geometry.size.height))
                        path.addLine(to: CGPoint(x: i + geometry.size.height + stripeWidth, y: geometry.size.height))
                        path.addLine(to: CGPoint(x: i + stripeWidth, y: 0))
                        path.closeSubpath()
                    }
                }
                .fill(Color.white.opacity(0.03))
            }
            
            VStack(spacing: 36) {
                Spacer()
                
                // Dramatic icon with pulse effect - softer glow
                ZStack {
                    // Soft glow layers - reduced opacity for eye comfort
                    ForEach(0..<3) { index in
                        Circle()
                            .fill(Color.white.opacity(0.15 - Double(index) * 0.05))
                            .frame(width: 140 + CGFloat(index * 40), height: 140 + CGFloat(index * 40))
                            .blur(radius: 30)
                            .scaleEffect(breathingScale)
                    }
                    
                    Image(systemName: reminderType.icon)
                        .font(.system(size: 90, weight: .bold))
                        .foregroundColor(.white.opacity(0.95))
                        .scaleEffect(breathingScale)
                        .shadow(color: .black.opacity(0.25), radius: 15, x: 0, y: 8)
                }
                
                // Bold title with strong contrast
                VStack(spacing: 14) {
                    Text(reminderType.title)
                        .font(.system(size: 44, weight: .black))
                        .foregroundColor(.white)
                        .shadow(color: .black.opacity(0.3), radius: 10, x: 0, y: 5)
                        .textCase(.uppercase)
                        .tracking(1)
                    
                    Text(reminderType.subtitle)
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.white.opacity(0.95))
                }
                .multilineTextAlignment(.center)
                
                // Dramatic countdown with circular progress
                ZStack {
                    // Large outer ring
                    Circle()
                        .stroke(Color.white.opacity(0.2), lineWidth: 16)
                        .frame(width: 200, height: 200)
                    
                    // Animated progress ring
                    Circle()
                        .trim(from: 0, to: progress)
                        .stroke(
                            Color.white,
                            style: StrokeStyle(lineWidth: 16, lineCap: .round)
                        )
                        .frame(width: 200, height: 200)
                        .rotationEffect(.degrees(-90))
                        .animation(.linear(duration: 1), value: countdown)
                        .shadow(color: .black.opacity(0.3), radius: 15, x: 0, y: 0)
                    
                    // Bold countdown number
                    VStack(spacing: 6) {
                        Text("\(countdown)")
                            .font(.system(size: 72, weight: .black, design: .rounded))
                            .foregroundColor(.white)
                            .shadow(color: .black.opacity(0.4), radius: 15, x: 0, y: 5)
                            .contentTransition(.numericText())
                        
                        Text("SEC")
                            .font(.system(size: 16, weight: .black))
                            .foregroundColor(.white.opacity(0.8))
                            .tracking(3)
                    }
                }
                .padding(.vertical, 20)
                
                Spacer()
                
                // Bold dismiss button
                Button(action: onDismiss) {
                    HStack(spacing: 12) {
                        Image(systemName: canDismiss ? "xmark.circle.fill" : "lock.fill")
                            .font(.system(size: 20, weight: .bold))
                        Text(canDismiss ? "SKIP" : "LOCKED")
                            .font(.system(size: 18, weight: .black))
                            .tracking(2)
                    }
                    .foregroundColor(canDismiss ? reminderType.color : reminderType.color.opacity(0.5))
                    .padding(.horizontal, 40)
                    .padding(.vertical, 18)
                    .background(
                        Capsule()
                            .fill(canDismiss ? Color.white : Color.white.opacity(0.6))
                            .shadow(color: .black.opacity(canDismiss ? 0.3 : 0.15), radius: 15, x: 0, y: 8)
                    )
                }
                .buttonStyle(.plain)
                .disabled(!canDismiss)
                
                Spacer()
                    .frame(height: 40)
            }
            .padding(60)
            .scaleEffect(scale)
        }
        .opacity(opacity)
    }
}

// Helper view to handle keyboard events
struct KeyEventHandlingView: NSViewRepresentable {
    let onEscape: () -> Void
    
    func makeNSView(context: Context) -> NSView {
        let view = KeyEventNSView(onEscape: onEscape)
        DispatchQueue.main.async {
            view.window?.makeFirstResponder(view)
        }
        return view
    }
    
    func updateNSView(_ nsView: NSView, context: Context) {}
}

class KeyEventNSView: NSView {
    let onEscape: () -> Void
    
    init(onEscape: @escaping () -> Void) {
        self.onEscape = onEscape
        super.init(frame: .zero)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override var acceptsFirstResponder: Bool { true }
    
    override func keyDown(with event: NSEvent) {
        if event.keyCode == 53 { // ESC key
            onEscape()
        } else {
            super.keyDown(with: event)
        }
    }
}
