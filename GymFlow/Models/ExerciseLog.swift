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
    
    var workoutLog: WorkoutLog?
    
    init(id: UUID = UUID(), exerciseId: String, exerciseName: String, setsCompleted: Int = 0, totalSets: Int, value: Int, isCompleted: Bool = false, completedAt: Date? = nil) {
        self.id = id
        self.exerciseId = exerciseId
        self.exerciseName = exerciseName
        self.setsCompleted = setsCompleted
        self.totalSets = totalSets
        self.value = value
        self.isCompleted = isCompleted
        self.completedAt = completedAt
    }
}
