import Foundation
import SwiftData

@Model
final class WorkoutLog {
    var id: UUID
    var routineId: UUID
    var routineName: String
    var date: Date
    var startedAt: Date?
    var completedAt: Date?
    
    @Relationship(deleteRule: .cascade, inverse: \ExerciseLog.workoutLog)
    var exerciseLogs: [ExerciseLog]
    
    var isCompleted: Bool
    
    init(id: UUID = UUID(), routineId: UUID, routineName: String, date: Date = Date(), startedAt: Date? = nil, completedAt: Date? = nil, exerciseLogs: [ExerciseLog] = [], isCompleted: Bool = false) {
        self.id = id
        self.routineId = routineId
        self.routineName = routineName
        self.date = date
        self.startedAt = startedAt
        self.completedAt = completedAt
        self.exerciseLogs = exerciseLogs
        self.isCompleted = isCompleted
    }
}
