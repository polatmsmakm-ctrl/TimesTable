import SwiftUI

extension Color {
    init(hex: UInt32) {
        self.init(.sRGB,
                  red: Double((hex >> 16) & 0xFF) / 255,
                  green: Double((hex >> 8) & 0xFF) / 255,
                  blue: Double(hex & 0xFF) / 255,
                  opacity: 1)
    }
}

enum Theme {
    static let bg = Color(hex: 0x0E1116)
    static let card = Color(hex: 0x171B22)
    static let line = Color(hex: 0x2A303B)
    static let text = Color(hex: 0xEDEFF4)
    static let dim = Color(hex: 0xA9B2C0)
    static let gold = Color(hex: 0xF2B84B)
    static let teal = Color(hex: 0x4FD1C5)
    static let pink = Color(hex: 0xFF7A8A)
    static let green = Color(hex: 0x5BD68A)
}

/// يعزل النص (معادلة مثلًا) كي لا ينقلب ترتيبه داخل الجملة العربية.
func ltr(_ s: String) -> String {
    return "\u{2066}" + s + "\u{2069}"
}

struct CardStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(14)
            .background(Theme.card)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay(RoundedRectangle(cornerRadius: 16).stroke(Theme.line, lineWidth: 1))
    }
}

extension View {
    func card() -> some View {
        modifier(CardStyle())
    }
}
