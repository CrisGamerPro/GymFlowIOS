import Foundation
import Combine

/// Estado del entrenamiento activo, compartido entre ActiveWorkoutView, el
/// App Intent de Siri y los botones de la Live Activity.
@MainActor
final class ActiveWorkoutSession: ObservableObject {
    static let shared = ActiveWorkoutSession()

    @Published private(set) var routine: Routine?

    /// Snapshot de los ejercicios EN ORDEN, tomado al iniciar. Se guarda aquí
    /// en vez de leer `routine.exercises` cada vez porque esa relación de
    /// SwiftData no garantiza orden y puede cambiar si se edita la rutina.
    @Published private(set) var exercises: [Exercise] = []

    /// checkedSets[displayIndex][setIndex] — SIEMPRE indexado por posición de
    /// pantalla, no por posición original en la rutina.
    @Published var checkedSets: [[Bool]] = []

    /// Mapeo de posición de pantalla → índice en `exercises`.
    @Published private(set) var exerciseOrder: [Int] = []

    /// Índice de pantalla del ejercicio priorizado, o nil si no hay prioridad.
    @Published private(set) var prioritizedDisplayIndex: Int? = nil

    /// Cuando es true, cada fila muestra botones ↑ ↓ para reordenar.
    @Published var isReorderMode: Bool = false

    @Published private(set) var didCompleteAll = false
    @Published private(set) var wasCanceledExternally = false

    /// Se pone en true cuando se pide finalizar desde la Live Activity.
    /// ActiveWorkoutView lo observa para guardar el log y cerrarse.
    @Published private(set) var finishRequestedExternally = false

    private init() {
        // Botones de la Live Activity (los intents corren en este proceso).
        NotificationCenter.default.addObserver(
            forName: .gymflowMarkSetRequested, object: nil, queue: .main
        ) { _ in
            Task { @MainActor in
                ActiveWorkoutSession.shared.completeNextPendingSet()
            }
        }
        NotificationCenter.default.addObserver(
            forName: .gymflowFinishWorkoutRequested, object: nil, queue: .main
        ) { _ in
            Task { @MainActor in
                ActiveWorkoutSession.shared.requestFinishFromLiveActivity()
            }
        }
    }

    // MARK: - Derived

    var isActive: Bool { routine != nil }

    var progressPercent: Double {
        let all = checkedSets.flatMap { $0 }
        guard !all.isEmpty else { return 0 }
        return Double(all.filter { $0 }.count) / Double(all.count)
    }

    func exercise(atDisplayIndex i: Int) -> Exercise? {
        guard exerciseOrder.indices.contains(i) else { return nil }
        let idx = exerciseOrder[i]
        guard exercises.indices.contains(idx) else { return nil }
        return exercises[idx]
    }

    /// ¿Este entrenamiento activo pertenece a esta rutina?
    func isRunning(routineId: UUID) -> Bool {
        routine?.id == routineId
    }

    // MARK: - Lifecycle

    func start(routine: Routine) {
        let ordered = routine.orderedExercises

        self.routine = routine
        self.exercises = ordered
        self.exerciseOrder = Array(ordered.indices)
        self.checkedSets = ordered.map { Array(repeating: false, count: max(1, $0.sets)) }
        self.prioritizedDisplayIndex = nil
        self.isReorderMode = false
        self.didCompleteAll = false
        self.wasCanceledExternally = false
        self.finishRequestedExternally = false

        if let firstEx = ordered.first {
            LiveActivityManager.shared.startWorkout(
                routineName: routine.name,
                firstExerciseName: firstEx.name,
                sets: firstEx.sets
            )
        }
    }

    func end() {
        routine = nil
        exercises = []
        checkedSets = []
        exerciseOrder = []
        prioritizedDisplayIndex = nil
        isReorderMode = false
        didCompleteAll = false
        finishRequestedExternally = false
    }

    @discardableResult
    func cancelActiveWorkout(external: Bool = false) -> Bool {
        guard routine != nil else { return false }
        LiveActivityManager.shared.endWorkout()
        end()
        if external { wasCanceledExternally = true }
        return true
    }

    /// Pedido de "Finalizar" desde la Live Activity. No guarda nada aquí —
    /// solo levanta la bandera; ActiveWorkoutView es quien tiene el
    /// ModelContext y persiste el WorkoutLog.
    func requestFinishFromLiveActivity() {
        guard routine != nil else { return }
        finishRequestedExternally = true
    }

    // MARK: - Set toggling

    func toggleSet(exIndex: Int, setIndex: Int) {
        guard checkedSets.indices.contains(exIndex),
              checkedSets[exIndex].indices.contains(setIndex) else { return }
        checkedSets[exIndex][setIndex].toggle()
        afterChange(displayIndex: exIndex)
    }

    /// Marca la próxima serie pendiente. Si hay un ejercicio priorizado, lo
    /// intenta primero; si ya está completo, avanza al siguiente.
    @discardableResult
    func completeNextPendingSet() -> Bool {
        guard !checkedSets.isEmpty else { return false }

        var searchOrder = Array(checkedSets.indices)
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
        prioritizedDisplayIndex = (prioritizedDisplayIndex == displayIndex) ? nil : displayIndex
    }

    func clearPriority() {
        prioritizedDisplayIndex = nil
    }

    // MARK: - Reorder

    /// Mueve el ejercicio de `from` a `to` (índices de pantalla).
    /// Mantiene checkedSets sincronizado con exerciseOrder.
    func moveExercise(from: Int, to: Int) {
        guard from != to,
              exerciseOrder.indices.contains(from),
              exerciseOrder.indices.contains(to),
              checkedSets.indices.contains(from),
              checkedSets.indices.contains(to) else { return }

        let orderElem = exerciseOrder.remove(at: from)
        exerciseOrder.insert(orderElem, at: to)

        let setsElem = checkedSets.remove(at: from)
        checkedSets.insert(setsElem, at: to)

        if let pri = prioritizedDisplayIndex {
            if pri == from {
                prioritizedDisplayIndex = to
            } else if from < to, pri > from, pri <= to {
                prioritizedDisplayIndex = pri - 1
            } else if from > to, pri >= to, pri < from {
                prioritizedDisplayIndex = pri + 1
            }
        }
    }

    // MARK: - Private

    private func afterChange(displayIndex: Int) {
        guard let ex = exercise(atDisplayIndex: displayIndex),
              checkedSets.indices.contains(displayIndex) else { return }

        let completed = checkedSets[displayIndex].filter { $0 }.count

        LiveActivityManager.shared.updateProgress(
            exerciseName: ex.name,
            currentSet: completed,
            totalSets: checkedSets[displayIndex].count,
            progress: progressPercent
        )

        if checkedSets.flatMap({ $0 }).allSatisfy({ $0 }) {
            didCompleteAll = true
        }
    }
}
