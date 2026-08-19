import SwiftUI
import SwiftData
import UIKit
import AppIntents

struct ActiveWorkoutView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @ObservedObject private var session = ActiveWorkoutSession.shared
    @AppStorage("gymflow.didDismissSiriTip") private var didDismissSiriTip = false

    let routine: Routine

    // Elapsed timer
    @State private var startTime: Date = Date()
    @State private var elapsedTime: TimeInterval = 0
    @State private var elapsedTimer: Timer? = nil

    // Workout log (created on start, deleted on cancel, saved on finish)
    @State private var activeLog: WorkoutLog? = nil

    // Screens
    @State private var showCompleteScreen = false

    // Start countdown (3-2-1 overlay at workout begin)
    @State private var showStartCountdown = true
    @State private var startCountdownValue: Int = 3  // 3 → 2 → 1 → 0 ("¡Listo!")
    @State private var startCountdownTimer: Timer? = nil

    // Siri tip visibility (shown once per workout after countdown)
    @State private var showSiriTip = false
    @State private var siriTipVisible = true

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.background.ignoresSafeArea()

                if showCompleteScreen {
                    WorkoutCompleteView(routineName: routine.name, time: elapsedTime) {
                        finishWorkout()
                    }
                } else {
                    mainWorkoutContent
                }

                // 3-2-1 countdown overlay
                if showStartCountdown {
                    StartCountdownOverlay(value: startCountdownValue)
                        .ignoresSafeArea()
                        .transition(.opacity)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") { cancelWorkout() }
                        .foregroundColor(Theme.textSecondary)
                        .opacity(hideCancelButton ? 0 : 1)
                        .disabled(hideCancelButton)
                }
            }
            .toolbarBackground(Theme.background, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .onAppear(perform: setupWorkout)
            .onDisappear {
                elapsedTimer?.invalidate()
                startCountdownTimer?.invalidate()
            }
            .onChange(of: session.didCompleteAll) { _, done in
                guard done else { return }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                    UINotificationFeedbackGenerator().notificationOccurred(.success)
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                        showCompleteScreen = true
                    }
                }
            }
            .onChange(of: session.wasCanceledExternally) { _, canceled in
                if canceled { dismiss() }
            }
            .onChange(of: session.finishRequestedExternally) { _, requested in
                // Botón "Finalizar" de la Live Activity
                guard requested else { return }
                startCountdownTimer?.invalidate()
                showStartCountdown = false
                UINotificationFeedbackGenerator().notificationOccurred(.success)
                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                    showCompleteScreen = true
                }
            }
        }
    }

    // MARK: - Main content

    @ViewBuilder
    private var mainWorkoutContent: some View {
        VStack(spacing: 0) {
            WorkoutHeaderView(
                routineName: routine.name,
                progress: session.progressPercent,
                time: elapsedTime,
                isReorderMode: session.isReorderMode,
                priorityName: priorityExerciseName,
                onExitReorder: { withAnimation { session.isReorderMode = false } },
                onClearPriority: { withAnimation { session.clearPriority() } }
            )
            .padding(.horizontal)
            .padding(.bottom, 10)

            if !didDismissSiriTip && showSiriTip {
                // Tarjeta nativa: muestra la frase REAL que el sistema
                // registró para el intent, no una inventada.
                SiriTipView(intent: CompleteNextSetIntent(), isVisible: $siriTipVisible)
                    .padding(.horizontal)
                    .padding(.bottom, 10)
                    .transition(.opacity.combined(with: .move(edge: .top)))
                    .onChange(of: siriTipVisible) { _, visible in
                        if !visible { didDismissSiriTip = true }
                    }
            }

            ScrollView {
                VStack(spacing: 16) {
                    WorkoutExerciseList(session: session)

                    Button(action: { showCompleteScreen = true }) {
                        Text("Finalizar Entrenamiento")
                            .scaledFont(size: 16, weight: .bold)
                            .foregroundColor(Theme.red)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(Theme.red.opacity(0.15))
                            .cornerRadius(16)
                    }
                    .padding(.top, 20)
                }
                .padding()
            }
        }
    }

    // MARK: - Setup

    private func setupWorkout() {
        // Si ya hay una sesión de ESTA misma rutina (p. ej. se volvió a entrar
        // a la vista), reengancha el log en vez de arrancar de cero y perderlo.
        if session.isActive {
            guard session.isRunning(routineId: routine.id) else {
                // Hay otro entrenamiento en curso: no lo pisamos.
                return
            }
            if activeLog == nil { activeLog = findOrCreateOpenLog() }
            showStartCountdown = false
            startElapsedTimer()
            showSiriTip = true
            return
        }

        session.start(routine: routine)

        // Log creado inmediatamente al empezar (isCompleted = false)
        let log = WorkoutLog(
            routineId: routine.id,
            routineName: routine.name,
            date: Date(),
            startedAt: Date(),
            isCompleted: false
        )
        modelContext.insert(log)
        try? modelContext.save()
        activeLog = log

        // Lanzar cuenta regresiva 3-2-1
        showStartCountdown = true
        startCountdownValue = 3
        UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
        startCountdownTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { t in
            if startCountdownValue > 1 {
                startCountdownValue -= 1
                UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
            } else {
                t.invalidate()
                startCountdownValue = 0    // muestra "¡Listo!"
                UINotificationFeedbackGenerator().notificationOccurred(.success)
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) {
                    withAnimation(.easeOut(duration: 0.3)) { showStartCountdown = false }
                    startElapsedTimer()
                    // Mostrar tip de Siri un momento después
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        withAnimation { showSiriTip = true }
                    }
                }
            }
        }
    }

    private func startElapsedTimer() {
        elapsedTimer?.invalidate()
        startTime = Date()
        elapsedTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            elapsedTime = Date().timeIntervalSince(startTime)
        }
    }

    /// Recupera el WorkoutLog abierto de esta rutina (creado al iniciar) o
    /// crea uno nuevo si se perdió — así "Finalizar" nunca pierde el registro.
    private func findOrCreateOpenLog() -> WorkoutLog {
        let routineId = routine.id
        let descriptor = FetchDescriptor<WorkoutLog>(
            predicate: #Predicate { $0.routineId == routineId && $0.completedAt == nil },
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )
        if let existing = try? modelContext.fetch(descriptor).first {
            return existing
        }
        let log = WorkoutLog(
            routineId: routine.id, routineName: routine.name,
            date: Date(), startedAt: Date(), isCompleted: false
        )
        modelContext.insert(log)
        try? modelContext.save()
        return log
    }

    // MARK: - Actions

    private func cancelWorkout() {
        // Borrar el log — no cuenta como "empezada" si se cancela
        if let log = activeLog {
            modelContext.delete(log)
            try? modelContext.save()
        }
        session.cancelActiveWorkout()
        dismiss()
    }

    private func finishWorkout() {
        let allSetsChecked = session.checkedSets.flatMap { $0 }.allSatisfy { $0 }

        if let log = activeLog {
            log.completedAt = Date()
            log.isCompleted = allSetsChecked

            for displayIdx in session.exerciseOrder.indices {
                guard let ex = session.exercise(atDisplayIndex: displayIdx),
                      displayIdx < session.checkedSets.count else { continue }
                let sets = session.checkedSets[displayIdx]
                let completed = sets.filter { $0 }.count
                let exLog = ExerciseLog(
                    exerciseId: ex.id, exerciseName: ex.name,
                    setsCompleted: completed, totalSets: sets.count,
                    value: ex.defaultValue, isCompleted: completed == sets.count
                )
                exLog.workoutLog = log
                log.exerciseLogs.append(exLog)
            }
            try? modelContext.save()
        }

        LiveActivityManager.shared.endWorkout()
        session.end()
        dismiss()
    }

    // MARK: - Helpers

    private var hideCancelButton: Bool {
        showCompleteScreen || showStartCountdown
    }

    private var priorityExerciseName: String? {
        guard let idx = session.prioritizedDisplayIndex else { return nil }
        guard let ex = session.exercise(atDisplayIndex: idx) else { return nil }
        return ExerciseCatalog.displayName(id: ex.id, storedName: ex.name)
    }
}

// MARK: - Exercise list (extracted to keep ActiveWorkoutView's body type-checkable)

struct WorkoutExerciseList: View {
    @ObservedObject var session: ActiveWorkoutSession

    var body: some View {
        let count = session.exerciseOrder.count
        let isValid = count > 0 && session.checkedSets.count == count

        Group {
            if isValid {
                ForEach(session.exerciseOrder.indices, id: \.self) { displayIdx in
                    exerciseRow(displayIdx: displayIdx, total: count)
                }
            }
        }
    }

    @ViewBuilder
    private func exerciseRow(displayIdx: Int, total: Int) -> some View {
        if let exercise = session.exercise(atDisplayIndex: displayIdx) {
            let isPrioritized: Bool = session.prioritizedDisplayIndex == displayIdx
            let isDimmed: Bool = session.prioritizedDisplayIndex != nil && !isPrioritized

            ExerciseCheckRow(
                exercise: exercise,
                checkedSets: $session.checkedSets[displayIdx],
                isPrioritized: isPrioritized,
                isDimmed: isDimmed,
                isReorderMode: session.isReorderMode,
                isFirst: displayIdx == 0,
                isLast: displayIdx == total - 1,
                onToggleSet: { setIndex in
                    session.toggleSet(exIndex: displayIdx, setIndex: setIndex)
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                },
                onMoveUp: { session.moveExercise(from: displayIdx, to: max(0, displayIdx - 1)) },
                onMoveDown: { session.moveExercise(from: displayIdx, to: min(total - 1, displayIdx + 1)) }
            )
            .contextMenu {
                Button(action: { togglePriority(displayIdx) }) {
                    Label(
                        isPrioritized ? "Quitar prioridad" : "Priorizar",
                        systemImage: isPrioritized ? "star.slash.fill" : "star.fill"
                    )
                }
                Button(action: toggleReorderMode) {
                    Label(
                        session.isReorderMode ? "Terminar de ordenar" : "Ordenar ejercicios",
                        systemImage: "arrow.up.arrow.down"
                    )
                }
            }
        }
    }

    private func togglePriority(_ displayIdx: Int) {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
            session.setPriority(displayIndex: displayIdx)
        }
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
    }

    private func toggleReorderMode() {
        withAnimation(.easeInOut(duration: 0.25)) {
            session.isReorderMode.toggle()
            session.clearPriority()
        }
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
    }
}

// MARK: - Countdown overlay

struct StartCountdownOverlay: View {
    let value: Int

    var body: some View {
        ZStack {
            Color.black.opacity(0.85)

            VStack(spacing: 20) {
                if value > 0 {
                    Text("\(value)")
                        .font(.system(size: 130, weight: .black, design: .rounded))
                        .foregroundColor(Theme.amber)
                        .id("cd-\(value)")
                        .transition(.asymmetric(
                            insertion: .scale(scale: 1.5).combined(with: .opacity),
                            removal: .scale(scale: 0.5).combined(with: .opacity)
                        ))
                        .animation(.spring(response: 0.35, dampingFraction: 0.6), value: value)

                    Text("Preparándose...")
                        .scaledFont(size: 20, weight: .medium)
                        .foregroundColor(Theme.textSecondary)
                } else {
                    Text("¡Listo!")
                        .font(.system(size: 64, weight: .black, design: .rounded))
                        .foregroundColor(Theme.green)
                        .transition(.scale(scale: 1.2).combined(with: .opacity))
                        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: value)
                }
            }
        }
    }
}

// MARK: - Workout header

struct WorkoutHeaderView: View {
    let routineName: String
    let progress: Double
    let time: TimeInterval
    let isReorderMode: Bool
    let priorityName: String?
    let onExitReorder: () -> Void
    let onClearPriority: () -> Void

    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Text(routineName)
                    .scaledFont(size: 20, weight: .bold)
                    .foregroundColor(Theme.text)
                Spacer()
                Text(formatTime(time))
                    .font(.system(size: 18, weight: .bold).monospacedDigit())
                    .foregroundColor(Theme.amber)
            }

            if isReorderMode {
                HStack {
                    Image(systemName: "arrow.up.arrow.down.circle.fill")
                        .foregroundColor(Theme.blue)
                    Text("Modo ordenar — arrastra o usa ↑↓")
                        .scaledFont(size: 13, weight: .semibold)
                        .foregroundColor(Theme.blue)
                    Spacer()
                    Button("Listo", action: onExitReorder)
                        .scaledFont(size: 13, weight: .bold)
                        .foregroundColor(Theme.amber)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Theme.blue.opacity(0.12))
                .cornerRadius(10)
                .transition(.opacity.combined(with: .move(edge: .top)))
            } else if let name = priorityName {
                HStack {
                    Image(systemName: "star.fill").foregroundColor(Theme.amber)
                    Text("Priorizando: \(name)")
                        .scaledFont(size: 13, weight: .semibold)
                        .foregroundColor(Theme.amber)
                    Spacer()
                    Button("Quitar", action: onClearPriority)
                        .scaledFont(size: 13, weight: .bold)
                        .foregroundColor(Theme.textSecondary)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Theme.amber.opacity(0.12))
                .cornerRadius(10)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }

            // Barra de progreso
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color(hex: "#2C2C2E"))
                        .frame(height: 12)
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Theme.amber)
                        .frame(width: max(0, geo.size.width * CGFloat(progress)), height: 12)
                        .animation(.spring(), value: progress)
                }
            }
            .frame(height: 12)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("Progreso")
            .accessibilityValue("\(Int(progress * 100))%")
        }
        .padding(16)
        .glassCard()
        .animation(.easeInOut(duration: 0.25), value: isReorderMode)
        .animation(.easeInOut(duration: 0.25), value: priorityName)
    }

    private func formatTime(_ t: TimeInterval) -> String {
        let m = Int(t) / 60
        let s = Int(t) % 60
        return String(format: "%02d:%02d", m, s)
    }
}

// MARK: - Exercise check row (with priority, reorder, time-based timer)

struct ExerciseCheckRow: View {
    let exercise: Exercise
    @Binding var checkedSets: [Bool]
    let isPrioritized: Bool
    let isDimmed: Bool
    let isReorderMode: Bool
    let isFirst: Bool
    let isLast: Bool
    let onToggleSet: (Int) -> Void
    let onMoveUp: () -> Void
    let onMoveDown: () -> Void

    // Per-set timer state (only used for time-based exercises)
    @State private var activeTimerSetIndex: Int? = nil
    @State private var timerPhase: TimerPhase = .idle
    @State private var countdownValue: Int = 3
    @State private var remainingSeconds: Int = 0
    @State private var timerRef: Timer? = nil
    @State private var showInfo = false

    enum TimerPhase { case idle, countdown, running, done }

    private var isTimeBased: Bool { ExerciseCatalog.isTimeBased(unit: exercise.unit) }
    private var durationSeconds: Int {
        exercise.unit == "min" ? exercise.defaultValue * 60 : exercise.defaultValue
    }

    private var allDone: Bool { checkedSets.allSatisfy { $0 } }

    private var pattern: MovementPattern {
        ExerciseAnimationCatalog.pattern(forId: exercise.id, category: exercise.category)
    }

    private var displayName: String {
        ExerciseCatalog.displayName(id: exercise.id, storedName: exercise.name)
    }

    /// La animación se pausa cuando el ejercicio ya está completo o cuando la
    /// fila está atenuada por prioridad — no tiene sentido gastar frames ahí.
    private var animationPlaying: Bool {
        !allDone && !isDimmed && !isReorderMode
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Button(action: { showInfo = true }) {
                    ExerciseAnimationTile(
                        pattern: pattern,
                        size: 44,
                        tint: allDone ? Theme.green : Theme.amber,
                        isPlaying: animationPlaying
                    )
                }
                .buttonStyle(PlainButtonStyle())
                .accessibilityLabel("Cómo se hace \(displayName)")

                VStack(alignment: .leading, spacing: 2) {
                    Text(displayName)
                        .scaledFont(size: 16, weight: .bold)
                        .foregroundColor(Theme.text)
                    Text("\(exercise.defaultValue) \(ExerciseCatalog.displayUnit(exercise.unit))")
                        .scaledFont(size: 13)
                        .foregroundColor(Theme.textSecondary)
                }

                Spacer()

                if isReorderMode {
                    // Up / Down buttons when reorder mode is active
                    HStack(spacing: 4) {
                        Button(action: { UIImpactFeedbackGenerator(style: .light).impactOccurred(); onMoveUp() }) {
                            Image(systemName: "chevron.up.circle.fill")
                                .scaledFont(size: 26)
                                .foregroundColor(isFirst ? Theme.textSecondary.opacity(0.3) : Theme.blue)
                        }
                        .disabled(isFirst)

                        Button(action: { UIImpactFeedbackGenerator(style: .light).impactOccurred(); onMoveDown() }) {
                            Image(systemName: "chevron.down.circle.fill")
                                .scaledFont(size: 26)
                                .foregroundColor(isLast ? Theme.textSecondary.opacity(0.3) : Theme.blue)
                        }
                        .disabled(isLast)
                    }
                } else {
                    let completed = checkedSets.filter { $0 }.count
                    // Usa checkedSets.count, no exercise.sets: si la rutina se
                    // edita durante el entrenamiento, exercise.sets cambia pero
                    // checkedSets conserva el tamaño con el que se inició.
                    Text("\(completed)/\(checkedSets.count)")
                        .scaledFont(size: 14, weight: .bold)
                        .foregroundColor(completed == checkedSets.count ? Theme.green : Theme.textSecondary)
                        .contentTransition(.numericText())
                        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: completed)
                }
            }
            .accessibilityElement(children: .combine)

            // Set buttons
            HStack(spacing: 12) {
                ForEach(checkedSets.indices, id: \.self) { i in
                    setButton(index: i)
                }
            }
        }
        .padding(16)
        .glassCard()
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(isPrioritized ? Theme.amber : Color.clear, lineWidth: 2)
        )
        .opacity(isDimmed ? 0.3 : 1.0)
        .grayscale(isDimmed ? 0.6 : 0.0)
        .animation(.easeInOut(duration: 0.25), value: isDimmed)
        .animation(.easeInOut(duration: 0.25), value: isPrioritized)
        .onDisappear { timerRef?.invalidate() }
        .sheet(isPresented: $showInfo) {
            ExerciseInfoSheet(exercise: exercise)
        }
    }

    @ViewBuilder
    private func setButton(index: Int) -> some View {
        let isChecked = checkedSets[index]
        let isActiveTimer = activeTimerSetIndex == index

        Button(action: { handleSetTap(index: index) }) {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(buttonBg(isChecked: isChecked, isActive: isActiveTimer))
                    .frame(height: 48)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(buttonBorder(isChecked: isChecked, isActive: isActiveTimer), lineWidth: 1)
                    )

                if isChecked {
                    Image(systemName: "checkmark")
                        .scaledFont(size: 18, weight: .bold)
                        .foregroundColor(.white)
                        .transition(.scale.combined(with: .opacity))
                } else if isActiveTimer {
                    timerLabel
                } else {
                    Text("\(index + 1)")
                        .scaledFont(size: 16, weight: .bold)
                        .foregroundColor(Theme.textSecondary)
                }
            }
        }
        .buttonStyle(PlainButtonStyle())
        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isChecked)
        .animation(.easeInOut(duration: 0.15), value: timerPhase == .running)
        .accessibilityLabel("Serie \(index + 1) de \(ExerciseCatalog.displayName(id: exercise.id, storedName: exercise.name))")
        .accessibilityValue(isChecked ? "Completada" : "Pendiente")
        .accessibilityAddTraits(.isButton)
    }

    @ViewBuilder
    private var timerLabel: some View {
        switch timerPhase {
        case .countdown:
            Text("\(countdownValue)")
                .scaledFont(size: 20, weight: .black)
                .foregroundColor(Theme.amber)
        case .running:
            Text(formatSeconds(remainingSeconds))
                .font(.system(size: 16, weight: .bold).monospacedDigit())
                .foregroundColor(Theme.amber)
        case .done:
            Image(systemName: "checkmark.circle.fill")
                .scaledFont(size: 22)
                .foregroundColor(Theme.green)
        default:
            EmptyView()
        }
    }

    private func buttonBg(isChecked: Bool, isActive: Bool) -> Color {
        if isChecked { return Theme.green }
        if isActive { return Theme.amber.opacity(0.18) }
        return Color(hex: "#2C2C2E")
    }

    private func buttonBorder(isChecked: Bool, isActive: Bool) -> Color {
        if isChecked { return Theme.green }
        if isActive { return Theme.amber.opacity(0.6) }
        return Color(hex: "#3A3A3C")
    }

    // MARK: - Timer logic

    private func handleSetTap(index: Int) {
        if checkedSets[index] {
            // Already checked — uncheck
            onToggleSet(index)
            if activeTimerSetIndex == index { cancelTimer() }
            return
        }

        if !isTimeBased {
            onToggleSet(index)
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            return
        }

        // Time-based: start 3-2-1 then timer
        if activeTimerSetIndex == index {
            // Tap again to cancel current timer
            cancelTimer()
            return
        }
        cancelTimer()
        startTimerForSet(index: index)
    }

    private func startTimerForSet(index: Int) {
        activeTimerSetIndex = index
        timerPhase = .countdown
        countdownValue = 3
        UIImpactFeedbackGenerator(style: .rigid).impactOccurred()

        timerRef = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { t in
            if timerPhase == .countdown {
                if countdownValue > 1 {
                    countdownValue -= 1
                    UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
                } else {
                    // Start actual timer
                    timerPhase = .running
                    remainingSeconds = durationSeconds
                    UINotificationFeedbackGenerator().notificationOccurred(.success)
                }
            } else if timerPhase == .running {
                if remainingSeconds > 1 {
                    remainingSeconds -= 1
                } else {
                    // Timer complete — mark set
                    t.invalidate()
                    timerPhase = .done
                    UINotificationFeedbackGenerator().notificationOccurred(.success)
                    UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        onToggleSet(index)
                        cancelTimer()
                    }
                }
            }
        }
    }

    private func cancelTimer() {
        timerRef?.invalidate()
        timerRef = nil
        activeTimerSetIndex = nil
        timerPhase = .idle
    }

    private func formatSeconds(_ s: Int) -> String {
        String(format: "%d:%02d", s / 60, s % 60)
    }
}

// MARK: - Workout complete screen

struct WorkoutCompleteView: View {
    let routineName: String
    let time: TimeInterval
    let onFinish: () -> Void

    @State private var showContent = false

    var body: some View {
        VStack(spacing: 24) {
            Text("🎉")
                .scaledFont(size: 80)
                .scaleEffect(showContent ? 1.0 : 0.5)
                .opacity(showContent ? 1.0 : 0)

            VStack(spacing: 8) {
                Text("¡Entrenamiento Completado!")
                    .scaledFont(size: 24, weight: .heavy)
                    .foregroundColor(Theme.text)
                Text(routineName)
                    .scaledFont(size: 18, weight: .bold)
                    .foregroundColor(Theme.amber)
            }
            .offset(y: showContent ? 0 : 20)
            .opacity(showContent ? 1.0 : 0)

            HStack(spacing: 40) {
                VStack {
                    Text("Tiempo")
                        .scaledFont(size: 14)
                        .foregroundColor(Theme.textSecondary)
                    Text(formatTime(time))
                        .font(.system(size: 28, weight: .bold).monospacedDigit())
                        .foregroundColor(Theme.text)
                }
            }
            .padding(.vertical, 20)
            .offset(y: showContent ? 0 : 20)
            .opacity(showContent ? 1.0 : 0)

            Button(action: onFinish) {
                Text("Terminar")
                    .scaledFont(size: 18, weight: .bold)
                    .foregroundColor(.black)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Theme.amber)
                    .cornerRadius(16)
            }
            .padding(.horizontal, 40)
            .padding(.top, 20)
            .offset(y: showContent ? 0 : 20)
            .opacity(showContent ? 1.0 : 0)
        }
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.1)) {
                showContent = true
            }
        }
    }

    private func formatTime(_ t: TimeInterval) -> String {
        let m = Int(t) / 60
        let s = Int(t) % 60
        return String(format: "%02d:%02d", m, s)
    }
}
