import SwiftUI

/// Ficha de un ejercicio: animación grande del patrón de movimiento y claves
/// de técnica. Se abre desde la (i) del selector y desde la fila del
/// entrenamiento activo.
struct ExerciseInfoSheet: View {
    let exerciseId: String
    let storedName: String
    let icon: String
    let category: String
    let unit: String
    let sets: Int
    let value: Int

    @Environment(\.dismiss) private var dismiss

    private var pattern: MovementPattern {
        ExerciseAnimationCatalog.pattern(forId: exerciseId, category: category)
    }

    private var displayName: String {
        ExerciseCatalog.displayName(id: exerciseId, storedName: storedName)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.background.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {
                        animationCard
                        metaRow
                        historyLink
                        cuesCard
                    }
                    .padding()
                }
            }
            .navigationTitle(displayName)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Listo") { dismiss() }
                        .foregroundColor(Theme.amber)
                        .fontWeight(.bold)
                }
            }
            .toolbarBackground(Theme.cardBackground, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
    }

    // MARK: - Secciones

    private var animationCard: some View {
        VStack(spacing: 10) {
            ExerciseAnimationView(pattern: pattern, tint: Theme.amber, strokeRatio: 0.042)
                .frame(height: 230)
                .frame(maxWidth: .infinity)

            Text(pattern.displayName)
                .scaledFont(size: 12, weight: .semibold)
                .foregroundColor(Theme.textSecondary)
                .textCase(.uppercase)
        }
        .padding(.vertical, 18)
        .frame(maxWidth: .infinity)
        .glassCard()
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Animación: \(pattern.displayName)")
    }

    private var metaRow: some View {
        HStack(spacing: 10) {
            InfoPill(icon: icon,
                     label: ExerciseCatalog.displayCategory(category),
                     tint: Theme.blue)
            InfoPill(icon: "🔁",
                     label: "\(sets) \(setsWord)",
                     tint: Theme.green)
            InfoPill(icon: "📊",
                     label: "\(value) \(ExerciseCatalog.displayUnit(unit))",
                     tint: Theme.amber)
        }
    }

    private var historyLink: some View {
        NavigationLink(destination: ExerciseHistoryView(exerciseId: exerciseId, storedName: storedName)) {
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 9)
                        .fill(Theme.green.opacity(0.15))
                        .frame(width: 34, height: 34)
                    Image(systemName: "chart.line.uptrend.xyaxis")
                        .scaledFont(size: 15, weight: .semibold)
                        .foregroundColor(Theme.green)
                }

                VStack(alignment: .leading, spacing: 1) {
                    Text(historyTitle)
                        .scaledFont(size: 15, weight: .bold)
                        .foregroundColor(Theme.text)
                    Text(historySubtitle)
                        .scaledFont(size: 12)
                        .foregroundColor(Theme.textSecondary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .scaledFont(size: 13, weight: .semibold)
                    .foregroundColor(Theme.textSecondary)
                    .accessibilityHidden(true)
            }
            .padding(14)
            .glassCard()
        }
        .buttonStyle(PlainButtonStyle())
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isButton)
    }

    private var historyTitle: String {
        AppLanguage.current == .english ? "Progress & records" : "Progresión y récords"
    }

    private var historySubtitle: String {
        AppLanguage.current == .english
            ? "Your history for this exercise"
            : "Tu historial en este ejercicio"
    }

    private var cuesCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Label(techniqueTitle, systemImage: "checklist")
                .scaledFont(size: 15, weight: .bold)
                .foregroundColor(Theme.text)

            VStack(alignment: .leading, spacing: 10) {
                ForEach(Array(pattern.cues.enumerated()), id: \.offset) { index, cue in
                    CueRow(number: index + 1, text: cue)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .glassCard()
    }

    private var setsWord: String {
        AppLanguage.current == .english ? "sets" : "series"
    }

    private var techniqueTitle: String {
        AppLanguage.current == .english ? "Technique" : "Técnica"
    }
}

// MARK: - Piezas

private struct InfoPill: View {
    let icon: String
    let label: String
    let tint: Color

    var body: some View {
        VStack(spacing: 4) {
            Text(icon).scaledFont(size: 18)
            Text(label)
                .scaledFont(size: 12, weight: .semibold)
                .foregroundColor(tint)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(tint.opacity(0.12))
        .cornerRadius(12)
        .accessibilityElement(children: .combine)
    }
}

private struct CueRow: View {
    let number: Int
    let text: String

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            ZStack {
                Circle()
                    .fill(Theme.amber.opacity(0.18))
                    .frame(width: 22, height: 22)
                Text("\(number)")
                    .scaledFont(size: 11, weight: .bold)
                    .foregroundColor(Theme.amber)
            }
            Text(text)
                .scaledFont(size: 14)
                .foregroundColor(Theme.text)
                .fixedSize(horizontal: false, vertical: true)
        }
        .accessibilityElement(children: .combine)
    }
}

// MARK: - Conveniencias

extension ExerciseInfoSheet {
    /// Ficha desde un ejercicio guardado en una rutina.
    init(exercise: Exercise) {
        self.init(
            exerciseId: exercise.id, storedName: exercise.name, icon: exercise.icon,
            category: exercise.category, unit: exercise.unit,
            sets: exercise.sets, value: exercise.defaultValue
        )
    }

    /// Ficha desde una entrada del catálogo (selector de ejercicios).
    init(catalog: CatalogExercise) {
        self.init(
            exerciseId: catalog.id, storedName: catalog.name, icon: catalog.icon,
            category: catalog.category, unit: catalog.unit,
            sets: catalog.defaultSets, value: catalog.defaultValue
        )
    }
}
