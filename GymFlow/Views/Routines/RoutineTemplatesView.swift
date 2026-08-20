import SwiftUI
import SwiftData

/// Selector de rutinas prehechas. Al elegir una se crea de verdad y queda
/// editable como cualquier otra — no es una plantilla "atada".
struct RoutineTemplatesView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @State private var previewTemplate: RoutineTemplate?
    @State private var createdName: String?
    @State private var showCreatedAlert = false

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.background.ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 22) {
                        intro

                        ForEach(RoutineTemplate.Level.allCases, id: \.rawValue) { level in
                            levelSection(level)
                        }
                    }
                    .padding()
                    .padding(.bottom, 20)
                }
            }
            .navigationTitle("Rutinas Listas")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cerrar") { dismiss() }.foregroundColor(Theme.amber)
                }
            }
            .toolbarBackground(Theme.cardBackground, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .sheet(item: $previewTemplate) { template in
                TemplatePreviewSheet(template: template) {
                    create(template)
                }
            }
            .alert("Rutina creada", isPresented: $showCreatedAlert) {
                Button("Listo", role: .cancel) { dismiss() }
            } message: {
                Text("«\(createdName ?? "")» ya está en tus rutinas. Puedes editar días, horario y pesos cuando quieras.")
            }
        }
    }

    private var intro: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Empieza con una base")
                .scaledFont(size: 20, weight: .heavy)
                .foregroundColor(Theme.text)
            Text("Elige una rutina hecha y ajústala a tu gusto. Los pesos son solo una sugerencia.")
                .scaledFont(size: 14)
                .foregroundColor(Theme.textSecondary)
        }
        .accessibilityElement(children: .combine)
    }

    private func levelSection(_ level: RoutineTemplate.Level) -> some View {
        let templates = RoutineTemplates.templates(level: level)

        return VStack(alignment: .leading, spacing: 10) {
            Text(level.label)
                .scaledFont(size: 13, weight: .semibold)
                .foregroundColor(Theme.textSecondary)
                .textCase(.uppercase)

            ForEach(templates) { template in
                Button(action: { previewTemplate = template }) {
                    TemplateCard(template: template)
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
    }

    @MainActor
    private func create(_ template: RoutineTemplate) {
        let routine = RoutineTemplates.createRoutine(from: template, in: modelContext)
        WidgetSnapshotService.refresh(context: modelContext)
        createdName = routine.name
        previewTemplate = nil
        showCreatedAlert = true
    }
}

// MARK: - Tarjeta de plantilla

private struct TemplateCard: View {
    let template: RoutineTemplate

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 11)
                    .fill(Color(hex: template.colorHex).opacity(0.2))
                    .frame(width: 46, height: 46)
                Text(template.icon).scaledFont(size: 23)
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(template.name)
                    .scaledFont(size: 16, weight: .bold)
                    .foregroundColor(Theme.text)
                Text(template.desc)
                    .scaledFont(size: 12)
                    .foregroundColor(Theme.textSecondary)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
                Text("\(template.items.count) ejercicios · \(template.days.count) días")
                    .scaledFont(size: 11, weight: .semibold)
                    .foregroundColor(Color(hex: template.colorHex))
            }

            Spacer(minLength: 4)

            Image(systemName: "chevron.right")
                .scaledFont(size: 13, weight: .semibold)
                .foregroundColor(Theme.textSecondary)
                .accessibilityHidden(true)
        }
        .padding(14)
        .glassCard()
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isButton)
    }
}

// MARK: - Vista previa antes de crear

private struct TemplatePreviewSheet: View {
    let template: RoutineTemplate
    let onCreate: () -> Void

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.background.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 18) {
                        headerCard
                        exerciseList
                        createButton
                    }
                    .padding()
                }
            }
            .navigationTitle(template.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cerrar") { dismiss() }.foregroundColor(Theme.amber)
                }
            }
            .toolbarBackground(Theme.cardBackground, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
    }

    private var headerCard: some View {
        VStack(spacing: 10) {
            Text(template.icon).scaledFont(size: 44)
            Text(template.desc)
                .scaledFont(size: 14)
                .foregroundColor(Theme.textSecondary)
                .multilineTextAlignment(.center)

            HStack(spacing: 5) {
                let letters = AppLanguage.current.dayLetters
                ForEach(0..<7, id: \.self) { i in
                    let isOn = template.days.contains(i)
                    Text(letters[i])
                        .scaledFont(size: 11, weight: .bold)
                        .foregroundColor(isOn ? Theme.amber : Theme.textSecondary.opacity(0.5))
                        .frame(width: 28, height: 28)
                        .background(isOn ? Theme.amber.opacity(0.15) : Color.white.opacity(0.05))
                        .cornerRadius(14)
                }
            }
            .padding(.top, 4)
        }
        .frame(maxWidth: .infinity)
        .padding(18)
        .glassCard()
    }

    private var exerciseList: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Ejercicios")
                .scaledFont(size: 13, weight: .semibold)
                .foregroundColor(Theme.textSecondary)
                .textCase(.uppercase)

            ForEach(Array(template.items.enumerated()), id: \.offset) { _, item in
                TemplateItemRow(item: item)
            }
        }
    }

    private var createButton: some View {
        Button(action: onCreate) {
            Text("Crear esta rutina")
                .scaledFont(size: 17, weight: .bold)
                .foregroundColor(.black)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(Theme.amber)
                .cornerRadius(16)
        }
        .padding(.top, 8)
        .padding(.bottom, 24)
    }
}

private struct TemplateItemRow: View {
    let item: RoutineTemplate.Item

    private var catalogExercise: CatalogExercise? {
        ExerciseCatalog.all.first { $0.id == item.exerciseId }
    }

    var body: some View {
        if let ex = catalogExercise {
            HStack(spacing: 12) {
                ExerciseAnimationTile(
                    pattern: ExerciseAnimationCatalog.pattern(forId: ex.id, category: ex.category),
                    size: 38
                )

                VStack(alignment: .leading, spacing: 2) {
                    Text(ExerciseCatalog.displayName(id: ex.id, storedName: ex.name))
                        .scaledFont(size: 15, weight: .bold)
                        .foregroundColor(Theme.text)
                    Text(detailLabel(ex))
                        .scaledFont(size: 12)
                        .foregroundColor(Theme.textSecondary)
                }

                Spacer()
            }
            .padding(12)
            .background(Color(hex: "#1C1C1E"))
            .cornerRadius(12)
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color(hex: "#3A3A3C"), lineWidth: 1))
            .accessibilityElement(children: .combine)
        }
    }

    private func detailLabel(_ ex: CatalogExercise) -> String {
        let setsWord = AppLanguage.current == .english ? "sets" : "series"
        let base = "\(item.sets) \(setsWord) × \(item.value) \(ExerciseCatalog.displayUnit(ex.unit))"
        guard item.weight > 0 else { return base }
        let w = item.weight == item.weight.rounded()
            ? String(Int(item.weight)) : String(format: "%.1f", item.weight)
        return "\(base) · \(w) kg"
    }
}
