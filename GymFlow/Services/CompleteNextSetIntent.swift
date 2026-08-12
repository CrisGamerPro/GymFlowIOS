import AppIntents

/// Permite marcar la próxima serie pendiente del entrenamiento activo por voz.
/// Frases más cortas (sin el nombre de la app) funcionan en iOS 17+ sin ambigüedad.
/// Para iOS 16, Siri puede pedir confirmación con qué app.
struct CompleteNextSetIntent: AppIntent {
    static var title: LocalizedStringResource = "Marcar serie completada"
    static var description = IntentDescription(
        "Marca como completada la próxima serie pendiente del entrenamiento activo en GymFlow."
    )
    static var openAppWhenRun: Bool = false

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        let didComplete = ActiveWorkoutSession.shared.completeNextPendingSet()
        let english = AppLanguage.current == .english

        if didComplete {
            // Si hay ejercicio priorizado, mencionarlo en la respuesta
            if let idx = ActiveWorkoutSession.shared.prioritizedDisplayIndex,
               let ex = ActiveWorkoutSession.shared.exercise(atDisplayIndex: idx) {
                let name = ExerciseCatalog.displayName(id: ex.id, storedName: ex.name, language: AppLanguage.current)
                return .result(dialog: english
                    ? "Set marked for \(name)."
                    : "Serie marcada en \(name).")
            }
            return .result(dialog: english ? "Set marked as completed." : "Serie marcada como completada.")
        } else {
            return .result(dialog: english
                ? "There's no active workout in GymFlow."
                : "No hay un entrenamiento activo en GymFlow.")
        }
    }
}

/// Cancela el entrenamiento activo por voz.
struct CancelWorkoutIntent: AppIntent {
    static var title: LocalizedStringResource = "Cancelar entrenamiento"
    static var description = IntentDescription(
        "Cancela el entrenamiento activo en GymFlow sin guardar el progreso."
    )
    static var openAppWhenRun: Bool = false

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        let didCancel = ActiveWorkoutSession.shared.cancelActiveWorkout(external: true)
        let english = AppLanguage.current == .english
        if didCancel {
            return .result(dialog: english ? "Workout canceled." : "Entrenamiento cancelado.")
        } else {
            return .result(dialog: english
                ? "There's no active workout in GymFlow."
                : "No hay un entrenamiento activo en GymFlow.")
        }
    }
}

// MARK: - App Shortcuts

struct GymFlowShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: CompleteNextSetIntent(),
            phrases: [
                // Con nombre de app (máxima compatibilidad)
                "Marca serie en \(.applicationName)",
                "Marca la serie en \(.applicationName)",
                "Siguiente serie en \(.applicationName)",
                "Completar serie en \(.applicationName)",
                "Anota serie en \(.applicationName)",
                "Suma serie en \(.applicationName)",
                "Serie completada en \(.applicationName)",
                "\(.applicationName), marca serie",
                "\(.applicationName), siguiente serie",

                // Sin nombre de app (iOS 17+; en iOS 16 Siri puede pedir confirmación)
                "Marca serie",
                "Marcar serie",
                "Serie hecha",
                "Serie completada",
                "Siguiente serie",
                "Anotar serie",
            ],
            shortTitle: "Marcar serie",
            systemImageName: "checkmark.circle.fill"
        )
        AppShortcut(
            intent: CancelWorkoutIntent(),
            phrases: [
                "Cancela la rutina en \(.applicationName)",
                "Cancela el entrenamiento en \(.applicationName)",
                "Detén el entrenamiento en \(.applicationName)",
                "\(.applicationName), cancela la rutina",
                "\(.applicationName), cancela el entrenamiento",

                // Sin nombre de app
                "Cancela la rutina",
                "Cancela el entrenamiento",
            ],
            shortTitle: "Cancelar entrenamiento",
            systemImageName: "xmark.circle.fill"
        )
    }
}
