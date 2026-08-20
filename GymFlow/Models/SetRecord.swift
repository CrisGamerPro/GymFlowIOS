import Foundation

/// Registro de UNA serie: lo que realmente se levantó, no lo planificado.
///
/// Es un `Codable` de valor, no un `@Model`: SwiftData lo guarda como array
/// dentro de ExerciseLog. Así evitamos un tercer nivel de relaciones
/// (WorkoutLog → ExerciseLog → SetLog) que complicaría cada consulta.
struct SetRecord: Codable, Hashable, Identifiable {
    var id: UUID
    /// Kilos. 0 = peso corporal o sin carga externa.
    var weight: Double
    /// Repeticiones hechas. En ejercicios por tiempo, guarda los segundos.
    var reps: Int
    var isCompleted: Bool

    init(id: UUID = UUID(), weight: Double = 0, reps: Int = 0, isCompleted: Bool = false) {
        self.id = id
        self.weight = weight
        self.reps = reps
        self.isCompleted = isCompleted
    }

    /// Volumen de la serie (kg × reps). Con peso corporal cuenta 0 —
    /// no inventamos un peso que el usuario no declaró.
    var volume: Double { weight * Double(reps) }

    /// 1RM estimado con la fórmula de Epley. Solo tiene sentido en rangos
    /// bajos de repeticiones; por encima de ~12 reps se vuelve optimista.
    var estimatedOneRepMax: Double {
        guard weight > 0, reps > 0 else { return 0 }
        return weight * (1 + Double(reps) / 30.0)
    }
}

extension SetRecord {
    /// Formatea el peso sin decimales inútiles: 20 en vez de 20.0, 22.5 tal cual.
    var weightLabel: String {
        if weight == 0 { return "—" }
        if weight == weight.rounded() { return String(Int(weight)) }
        return String(format: "%.1f", weight)
    }
}
