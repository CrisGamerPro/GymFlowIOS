import Foundation
import SwiftData

@Model
final class Routine {
    var id: UUID
    var name: String
    var desc: String
    var colorHex: String
    var icon: String
    var days: [Int] // 0=Mon, 1=Tue, 2=Wed...
    var time: Date?
    
    @Relationship(deleteRule: .cascade, inverse: \Exercise.routine)
    var exercises: [Exercise]
    
    var createdAt: Date
    var updatedAt: Date

    /// SwiftData NO garantiza el orden del array de una relación. Siempre usa
    /// esta propiedad cuando el orden importe (entrenamiento, listados, export).
    var orderedExercises: [Exercise] {
        exercises.sorted { $0.order < $1.order }
    }

    init(id: UUID = UUID(), name: String, desc: String = "", colorHex: String = "#E8A135", icon: String = "🏋️", days: [Int] = [], time: Date? = nil, exercises: [Exercise] = []) {
        self.id = id
        self.name = name
        self.desc = desc
        self.colorHex = colorHex
        self.icon = icon
        self.days = days
        self.time = time
        self.exercises = exercises
        self.createdAt = Date()
        self.updatedAt = Date()
    }
}
