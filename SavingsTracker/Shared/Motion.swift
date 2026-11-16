import SwiftUI

/// Shared animation timings, so the whole app moves the same way.
enum Motion {
    static let slowKey = "slowAnimations"
    /// 0.25 when slow animations are switched on (for checking motion), otherwise 1.
    private static var speed: Double { UserDefaults.standard.bool(forKey: slowKey) ? 0.25 : 1 }

    static var entrance: Animation { .spring(duration: 0.5, bounce: 0.18).speed(speed) }
    static var change: Animation { .snappy(duration: 0.35).speed(speed) }
    static var chart: Animation { .spring(duration: 0.8, bounce: 0.12).speed(speed) }
}

/// Fades and lifts a view into place each time it appears (e.g. switching tabs).
/// `index` staggers several views so they arrive one after another.
private struct Reveal: ViewModifier {
    let index: Int
    @State private var shown = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func body(content: Content) -> some View {
        content
            .opacity(shown ? 1 : 0)
            .offset(y: shown || reduceMotion ? 0 : 18)
            .scaleEffect(shown || reduceMotion ? 1 : 0.98, anchor: .top)
            .onAppear {
                withAnimation(Motion.entrance.delay(Double(index) * 0.06)) { shown = true }
            }
            .onDisappear { shown = false }
    }
}

/// Grows a value from 0 to 1 each time the view appears; multiply chart values by it.
struct GrowOnAppear: ViewModifier {
    @Binding var progress: Double
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func body(content: Content) -> some View {
        content
            .onAppear {
                if reduceMotion { progress = 1; return }
                withAnimation(Motion.chart.delay(0.15)) { progress = 1 }
            }
            .onDisappear { progress = 0 }
    }
}

/// Makes buttons and cards squish slightly while pressed.
struct PressableStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .opacity(configuration.isPressed ? 0.85 : 1)
            .animation(.snappy(duration: 0.2), value: configuration.isPressed)
    }
}

extension View {
    func reveal(_ index: Int = 0) -> some View { modifier(Reveal(index: index)) }

    /// Rolls the digits when an amount changes instead of swapping it instantly.
    func rollingNumber(_ value: Decimal) -> some View {
        contentTransition(.numericText(value: value.double))
            .animation(Motion.change, value: value)
    }
}
