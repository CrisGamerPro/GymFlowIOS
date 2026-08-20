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

    // Cronómetro de sesión
    @State private var startTime: Date = Date()
    @State private var elapsedTime: TimeInterval = 0
    @State private var elapsedTimer: Timer? = nil

    // Registro (se crea al empezar, se borra al cancelar, se guarda al terminar)
    @State private var activeLog: WorkoutLog? = nil

    // Pantallas
    @State private var showCompleteScreen = false
    @State private var brokenRecords: [BrokenRecord] = []

    // Cuenta regresiva 3-2-1 del inicio
    @State private var showStartCountdown = true
    @State private var startCountdownValue: Int = 3
    @State private var startCountdownTimer: Timer? = nil

    // Tip de Siri
    @State private var showSiriTip = false
    @State private var siriTipVisible = true

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.background.ignoresSafeArea()

                if showCompleteScreen {
                    WorkoutCompleteView(
                        routineName: routine.name,
                        time: elapsedTime,
                        volume: session.sessionVolume,
                        setsDone: session.checkedSets.flatMap { $0 }.filter { $0 }.count,
                        records: brokenRecords,
                        onFinish: { finishWorkout() }
                    )
                } else {
                    mainWorkoutContent
                }

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
                    goToCompleteScreen()
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
                goToCompleteScreen()
            }
        }
    }

    // MARK: - Contenido principal

    @ViewBuilder
    private var mainWorkoutContent: some View {
        VStack(spacing: 0) {
            WorkoutHeaderView(
                routineName: routine.name,
                progress: session.progressPercent,
                time: elapsedTime,
                volume: session.sessionVolume,
                isReorderMode: session.isReorderMode,
                priorityName: priorityExerciseName,
                onExitReorder: { withAnimation { session.isReorderMode = false } },
                onClearPriority: { withAnimation { session.clearPriority() } }
            )
            .padding(.horizontal)
            .padding(.bottom, 10)

            if session.isResting {
                RestTimerBar(
                    remaining: session.restRemaining,
                    total: session.restTotal,
                    onSkip: { withAnimation { session.skipRest() } },
                    onAdd: { session.addRestTime(15) }
                )
                .padding(.horizontal)
                .padding(.bottom, 10)
                .transition(.move(edge: .top).combined(with: .opacity))
            }

            if !didDismissSiriTip && showSiriTip && !session.isResting {
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

                    Button(action: { goToCompleteScreen() }) {
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
        .animation(.easeInOut(duration: 0.25), value: session.isResting)
    }

    // MARK: - Arranque

    private func setupWorkout() {
        // Si ya hay una sesión de ESTA misma rutina (se volvió a entrar a la
        // vista), reengancha el log en vez de arrancar de cero y perderlo.
        if session.isActive {
            guard session.isRunning(routineId: routine.id) else { return }
            if activeLog == nil { activeLog = findOrCreateOpenLog() }
            showStartCountdown = false
            startElapsedTimer()
            showSiriTip = true
            return
        }

        // Precarga el último peso usado en cada ejercicio, para no volver a
        // teclear los mismos kilos cada sesión.
        let lastWeights = PersonalRecordService.lastUsedWeights(in: modelContext)
        session.start(routine: routine, prefillWeights: lastWeights)

        let log = WorkoutLog(
            routineId: routine.id, routineName: routine.name,
            date: Date(), startedAt: Date(), isCompleted: false
        )
        modelContext.insert(log)
        try? modelContext.save()
        activeLog = log

        showStartCountdown = true
        startCountdownValue = 3
        UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
        startCountdownTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { t in
            if startCountdownValue > 1 {
                startCountdownValue -= 1
                UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
            } else {
                t.invalidate()
                startCountdownValue = 0   // muestra "¡Listo!"
                UINotificationFeedbackGenerator().notificationOccurred(.success)
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) {
                    withAnimation(.easeOut(duration: 0.3)) { showStartCountdown = false }
                    startElapsedTimer()
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

    /// Recupera el WorkoutLog abierto de esta rutina o crea uno nuevo, para
    /// que "Finalizar" nunca pierda el registro.
    private func findOrCreateOpenLog() -> WorkoutLog {
        let routineId = routine.id
        let descriptor = FetchDescriptor<WorkoutLog>(
            predicate: #Predicate { $0.routineId == routineId && $0.completedAt == nil },
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )
        if let existing = try? modelContext.fetch(descriptor).first { return existing }

        let log = WorkoutLog(
            routineId: routine.id, routineName: routine.name,
            date: Date(), startedAt: Date(), isCompleted: false
        )
        modelContext.insert(log)
        try? modelContext.save()
        return log
    }

    // MARK: - Acciones

    @MainActor
    private func cancelWorkout() {
        // Borrar el log — cancelar no cuenta como rutina empezada.
        if let log = activeLog {
            modelContext.delete(log)
            try? modelContext.save()
        }
        session.cancelActiveWorkout()
        WidgetSnapshotService.refresh(context: modelContext)
        dismiss()
    }

    /// Persiste el detalle y pasa a la pantalla de resumen. Se guarda ANTES
    /// de mostrar el resumen para poder detectar los récords batidos.
    private func goToCompleteScreen() {
        session.skipRest()
        persistExerciseLogs()
        UINotificationFeedbackGenerator().notificationOccurred(.success)
        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
            showCompleteScreen = true
        }
    }

    private func persistExerciseLogs() {
        guard let log = activeLog else { return }

        log.completedAt = Date()
        log.isCompleted = session.checkedSets.flatMap { $0 }.allSatisfy { $0 }

        // Reemplaza los registros previos: si se vuelve a "finalizar" tras
        // reabrir la vista, no queremos ejercicios duplicados.
        for old in log.exerciseLogs { modelContext.delete(old) }
        log.exerciseLogs = []

        for displayIdx in session.exerciseOrder.indices {
            guard let ex = session.exercise(atDisplayIndex: displayIdx),
                  displayIdx < session.checkedSets.count else { continue }

            let checks = session.checkedSets[displayIdx]
            let records = checks.indices.map { j in
                SetRecord(
                    weight: session.weight(exIndex: displayIdx, setIndex: j),
                    reps: session.reps(exIndex: displayIdx, setIndex: j),
                    isCompleted: checks[j]
                )
            }
            let completed = checks.filter { $0 }.count

            let exLog = ExerciseLog(
                exerciseId: ex.id, exerciseName: ex.name,
                setsCompleted: completed, totalSets: checks.count,
                value: ex.defaultValue, isCompleted: completed == checks.count,
                setRecords: records
            )
            exLog.workoutLog = log
            log.exerciseLogs.append(exLog)
            modelContext.insert(exLog)
        }

        try? modelContext.save()

        // Los récords se calculan con el log ya guardado, excluyéndolo de la
        // comparación (lo hace PersonalRecordService por id).
        brokenRecords = PersonalRecordService.detectBrokenRecords(in: log, context: modelContext)
    }

    @MainActor
    private func finishWorkout() {
        // Recuerda el peso usado como nuevo objetivo de la rutina, así la
        // próxima vez arranca donde quedaste.
        for displayIdx in session.exerciseOrder.indices {
            guard let ex = session.exercise(atDisplayIndex: displayIdx) else { continue }
            let used = session.setWeights.indices.contains(displayIdx)
                ? session.setWeights[displayIdx].max() ?? 0 : 0
            if used > 0 { ex.defaultWeight = used }
        }
        try? modelContext.save()

        LiveActivityManager.shared.endWorkout()
        session.end()
        WidgetSnapshotService.refresh(context: modelContext)
        dismiss()
    }

    // MARK: - Ayudas

    private var hideCancelButton: Bool { showCompleteScreen || showStartCountdown }

    private var priorityExerciseName: String? {
        guard let idx = session.prioritizedDisplayIndex,
              let ex = session.exercise(atDisplayIndex: idx) else { return nil }
        return ExerciseCatalog.displayName(id: ex.id, storedName: ex.name)
    }
}

// MARK: - Lista de ejercicios
//
// Extraída de ActiveWorkoutView para que el type-checker pueda con el body.

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
                displayIndex: displayIdx,
                session: session,
                isPrioritized: isPrioritized,
                isDimmed: isDimmed,
                isFirst: displayIdx == 0,
                isLast: displayIdx == total - 1,
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

// MARK: - Cuenta regresiva de inicio

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

// MARK: - Barra de descanso

struct RestTimerBar: View {
    let remaining: Int
    let total: Int
    let onSkip: () -> Void
    let onAdd: () -> Void

    private var progress: Double {
        guard total > 0 else { return 0 }
        return Double(remaining) / Double(total)
    }

    var body: some View {
        VStack(spacing: 8) {
            HStack(spacing: 10) {
                Image(systemName: "timer")
                    .scaledFont(size: 15, weight: .semibold)
                    .foregroundColor(Theme.blue)
                    .accessibilityHidden(true)

                Text("Descanso")
                    .scaledFont(size: 13, weight: .bold)
                    .foregroundColor(Theme.text)

                Spacer()

                Text(timeLabel)
                    .font(.system(size: 20, weight: .heavy).monospacedDigit())
                    .foregroundColor(Theme.blue)
                    .contentTransition(.numericText(countsDown: true))
                    .animation(.linear(duration: 0.2), value: remaining)

                Button(action: onAdd) {
                    Text("+15s")
                        .scaledFont(size: 12, weight: .bold)
                        .foregroundColor(Theme.blue)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 5)
                        .background(Theme.blue.opacity(0.16))
                        .cornerRadius(8)
                }
                .accessibilityLabel("Agregar 15 segundos de descanso")

                Button(action: onSkip) {
                    Text("Saltar")
                        .scaledFont(size: 12, weight: .bold)
                        .foregroundColor(Theme.textSecondary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 5)
                        .background(Color.white.opacity(0.08))
                        .cornerRadius(8)
                }
                .accessibilityLabel("Saltar descanso")
            }

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color.white.opacity(0.1))
                        .frame(height: 6)
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Theme.blue)
                        .frame(width: max(0, geo.size.width * progress), height: 6)
                        .animation(.linear(duration: 0.3), value: progress)
                }
            }
            .frame(height: 6)
        }
        .padding(14)
        .background(Theme.blue.opacity(0.1))
        .cornerRadius(14)
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Theme.blue.opacity(0.25), lineWidth: 1))
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Descanso, \(timeLabel) restantes")
    }

    private var timeLabel: String {
        String(format: "%d:%02d", remaining / 60, remaining % 60)
    }
}

// MARK: - Cabecera

struct WorkoutHeaderView: View {
    let routineName: String
    let progress: Double
    let time: TimeInterval
    let volume: Double
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
                if volume > 0 {
                    Text(volumeLabel)
                        .scaledFont(size: 12, weight: .semibold)
                        .foregroundColor(Theme.green)
                        .padding(.trailing, 8)
                }
                Text(formatTime(time))
                    .font(.system(size: 18, weight: .bold).monospacedDigit())
                    .foregroundColor(Theme.amber)
            }

            if isReorderMode {
                banner(icon: "arrow.up.arrow.down.circle.fill", tint: Theme.blue,
                       text: "Modo ordenar — usa ↑↓",
                       actionTitle: "Listo", onTap: onExitReorder)
            } else if let name = priorityName {
                banner(icon: "star.fill", tint: Theme.amber,
                       text: "Priorizando: \(name)",
                       actionTitle: "Quitar", onTap: onClearPriority)
            }

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

    private func banner(icon: String, tint: Color, text: String,
                        actionTitle: LocalizedStringKey,
                        onTap: @escaping () -> Void) -> some View {
        HStack {
            Image(systemName: icon).foregroundColor(tint)
            Text(text)
                .scaledFont(size: 13, weight: .semibold)
                .foregroundColor(tint)
            Spacer()
            Button(actionTitle, action: onTap)
                .scaledFont(size: 13, weight: .bold)
                .foregroundColor(Theme.textSecondary)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(tint.opacity(0.12))
        .cornerRadius(10)
        .transition(.opacity.combined(with: .move(edge: .top)))
    }

    private var volumeLabel: String {
        let kg = volume >= 1000
            ? String(format: "%.1ft", volume / 1000)
            : String(Int(volume))
        return "\(kg) kg"
    }

    private func formatTime(_ t: TimeInterval) -> String {
        String(format: "%02d:%02d", Int(t) / 60, Int(t) % 60)
    }
}
