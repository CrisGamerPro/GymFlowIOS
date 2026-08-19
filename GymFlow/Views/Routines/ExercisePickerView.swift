import SwiftUI

struct ExercisePickerView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var selectedExercises: [Exercise]
    
    @State private var searchText = ""
    @State private var selectedCategory = "Todos"
    @State private var infoExercise: CatalogExercise?
    
    let categories = ExerciseCatalog.categories

    var filteredExercises: [CatalogExercise] {
        let all = ExerciseCatalog.all
        let filteredByCategory = selectedCategory == "Todos" ? all : all.filter { $0.category == selectedCategory }
        if searchText.isEmpty {
            return filteredByCategory
        } else {
            return filteredByCategory.filter { ex in
                ex.name.localizedCaseInsensitiveContains(searchText) ||
                ExerciseCatalog.displayName(id: ex.id, storedName: ex.name).localizedCaseInsensitiveContains(searchText) ||
                ex.category.localizedCaseInsensitiveContains(searchText)
            }
        }
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Theme.background.ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Custom search bar
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(Theme.textSecondary)
                            .accessibilityHidden(true)
                        TextField("Buscar ejercicio...", text: $searchText)
                            .foregroundColor(Theme.text)
                    }
                    .padding(10)
                    .background(Color(hex: "#2C2C2E"))
                    .cornerRadius(10)
                    .padding(.horizontal)
                    .padding(.vertical, 10)
                    
                    // Categories
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(categories, id: \.self) { cat in
                                let isSelected = cat == selectedCategory
                                Text(ExerciseCatalog.displayCategory(cat))
                                    .scaledFont(size: 13, weight: .semibold)
                                    .foregroundColor(isSelected ? Theme.amber : Theme.textSecondary)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 8)
                                    .background(isSelected ? Theme.amber.opacity(0.15) : Color(hex: "#2C2C2E"))
                                    .cornerRadius(20)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 20)
                                            .stroke(isSelected ? Theme.amber.opacity(0.3) : Color(hex: "#3A3A3C"), lineWidth: 1)
                                    )
                                    .onTapGesture {
                                        withAnimation(.easeInOut(duration: 0.15)) {
                                            selectedCategory = cat
                                        }
                                    }
                                    .accessibilityAddTraits(.isButton)
                                    .accessibilityValue(isSelected ? "Seleccionado" : "")
                            }
                        }
                        .padding(.horizontal)
                    }
                    .padding(.bottom, 10)
                    
                    // Grid
                    ScrollView {
                        LazyVStack(spacing: 8) {
                            ForEach(filteredExercises) { catEx in
                                ExercisePickerRow(
                                    catalogExercise: catEx,
                                    isPicked: selectedExercises.contains { $0.id == catEx.id },
                                    onToggle: {
                                        withAnimation(.easeInOut(duration: 0.15)) {
                                            toggleSelection(for: catEx)
                                        }
                                    },
                                    onInfo: { infoExercise = catEx }
                                )
                                .padding(.horizontal)
                            }
                        }
                        .padding(.vertical)
                    }
                }
            }
            .navigationTitle("Elegir Ejercicio")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Listo") { dismiss() }
                        .foregroundColor(Theme.amber)
                }
            }
            .toolbarBackground(Theme.background, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .sheet(item: $infoExercise) { catEx in
                ExerciseInfoSheet(catalog: catEx)
            }
        }
    }
    
    private func toggleSelection(for catEx: CatalogExercise) {
        if let index = selectedExercises.firstIndex(where: { $0.id == catEx.id }) {
            selectedExercises.remove(at: index)
        } else {
            let newEx = Exercise(
                id: catEx.id,
                name: catEx.name,
                icon: catEx.icon,
                category: catEx.category,
                unit: catEx.unit,
                sets: catEx.defaultSets,
                defaultValue: catEx.defaultValue,
                order: selectedExercises.count
            )
            selectedExercises.append(newEx)
        }
    }
}

// MARK: - Fila del selector

struct ExercisePickerRow: View {
    let catalogExercise: CatalogExercise
    let isPicked: Bool
    let onToggle: () -> Void
    let onInfo: () -> Void

    private var pattern: MovementPattern {
        ExerciseAnimationCatalog.pattern(
            forId: catalogExercise.id,
            category: catalogExercise.category
        )
    }

    private var displayName: String {
        ExerciseCatalog.displayName(id: catalogExercise.id, storedName: catalogExercise.name)
    }

    private var displayCategory: String {
        ExerciseCatalog.displayCategory(catalogExercise.category)
    }

    var body: some View {
        HStack(spacing: 12) {
            // La animación reemplaza al emoji: se ve el movimiento antes de elegir.
            ExerciseAnimationTile(
                pattern: pattern,
                size: 44,
                tint: isPicked ? Theme.green : Theme.amber
            )

            VStack(alignment: .leading, spacing: 2) {
                Text(displayName)
                    .scaledFont(size: 15, weight: .bold)
                    .foregroundColor(Theme.text)
                Text(displayCategory)
                    .scaledFont(size: 12)
                    .foregroundColor(Theme.textSecondary)
            }

            Spacer()

            if isPicked {
                Image(systemName: "checkmark")
                    .scaledFont(size: 18, weight: .bold)
                    .foregroundColor(Theme.green)
                    .accessibilityHidden(true)
            }

            Button(action: onInfo) {
                Image(systemName: "info.circle")
                    .scaledFont(size: 20)
                    .foregroundColor(Theme.blue)
                    .padding(.leading, 4)
            }
            .buttonStyle(PlainButtonStyle())
            .accessibilityLabel("Cómo se hace \(displayName)")
        }
        .padding(12)
        .background(isPicked ? Theme.green.opacity(0.1) : Color(hex: "#1C1C1E"))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(isPicked ? Theme.green.opacity(0.3) : Color(hex: "#3A3A3C"), lineWidth: 1)
        )
        .animation(.easeInOut(duration: 0.15), value: isPicked)
        .contentShape(Rectangle())
        .onTapGesture(perform: onToggle)
        .accessibilityElement(children: .contain)
        .accessibilityLabel("\(displayName), \(displayCategory)")
        .accessibilityAddTraits(.isButton)
        .accessibilityValue(isPicked ? "Seleccionado" : "")
    }
}
