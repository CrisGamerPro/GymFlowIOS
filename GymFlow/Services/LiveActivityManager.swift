import Foundation
import ActivityKit

final class LiveActivityManager {
    static let shared = LiveActivityManager()

    private var currentActivity: Activity<WorkoutActivityAttributes>?

    private init() {}

    func startWorkout(routineName: String, firstExerciseName: String, sets: Int) {
        guard ActivityAuthorizationInfo().areActivitiesEnabled else { return }

        // Limpia cualquier Live Activity huérfana (p. ej. si la app se cerró
        // de golpe en un entrenamiento anterior). Sin esto se acumulan.
        endAllOrphanActivities()

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
        } catch {
            print("Error starting Live Activity: \(error.localizedDescription)")
        }
    }

    func updateProgress(exerciseName: String, currentSet: Int, totalSets: Int, progress: Double) {
        guard let activity = currentActivity else { return }

        let state = WorkoutActivityAttributes.ContentState(
            currentExerciseName: exerciseName,
            currentSet: currentSet,
            totalSets: totalSets,
            progressPercent: progress,
            isCompleted: false
        )

        Task {
            await activity.update(ActivityContent(state: state, staleDate: nil))
        }
    }

    func endWorkout() {
        guard let activity = currentActivity else {
            endAllOrphanActivities()
            return
        }
        currentActivity = nil

        let finalState = WorkoutActivityAttributes.ContentState(
            currentExerciseName: "¡Completado!",
            currentSet: 0,
            totalSets: 0,
            progressPercent: 1.0,
            isCompleted: true
        )

        Task {
            await activity.end(
                ActivityContent(state: finalState, staleDate: nil),
                dismissalPolicy: .default
            )
        }
    }

    /// Termina de inmediato cualquier Live Activity de GymFlow que haya
    /// quedado viva de una sesión anterior del proceso.
    private func endAllOrphanActivities() {
        let orphans = Activity<WorkoutActivityAttributes>.activities
        guard !orphans.isEmpty else { return }
        Task {
            for activity in orphans {
                await activity.end(nil, dismissalPolicy: .immediate)
            }
        }
    }
}
