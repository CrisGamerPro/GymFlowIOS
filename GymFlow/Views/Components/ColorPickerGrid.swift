import SwiftUI

struct ColorPickerGrid: View {
    @Binding var selectedColor: String
    @AppStorage(AppLanguage.storageKey) private var languageCode = AppLanguage.spanish.rawValue

    private var colorNames: [String: String] {
        if (AppLanguage(rawValue: languageCode) ?? .spanish) == .english {
            return [
                "#4A9EFF": "Blue", "#32D74B": "Green", "#E8A135": "Amber", "#FF453A": "Red",
                "#BF5AF2": "Purple", "#FF9F0A": "Orange", "#5AC8FA": "Sky Blue", "#FF6482": "Pink"
            ]
        }
        return [
            "#4A9EFF": "Azul", "#32D74B": "Verde", "#E8A135": "Ámbar", "#FF453A": "Rojo",
            "#BF5AF2": "Púrpura", "#FF9F0A": "Naranjo", "#5AC8FA": "Celeste", "#FF6482": "Rosado"
        ]
    }

    var body: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: 4), spacing: 15) {
            ForEach(Theme.palette, id: \.self) { hex in
                let isSelected = (hex == selectedColor)
                Circle()
                    .fill(Color(hex: hex))
                    .frame(height: 38)
                    .overlay(
                        Circle()
                            .stroke(Color(hex: hex), lineWidth: isSelected ? 4 : 0)
                            .padding(-6)
                    )
                    .scaleEffect(isSelected ? 1.15 : 1.0)
                    .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isSelected)
                    .onTapGesture {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                            selectedColor = hex
                        }
                    }
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel("Color \(colorNames[hex] ?? hex)")
                    .accessibilityAddTraits(.isButton)
                    .accessibilityValue(isSelected ? "Seleccionado" : "")
            }
        }
    }
}
