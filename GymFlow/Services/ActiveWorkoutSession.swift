import Foundation
import Combine

/// Estado del entrenamiento activo, compartido entre ActiveWorkoutView y el
/// App Intent de Siri (CompleteNextSetIntent). Vive en memoria mientras el
/// proceso de la app esté activo — si la app se termina por completo, el
/// intent lo detecta (routine == nil) y responde que no hay entrenamiento
/// en curso, en vez de fallar.
@MainActor
final class ActiveWorkoutSession: ObservableObject {
    static let shared = ActiveWorkoutSession()

    @Published private(set) var routine: Routine?
    @Published var checkedSets: [[Bool]] = []
    @Published private(set) var didCompleteAll = false
    /// Se pone en true cuando el entrenamiento se cancela desde afuera de
    /// ActiveWorkoutView (por ejemplo, por Siri). La vista lo observa para
    /// cerrarse a sí misma, ya que un intent no puede llamar dismiss().
    @Published private(set) var wasCanceledExternally = false

    private init() {}

    var progressPercent: Double {
        let all = checkedSets.flatMap { $0 }
        guard !all.isEmpty else { return 0 }
        return Double(all.filter { $0 }.count) / Double(all.count)
    }

    func start(routine: Routine) {
        self.routine = routine
        self.checkedSets = routine.exercises.map { Array(repeating: false, count: $0.sets) }
        self.didCompleteAll = false
        self.wasCanceledExternally = false

        if let firstEx = routine.exercises.first {
            LiveActivityManager.shared.startWorkout(routineName: routine.name, firstExerciseName: firstEx.name, sets: firstEx.sets)
        }
    }

    func end() {
        routine = nil
        checkedSets = []
        didCompleteAll = false
    }

    /// Cancela el entrenamiento en curso sin guardar progreso.
    /// `external: true` es para cuando lo dispara el intent de Siri, no un
    /// tap dentro de ActiveWorkoutView — así la vista sabe que debe
    /// cerrarse sola en vez de asumir que ya se está cerrando.
    @discardableResult
    func cancelActiveWorkout(external: Bool = false) -> Bool {
        guard routine != nil else { return false }
        LiveActivityManager.shared.endWorkout()
        end()
        if external {
            wasCanceledExternally = true
        }
        return true
    }

    func toggleSet(exIndex: Int, setIndex: Int) {
        guard checkedSets.indices.contains(exIndex), checkedSets[exIndex].indices.contains(setIndex) else { return }
        checkedSets[exIndex][setIndex].toggle()
        afterChange(exIndex: exIndex)
    }

    /// Marca la próxima serie pendiente del primer ejercicio incompleto.
    /// Es lo que usa el intent de Siri: no necesita saber en qué ejercicio
    /// ni serie exacta está el usuario, solo "avanzar una serie más".
    @discardableResult
    func completeNextPendingSet() -> Bool {
        guard let routine, !checkedSets.isEmpty else { return false }
        for exIndex in routine.exercises.indices {
            if let setIndex = checkedSets[exIndex].firstIndex(where: { !$0 }) {
                checkedSets[exIndex][setIndex] = true
                afterChange(exIndex: exIndex)
                return true
            }
        }
        return false
    }

    private func afterChange(exIndex: Int) {
        guard let routine else { return }
        let ex = routine.exercises[exIndex]
        let completed = checkedSets[exIndex].filter { $0 }.count
        LiveActivityManager.shared.updateProgress(exerciseName: ex.name, currentSet: completed, totalSets: ex.sets, progress: progressPercent)

        if checkedSets.flatMap({ $0 }).allSatisfy({ $0 }) {
            didCompleteAll = true
        }
    }
}
