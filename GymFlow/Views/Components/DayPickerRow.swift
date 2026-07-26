import SwiftUI

struct DayPickerRow: View {
    @Binding var selectedDays: Set<Int>
    @AppStorage(AppLanguage.storageKey) private var languageCode = AppLanguage.spanish.rawValue

    private var language: AppLanguage { AppLanguage(rawValue: languageCode) ?? .spanish }
    var days: [String] { language.dayLetters }
    var fullDayNames: [String] { language.dayFullNames }

    var body: some View {
        HStack(spacing: 6) {
            ForEach(0..<7, id: \.self) { i in
                let isSelected = selectedDays.contains(i)

                Text(days[i])
                    .scaledFont(size: 15, weight: .bold)
                    .foregroundColor(isSelected ? Theme.amber : Theme.textSecondary)
                    .frame(maxWidth: .infinity, minHeight: 44)
                    .aspectRatio(1, contentMode: .fit)
                    .background(isSelected ? Theme.amber.opacity(0.15) : Color(hex: "#2C2C2E"))
                    .clipShape(Circle())
                    .overlay(
                        Circle()
                            .stroke(isSelected ? Theme.amber.opacity(0.3) : Color(hex: "#3A3A3C"), lineWidth: 1)
                    )
                    .scaleEffect(isSelected ? 1.08 : 1.0)
                    .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isSelected)
                    .onTapGesture {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                            if isSelected {
                                selectedDays.remove(i)
                            } else {
                                selectedDays.insert(i)
                            }
                        }
                    }
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel(fullDayNames[i])
                    .accessibilityAddTraits(.isButton)
                    .accessibilityValue(isSelected ? "Seleccionado" : "No seleccionado")
            }
        }
    }
}
