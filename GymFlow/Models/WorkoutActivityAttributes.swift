import Foundation
import ActivityKit

/// Atributos de la Live Activity de GymFlow.
/// Este archivo es compilado tanto en el target principal (GymFlow)
/// como en el Widget Extension (GymFlowWidget).
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
