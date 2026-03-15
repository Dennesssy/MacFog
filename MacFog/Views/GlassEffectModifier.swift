import SwiftUI

struct GlassEffectModifier: ViewModifier {
    func body(content: Content) -> some View {
        if #available(macOS 26.0, *) {
            content.glassEffect()
        } else {
            content
        }
    }
}

extension View {
    func glassEffectConditional() -> some View {
        self.modifier(GlassEffectModifier())
    }
}
