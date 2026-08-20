import Foundation
import Combine

/// Estado del entrenamiento activo, compartido entre ActiveWorkoutView, el
/// App Intent de Siri y los botones de la Live Activity.
@MainActor
final class ActiveWorkoutSession: ObservableObject {
    static let shared = ActiveWorkoutSession()

    /// Descanso por defecto cuando el ejercicio no define uno propio.
    /// `nonisolated` porque lo leen @AppStorage y vistas fuera del actor —
    /// UserDefaults es seguro entre hilos, no hace falta aislarlo.
    nonisolated static let defaultRestKey = "gymflow.defaultRestSeconds"

    nonisolated static var globalDefaultRest: Int {
        let stored = UserDefaults.standard.integer(forKey: defaultRestKey)
        return stored > 0 ? stored : 90
    }

    @Published private(set) var routine: Routine?

    /// Snapshot de los ejercicios EN ORDEN, tomado al iniciar. Se guarda aquí
    /// en vez de leer `routine.exercises` cada vez porque esa relación de
    /// SwiftData no garantiza orden y puede cambiar si se edita la rutina.
    @Published private(set) var exercises: [Exercise] = []

    /// Todos los arrays siguientes están indexados por POSICIÓN DE PANTALLA,
    /// no por posición original en la rutina, y se reordenan juntos.
    @Published var checkedSets: [[Bool]] = []
    @Published var setWeights: [[Double]] = []
    @Published var setReps: [[Int]] = []

    /// Mapeo posición de pantalla → índice en `exercises`.
    @Published private(set) var exerciseOrder: [Int] = []

    @Published private(set) var prioritizedDisplayIndex: Int? = nil
    @Published var isReorderMode: Bool = false

    @Published private(set) var didCompleteAll = false
    @Published private(set) var wasCanceledExternally = false
    @Published private(set) var finishRequestedExternally = false

    // MARK: Descanso entre series

    @Published private(set) var restRemaining: Int = 0
    @Published private(set) var restTotal: Int = 0
    private var restTimer: Timer?

    var isResting: Bool { restRemaining > 0 }

    private init() {
        NotificationCenter.default.addObserver(
            forName: .gymflowMarkSetRequested, object: nil, queue: .main
        ) { _ in
            Task { @MainActor in ActiveWorkoutSession.shared.completeNextPendingSet() }
        }
        NotificationCenter.default.addObserver(
            forName: .gymflowFinishWorkoutRequested, object: nil, queue: .main
        ) { _ in
            Task { @MainActor in ActiveWorkoutSession.shared.requestFinishFromLiveActivity() }
        }
    }

    // MARK: - Derivados

    var isActive: Bool { routine != nil }

    var progressPercent: Double {
        let all = checkedSets.flatMap { $0 }
        guard !all.isEmpty else { return 0 }
        return Double(all.filter { $0 }.count) / Double(all.count)
    }

    /// Volumen acumulado en la sesión (Σ kg × reps de las series marcadas).
    var sessionVolume: Double {
        var total: Double = 0
        for i in checkedSets.indices {
            for j in checkedSets[i].indices where checkedSets[i][j] {
                total += weight(exIndex: i, setIndex: j) * Double(reps(exIndex: i, setIndex: j))
            }
        }
        return total
    }

    func exercise(atDisplayIndex i: Int) -> Exercise? {
        guard exerciseOrder.indices.contains(i) else { return nil }
        let idx = exerciseOrder[i]
        guard exercises.indices.contains(idx) else { return nil }
        return exercises[idx]
    }

    func isRunning(routineId: UUID) -> Bool { routine?.id == routineId }

    func weight(exIndex: Int, setIndex: Int) -> Double {
        guard setWeights.indices.contains(exIndex),
              setWeights[exIndex].indices.contains(setIndex) else { return 0 }
        return setWeights[exIndex][setIndex]
    }

    func reps(exIndex: Int, setIndex: Int) -> Int {
        guard setReps.indices.contains(exIndex),
              setReps[exIndex].indices.contains(setIndex) else { return 0 }
        return setReps[exIndex][setIndex]
    }

    // MARK: - Ciclo de vida

    /// `prefillWeights` viene de PersonalRecordService: último peso usado por
    /// id de ejercicio. Si la rutina no declara peso, se precarga ese.
    func start(routine: Routine, prefillWeights: [String: Double] = [:]) {
        let ordered = routine.orderedExercises

        self.routine = routine
        self.exercises = ordered
        self.exerciseOrder = Array(ordered.indices)
        self.checkedSets = ordered.map { Array(repeating: false, count: max(1, $0.sets)) }
        self.setWeights = ordered.map { ex in
            let w = ex.defaultWeight > 0 ? ex.defaultWeight : (prefillWeights[ex.id] ?? 0)
            return Array(repeating: ex.usesWeight ? w : 0, count: max(1, ex.sets))
        }
        self.setReps = ordered.map { ex in
            Array(repeating: ex.defaultValue, count: max(1, ex.sets))
        }
        self.prioritizedDisplayIndex = nil
        self.isReorderMode = false
        self.didCompleteAll = false
        self.wasCanceledExternally = false
        self.finishRequestedExternally = false
        cancelRest()

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
        setWeights = []
        setReps = []
        exerciseOrder = []
        prioritizedDisplayIndex = nil
        isReorderMode = false
        didCompleteAll = false
        finishRequestedExternally = false
        cancelRest()
    }

    @discardableResult
    func cancelActiveWorkout(external: Bool = false) -> Bool {
        guard routine != nil else { return false }
        LiveActivityManager.shared.endWorkout()
        end()
        if external { wasCanceledExternally = true }
        return true
    }

    func requestFinishFromLiveActivity() {
        guard routine != nil else { return }
        finishRequestedExternally = true
    }

    // MARK: - Edición de series

    func setWeight(_ value: Double, exIndex: Int, setIndex: Int) {
        guard setWeights.indices.contains(exIndex),
              setWeights[exIndex].indices.contains(setIndex) else { return }
        setWeights[exIndex][setIndex] = max(0, value)
    }

    func setRepCount(_ value: Int, exIndex: Int, setIndex: Int) {
        guard setReps.indices.contains(exIndex),
              setReps[exIndex].indices.contains(setIndex) else { return }
        setReps[exIndex][setIndex] = max(0, value)
    }

    /// Aplica un peso a TODAS las series pendientes del ejercicio. Es lo que
    /// se espera al ajustar la carga a mitad de un ejercicio.
    func applyWeightToRemaining(_ value: Double, exIndex: Int, fromSet: Int) {
        guard setWeights.indices.contains(exIndex) else { return }
        for j in setWeights[exIndex].indices where j >= fromSet && !checkedSets[exIndex][j] {
            setWeights[exIndex][j] = max(0, value)
        }
    }

    func toggleSet(exIndex: Int, setIndex: Int) {
        guard checkedSets.indices.contains(exIndex),
              checkedSets[exIndex].indices.contains(setIndex) else { return }
        let willComplete = !checkedSets[exIndex][setIndex]
        checkedSets[exIndex][setIndex].toggle()
        afterChange(displayIndex: exIndex, didComplete: willComplete)
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
                afterChange(displayIndex: displayIdx, didComplete: true)
                return true
            }
        }
        return false
    }

    // MARK: - Prioridad

    func setPriority(displayIndex: Int) {
        prioritizedDisplayIndex = (prioritizedDisplayIndex == displayIndex) ? nil : displayIndex
    }

    func clearPriority() { prioritizedDisplayIndex = nil }

    // MARK: - Reordenar

    /// Mueve el ejercicio de `from` a `to` (índices de pantalla), manteniendo
    /// series, pesos y reps sincronizados.
    func moveExercise(from: Int, to: Int) {
        guard from != to,
              exerciseOrder.indices.contains(from), exerciseOrder.indices.contains(to),
              checkedSets.indices.contains(from), checkedSets.indices.contains(to),
              setWeights.indices.contains(from), setReps.indices.contains(from) else { return }

        let orderElem = exerciseOrder.remove(at: from)
        exerciseOrder.insert(orderElem, at: to)

        let setsElem = checkedSets.remove(at: from)
        checkedSets.insert(setsElem, at: to)

        let weightsElem = setWeights.remove(at: from)
        setWeights.insert(weightsElem, at: to)

        let repsElem = setReps.remove(at: from)
        setReps.insert(repsElem, at: to)

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

    // MARK: - Descanso

    func startRest(seconds: Int) {
        guard seconds > 0 else { return }
        restTimer?.invalidate()
        restTotal = seconds
        restRemaining = seconds
        restTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] t in
            Task { @MainActor in
                guard let self else { t.invalidate(); return }
                if self.restRemaining > 1 {
                    self.restRemaining -= 1
                } else {
                    t.invalidate()
                    self.restTimer = nil
                    self.restRemaining = 0
                    NotificationService.shared.notifyRestFinished()
                }
            }
        }
    }

    func skipRest() { cancelRest() }

    func addRestTime(_ seconds: Int) {
        guard isResting else { return }
        restRemaining += seconds
        restTotal = max(restTotal, restRemaining)
    }

    private func cancelRest() {
        restTimer?.invalidate()
        restTimer = nil
        restRemaining = 0
        restTotal = 0
    }

    /// Segundos de descanso que corresponden a un ejercicio.
    func restSeconds(forDisplayIndex i: Int) -> Int {
        guard let ex = exercise(atDisplayIndex: i) else { return Self.globalDefaultRest }
        return ex.restSeconds > 0 ? ex.restSeconds : Self.globalDefaultRest
    }

    // MARK: - Privado

    private func afterChange(displayIndex: Int, didComplete: Bool) {
        guard let ex = exercise(atDisplayIndex: displayIndex),
              checkedSets.indices.contains(displayIndex) else { return }

        let completed = checkedSets[displayIndex].filter { $0 }.count
        let allDone = checkedSets.flatMap({ $0 }).allSatisfy({ $0 })

        LiveActivityManager.shared.updateProgress(
            exerciseName: ex.name,
            currentSet: completed,
            totalSets: checkedSets[displayIndex].count,
            progress: progressPercent
        )

        if allDone {
            didCompleteAll = true
            cancelRest()   // no tiene sentido descansar si ya terminaste
        } else if didComplete {
            startRest(seconds: restSeconds(forDisplayIndex: displayIndex))
        }
    }
}
