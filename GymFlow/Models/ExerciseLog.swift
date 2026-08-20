import Foundation
import SwiftData

@Model
final class ExerciseLog {
    var id: UUID
    var exerciseId: String
    var exerciseName: String
    var setsCompleted: Int
    var totalSets: Int
    var value: Int
    var isCompleted: Bool
    var completedAt: Date?

    /// Detalle serie a serie: peso y reps reales. Se agregó junto al registro
    /// de carga, así que los entrenamientos anteriores lo tienen vacío —
    /// todo el código que lo lea debe tolerar el array vacío.
    var setRecords: [SetRecord] = []

    var workoutLog: WorkoutLog?

    init(id: UUID = UUID(), exerciseId: String, exerciseName: String,
         setsCompleted: Int = 0, totalSets: Int, value: Int,
         isCompleted: Bool = false, completedAt: Date? = nil,
         setRecords: [SetRecord] = []) {
        self.id = id
        self.exerciseId = exerciseId
        self.exerciseName = exerciseName
        self.setsCompleted = setsCompleted
        self.totalSets = totalSets
        self.value = value
        self.isCompleted = isCompleted
        self.completedAt = completedAt
        self.setRecords = setRecords
    }

    // MARK: - Métricas derivadas
    //
    // Solo cuentan las series COMPLETADAS: una serie apuntada pero no hecha
    // no debería inflar el volumen ni disparar un récord.

    private var doneSets: [SetRecord] { setRecords.filter { $0.isCompleted } }

    /// Volumen total (Σ kg × reps). 0 si no se registraron pesos.
    var totalVolume: Double { doneSets.reduce(0) { $0 + $1.volume } }

    /// Peso máximo levantado en este ejercicio, en esta sesión.
    var maxWeight: Double { doneSets.map(\.weight).max() ?? 0 }

    /// Mejor 1RM estimado de la sesión.
    var bestEstimatedOneRepMax: Double { doneSets.map(\.estimatedOneRepMax).max() ?? 0 }

    /// Total de repeticiones completadas.
    var totalReps: Int { doneSets.reduce(0) { $0 + $1.reps } }

    /// ¿Este registro trae detalle de carga o viene de antes de la función?
    var hasWeightData: Bool { doneSets.contains { $0.weight > 0 } }
}
