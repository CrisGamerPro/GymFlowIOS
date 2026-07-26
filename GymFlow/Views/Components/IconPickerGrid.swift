import SwiftUI

struct IconPickerGrid: View {
    @Binding var selectedIcon: String
    
    var body: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 6), spacing: 12) {
            ForEach(Array(Theme.icons.enumerated()), id: \.offset) { index, icon in
                let isSelected = (icon == selectedIcon)

                Text(icon)
                    .scaledFont(size: 24)
                    .frame(width: 44, height: 44)
                    .background(isSelected ? Theme.amber.opacity(0.15) : Color(hex: "#2C2C2E"))
                    .cornerRadius(10)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(isSelected ? Theme.amber : Color.clear, lineWidth: 2)
                    )
                    .scaleEffect(isSelected ? 1.1 : 1.0)
                    .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isSelected)
                    .onTapGesture {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                            selectedIcon = icon
                        }
                    }
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel("Ícono opción \(index + 1)")
                    .accessibilityAddTraits(.isButton)
                    .accessibilityValue(isSelected ? "Seleccionado" : "")
            }
        }
    }
}
