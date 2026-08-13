import AppIntents
import Foundation

/// Copia idéntica de GymFlow/Services/LiveActivityIntents.swift.
/// Con grupos sincronizados de Xcode cada carpeta pertenece a un solo target,
/// así que estos tipos se declaran en ambos targets (app y widget extension)
/// para que GymFlowWidgetLiveActivity.swift pueda construir los botones.
///
/// El archivo no depende de nada de la app a propósito: solo publica
/// notificaciones. Los LiveActivityIntent SIEMPRE se ejecutan en el proceso de
/// la app principal (no en el del widget), y allí ActiveWorkoutSession es
/// quien está suscrito y hace el trabajo real.

extension Notification.Name {
    static let gymflowMarkSetRequested = Notification.Name("cl.subject.gymflow.liveactivity.markSet")
    static let gymflowFinishWorkoutRequested = Notification.Name("cl.subject.gymflow.liveactivity.finishWorkout")
}

// MARK: - Marcar serie desde la Live Activity

@available(iOS 17.0, *)
struct MarkSetLiveActivityIntent: LiveActivityIntent {
    static var title: LocalizedStringResource = "Marcar serie"
    static var description = IntentDescription("Marca la próxima serie pendiente sin abrir la app.")
    static var openAppWhenRun: Bool = false

    init() {}

    func perform() async throws -> some IntentResult {
        await MainActor.run {
            NotificationCenter.default.post(name: .gymflowMarkSetRequested, object: nil)
        }
        return .result()
    }
}

// MARK: - Finalizar entrenamiento desde la Live Activity

@available(iOS 17.0, *)
struct FinishWorkoutLiveActivityIntent: LiveActivityIntent {
    static var title: LocalizedStringResource = "Finalizar entrenamiento"
    static var description = IntentDescription("Termina el entrenamiento actual y guarda el progreso.")
    static var openAppWhenRun: Bool = false

    init() {}

    func perform() async throws -> some IntentResult {
        await MainActor.run {
            NotificationCenter.default.post(name: .gymflowFinishWorkoutRequested, object: nil)
        }
        return .result()
    }
}
