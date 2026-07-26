import SwiftUI
import UIKit

extension DynamicTypeSize {
    /// Mapeo a UIContentSizeCategory para poder calcular el factor de escala
    /// real de Dynamic Type con UIFontMetrics.
    var uiContentSizeCategory: UIContentSizeCategory {
        switch self {
        case .xSmall: return .extraSmall
        case .small: return .small
        case .medium: return .medium
        case .large: return .large
        case .xLarge: return .extraLarge
        case .xxLarge: return .extraExtraLarge
        case .xxxLarge: return .extraExtraExtraLarge
        case .accessibility1: return .accessibilityMedium
        case .accessibility2: return .accessibilityLarge
        case .accessibility3: return .accessibilityExtraLarge
        case .accessibility4: return .accessibilityExtraExtraLarge
        case .accessibility5: return .accessibilityExtraExtraExtraLarge
        @unknown default: return .large
        }
    }
}

private struct ScaledFontModifier: ViewModifier {
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    let size: CGFloat
    let weight: Font.Weight

    func body(content: Content) -> some View {
        content.font(.system(size: scaledSize, weight: weight))
    }

    /// Escala `size` con UIFontMetrics igual que lo haría un estilo semántico
    /// (.body, .headline, etc.), pero partiendo de un tamaño fijo en puntos.
    /// Se capa en .accessibility1 para no romper grillas/checkboxes de
    /// tamaño fijo (day picker, series de ActiveWorkoutView) en las
    /// categorías de accesibilidad más extremas.
    private var scaledSize: CGFloat {
        let cappedSize = min(dynamicTypeSize, .accessibility1)
        let traits = UITraitCollection(preferredContentSizeCategory: cappedSize.uiContentSizeCategory)
        return UIFontMetrics(forTextStyle: .body).scaledValue(for: size, compatibleWith: traits)
    }
}

extension View {
    /// Como `.font(.system(size:weight:))`, pero escala con el ajuste de
    /// tamaño de texto de iOS (Dynamic Type) en vez de quedar fijo.
    func scaledFont(size: CGFloat, weight: Font.Weight = .regular) -> some View {
        modifier(ScaledFontModifier(size: size, weight: weight))
    }
}
