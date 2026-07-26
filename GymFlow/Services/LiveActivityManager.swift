import Foundation
import ActivityKit

class LiveActivityManager {
    static let shared = LiveActivityManager()
    
    private var currentActivity: Activity<WorkoutActivityAttributes>?
    
    private init() {}
    
    func startWorkout(routineName: String, firstExerciseName: String, sets: Int) {
        guard ActivityAuthorizationInfo().areActivitiesEnabled else { return }
        
        let attributes = WorkoutActivityAttributes(routineName: routineName)
        let initialState = WorkoutActivityAttributes.ContentState(
            currentExerciseName: firstExerciseName,
            currentSet: 0,
            totalSets: sets,
            progressPercent: 0.0,
            isCompleted: false
        )
        
        do {
            currentActivity = try Activity.request(
                attributes: attributes,
                content: .init(state: initialState, staleDate: nil),
                pushType: nil
            )
            print("Live activity started: \(currentActivity?.id ?? "")")
        } catch {
            print("Error starting Live Activity: \(error.localizedDescription)")
        }
    }
    
    func updateProgress(exerciseName: String, currentSet: Int, totalSets: Int, progress: Double) {
        let state = WorkoutActivityAttributes.ContentState(
            currentExerciseName: exerciseName,
            currentSet: currentSet,
            totalSets: totalSets,
            progressPercent: progress,
            isCompleted: false
        )
        
        Task {
            await currentActivity?.update(
                ActivityContent(state: state, staleDate: nil)
            )
        }
    }
    
    func endWorkout() {
        let finalState = WorkoutActivityAttributes.ContentState(
            currentExerciseName: "¡Completado!",
            currentSet: 0,
            totalSets: 0,
            progressPercent: 1.0,
            isCompleted: true
        )
        
        Task {
            await currentActivity?.end(
                ActivityContent(state: finalState, staleDate: nil),
                dismissalPolicy: .default
            )
            currentActivity = nil
        }
    }
}
