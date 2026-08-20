import Foundation
import SwiftData

@Model
final class Exercise {
    var id: String
    var name: String
    var icon: String
    var category: String
    var unit: String
    var sets: Int
    var defaultValue: Int
    var order: Int

    /// Peso objetivo en kg. 0 = sin carga declarada; en ese caso el
    /// entrenamiento precarga el último peso usado en este ejercicio.
    var defaultWeight: Double = 0

    /// Descanso entre series, en segundos. 0 = usar el valor global de Ajustes.
    var restSeconds: Int = 0

    var routine: Routine?

    init(id: String, name: String, icon: String, category: String, unit: String,
         sets: Int, defaultValue: Int, order: Int,
         defaultWeight: Double = 0, restSeconds: Int = 0) {
        self.id = id
        self.name = name
        self.icon = icon
        self.category = category
        self.unit = unit
        self.sets = sets
        self.defaultValue = defaultValue
        self.order = order
        self.defaultWeight = defaultWeight
        self.restSeconds = restSeconds
    }

    /// ¿Tiene sentido registrar kilos en este ejercicio?
    /// Los que se miden en tiempo (trote, plancha) no llevan carga.
    var usesWeight: Bool { unit == "reps" }
}
