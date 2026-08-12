import Foundation
import Combine

/// Estado del entrenamiento activo, compartido entre ActiveWorkoutView y el
/// App Intent de Siri (CompleteNextSetIntent).
@MainActor
final class ActiveWorkoutSession: ObservableObject {
    static let shared = ActiveWorkoutSession()

    @Published private(set) var routine: Routine?

    /// checkedSets[displayIndex][setIndex] — SIEMPRE indexado por posición de
    /// pantalla, no por posición original en la rutina.
    @Published var checkedSets: [[Bool]] = []

    /// Mapeo de posición de pantalla → índice original en routine.exercises.
    /// Ej: exerciseOrder[0] = 2 significa que el primer ejercicio en pantalla
    /// es el tercero de la rutina original.
    @Published private(set) var exerciseOrder: [Int] = []

    /// Índice de pantalla del ejercicio priorizado, o nil si no hay prioridad.
    @Published private(set) var prioritizedDisplayIndex: Int? = nil

    /// Cuando es true, cada fila de ejercicio muestra botones ↑ ↓ para reordenar.
    @Published var isReorderMode: Bool = false

    @Published private(set) var didCompleteAll = false
    @Published private(set) var wasCanceledExternally = false

    private init() {}

    // MARK: - Derived

    var progressPercent: Double {
        let all = checkedSets.flatMap { $0 }
        guard !all.isEmpty else { return 0 }
        return Double(all.filter { $0 }.count) / Double(all.count)
    }

    /// Ejercicio actualmente en pantalla en la posición dada.
    func exercise(atDisplayIndex i: Int) -> Exercise? {
        guard let routine, exerciseOrder.indices.contains(i) else { return nil }
        let routineIdx = exerciseOrder[i]
        guard routine.exercises.indices.contains(routineIdx) else { return nil }
        return routine.exercises[routineIdx]
    }

    // MARK: - Lifecycle

    func start(routine: Routine) {
        self.routine = routine
        let count = routine.exercises.count
        self.exerciseOrder = Array(0..<count)
        self.checkedSets = routine.exercises.map { Array(repeating: false, count: $0.sets) }
        self.prioritizedDisplayIndex = nil
        self.isReorderMode = false
        self.didCompleteAll = false
        self.wasCanceledExternally = false

        if let firstEx = routine.exercises.first {
            LiveActivityManager.shared.startWorkout(
                routineName: routine.name,
                firstExerciseName: firstEx.name,
                sets: firstEx.sets
            )
        }
    }

    func end() {
        routine = nil
        checkedSets = []
        exerciseOrder = []
        prioritizedDisplayIndex = nil
        isReorderMode = false
        didCompleteAll = false
    }

    @discardableResult
    func cancelActiveWorkout(external: Bool = false) -> Bool {
        guard routine != nil else { return false }
        LiveActivityManager.shared.endWorkout()
        end()
        if external { wasCanceledExternally = true }
        return true
    }

    // MARK: - Set toggling

    func toggleSet(exIndex: Int, setIndex: Int) {
        guard checkedSets.indices.contains(exIndex),
              checkedSets[exIndex].indices.contains(setIndex) else { return }
        checkedSets[exIndex][setIndex].toggle()
        afterChange(displayIndex: exIndex)
    }

    /// Marca la próxima serie pendiente. Si hay un ejercicio priorizado, lo
    /// intenta primero; si todas sus series están hechas, avanza al siguiente.
    @discardableResult
    func completeNextPendingSet() -> Bool {
        guard !checkedSets.isEmpty else { return false }

        // Orden de búsqueda: priorizado primero, luego el resto en orden de pantalla
        var searchOrder = Array(0..<checkedSets.count)
        if let pri = prioritizedDisplayIndex, searchOrder.contains(pri) {
            searchOrder.removeAll { $0 == pri }
            searchOrder.insert(pri, at: 0)
        }

        for displayIdx in searchOrder {
            if let setIndex = checkedSets[displayIdx].firstIndex(where: { !$0 }) {
                checkedSets[displayIdx][setIndex] = true
                afterChange(displayIndex: displayIdx)
                return true
            }
        }
        return false
    }

    // MARK: - Priority

    func setPriority(displayIndex: Int) {
        if prioritizedDisplayIndex == displayIndex {
            prioritizedDisplayIndex = nil   // toggle off
        } else {
            prioritizedDisplayIndex = displayIndex
        }
    }

    func clearPriority() {
        prioritizedDisplayIndex = nil
    }

    // MARK: - Reorder

    /// Mueve el ejercicio de `from` a `to` (ambos son índices de pantalla).
    /// Mantiene checkedSets sincronizado con exerciseOrder.
    func moveExercise(from: Int, to: Int) {
        guard from != to,
              exerciseOrder.indices.contains(from),
              exerciseOrder.indices.contains(to) else { return }

        exerciseOrder.move(fromOffsets: IndexSet(integer: from),
                           toOffset: to > from ? to + 1 : to)
        checkedSets.move(fromOffsets: IndexSet(integer: from),
                         toOffset: to > from ? to + 1 : to)

        // Ajusta el índice priorizado si se ve afectado por el movimiento
        if let pri = prioritizedDisplayIndex {
            if pri == from {
                prioritizedDisplayIndex = to > from ? to : to
            } else if from < to, pri > from, pri <= to {
                prioritizedDisplayIndex = pri - 1
            } else if from > to, pri >= to, pri < from {
                prioritizedDisplayIndex = pri + 1
            }
        }
    }

    // MARK: - Private

    private func afterChange(displayIndex: Int) {
        guard let routine, exerciseOrder.indices.contains(displayIndex) else { return }
        let routineIdx = exerciseOrder[displayIndex]
        guard routine.exercises.indices.contains(routineIdx) else { return }
        let ex = routine.exercises[routineIdx]
        let completed = checkedSets[displayIndex].filter { $0 }.count

        LiveActivityManager.shared.updateProgress(
            exerciseName: ex.name,
            currentSet: completed,
            totalSets: ex.sets,
            progress: progressPercent
        )

        if checkedSets.flatMap({ $0 }).allSatisfy({ $0 }) {
            didCompleteAll = true
        }
    }
}
