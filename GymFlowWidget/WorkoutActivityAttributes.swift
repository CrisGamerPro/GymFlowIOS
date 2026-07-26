import Foundation
import ActivityKit

/// Atributos de la Live Activity de GymFlow.
/// Copia idéntica de GymFlow/Models/WorkoutActivityAttributes.swift.
/// Con grupos sincronizados de Xcode cada carpeta pertenece a un solo target,
/// así que este tipo se declara en ambos targets (app y widget extension)
/// para que GymFlowWidgetLiveActivity.swift pueda compilar.
struct WorkoutActivityAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        // Estado dinámico (cambia durante el entrenamiento)
        var currentExerciseName: String
        var currentSet: Int
        var totalSets: Int
        var progressPercent: Double  // 0.0 a 1.0
        var isCompleted: Bool
    }

    // Datos estáticos (no cambian durante el entrenamiento)
    var routineName: String
}
