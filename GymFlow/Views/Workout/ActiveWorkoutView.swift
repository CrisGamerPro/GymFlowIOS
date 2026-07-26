import SwiftUI
import SwiftData
import UIKit

struct ActiveWorkoutView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @ObservedObject private var session = ActiveWorkoutSession.shared
    @AppStorage("gymflow.didDismissSiriTip") private var didDismissSiriTip = false

    let routine: Routine

    @State private var startTime: Date = Date()
    @State private var elapsedTime: TimeInterval = 0
    @State private var timer: Timer? = nil

    @State private var showCompleteScreen = false

    var progressPercent: Double { session.progressPercent }

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.background.ignoresSafeArea()
                
                if showCompleteScreen {
                    WorkoutCompleteView(routineName: routine.name, time: elapsedTime) {
                        finishWorkout()
                    }
                } else {
                    VStack(spacing: 0) {
                        // Header con barra de progreso y timer
                        WorkoutHeader(routineName: routine.name, progress: progressPercent, time: elapsedTime)
                            .padding(.horizontal)
                            .padding(.bottom, 10)

                        if !didDismissSiriTip {
                            SiriHintBanner {
                                withAnimation { didDismissSiriTip = true }
                            }
                            .padding(.horizontal)
                            .padding(.bottom, 10)
                            .transition(.opacity.combined(with: .move(edge: .top)))
                        }

                        // Lista de ejercicios
                        ScrollView {
                            VStack(spacing: 16) {
                                if session.checkedSets.count == routine.exercises.count {
                                    ForEach(Array(routine.exercises.enumerated()), id: \.element.id) { index, exercise in
                                        ExerciseCheckRow(
                                            exercise: exercise,
                                            checkedSets: $session.checkedSets[index],
                                            onToggleSet: { setIndex in
                                                handleSetToggle(exIndex: index, setIndex: setIndex)
                                            }
                                        )
                                    }
                                }
                                
                                Button(action: finishWorkoutEarly) {
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
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    if !showCompleteScreen {
                        Button("Cancelar") {
                            // Debería preguntar confirmación, simplificado por ahora
                            session.cancelActiveWorkout()
                            dismiss()
                        }
                        .foregroundColor(Theme.textSecondary)
                    }
                }
            }
            .toolbarBackground(Theme.background, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .onAppear(perform: setupWorkout)
            .onDisappear {
                timer?.invalidate()
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
        }
    }

    private func setupWorkout() {
        guard session.routine == nil else { return }

        session.start(routine: routine)
        startTime = Date()
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            elapsedTime = Date().timeIntervalSince(startTime)
        }
    }

    private func handleSetToggle(exIndex: Int, setIndex: Int) {
        session.toggleSet(exIndex: exIndex, setIndex: setIndex)
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }

    private func finishWorkoutEarly() {
        showCompleteScreen = true
    }

    private func finishWorkout() {
        // Guardar progreso en SwiftData
        let workoutLog = WorkoutLog(routineId: routine.id, routineName: routine.name, date: Date(), startedAt: startTime, completedAt: Date(), isCompleted: true)

        for (i, ex) in routine.exercises.enumerated() {
            let completed = session.checkedSets[i].filter { $0 }.count
            let exLog = ExerciseLog(exerciseId: ex.id, exerciseName: ex.name, setsCompleted: completed, totalSets: ex.sets, value: ex.defaultValue, isCompleted: completed == ex.sets)
            exLog.workoutLog = workoutLog
            workoutLog.exerciseLogs.append(exLog)
        }

        modelContext.insert(workoutLog)
        try? modelContext.save()

        LiveActivityManager.shared.endWorkout()
        session.end()

        dismiss()
    }
}

struct WorkoutHeader: View {
    let routineName: String
    let progress: Double
    let time: TimeInterval
    
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
            .accessibilityLabel("Progreso del entrenamiento")
            .accessibilityValue("\(Int(progress * 100)) por ciento")
        }
        .padding(16)
        .glassCard()
        .accessibilityElement(children: .combine)
    }
    
    private func formatTime(_ t: TimeInterval) -> String {
        let m = Int(t) / 60
        let s = Int(t) % 60
        return String(format: "%02d:%02d", m, s)
    }
}

struct SiriHintBanner: View {
    let onDismiss: () -> Void

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Text("💡")
                .scaledFont(size: 18)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 4) {
                Text("Tip: usa tu voz")
                    .scaledFont(size: 13, weight: .bold)
                    .foregroundColor(Theme.text)
                Text("Prueba decir \"Oye Siri, marca serie en GymFlow\" para avanzar sin soltar las pesas.")
                    .scaledFont(size: 13)
                    .foregroundColor(Theme.textSecondary)
            }
            .accessibilityElement(children: .combine)

            Spacer()

            Button(action: onDismiss) {
                Image(systemName: "xmark")
                    .scaledFont(size: 12, weight: .semibold)
                    .foregroundColor(Theme.textSecondary)
            }
            .accessibilityLabel("Cerrar sugerencia de Siri")
        }
        .padding(14)
        .background(Theme.amber.opacity(0.1))
        .cornerRadius(14)
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Theme.amber.opacity(0.25), lineWidth: 1)
        )
    }
}

struct ExerciseCheckRow: View {
    let exercise: Exercise
    @Binding var checkedSets: [Bool]
    let onToggleSet: (Int) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.white.opacity(0.1))
                        .frame(width: 36, height: 36)
                    Text(exercise.icon)
                        .scaledFont(size: 18)
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(ExerciseCatalog.displayName(id: exercise.id, storedName: exercise.name))
                        .scaledFont(size: 16, weight: .bold)
                        .foregroundColor(Theme.text)
                    Text("\(exercise.defaultValue) \(ExerciseCatalog.displayUnit(exercise.unit))")
                        .scaledFont(size: 13)
                        .foregroundColor(Theme.textSecondary)
                }
                
                Spacer()

                let completed = checkedSets.filter { $0 }.count
                Text("\(completed)/\(exercise.sets)")
                    .scaledFont(size: 14, weight: .bold)
                    .foregroundColor(completed == exercise.sets ? Theme.green : Theme.textSecondary)
                    .contentTransition(.numericText())
                    .animation(.spring(response: 0.3, dampingFraction: 0.7), value: completed)
            }
            .accessibilityElement(children: .combine)

            // Checkboxes
            HStack(spacing: 12) {
                ForEach(0..<exercise.sets, id: \.self) { i in
                    let isChecked = checkedSets[i]
                    Button(action: { onToggleSet(i) }) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 10)
                                .fill(isChecked ? Theme.green : Color(hex: "#2C2C2E"))
                                .frame(height: 48)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10)
                                        .stroke(isChecked ? Theme.green : Color(hex: "#3A3A3C"), lineWidth: 1)
                                )

                            if isChecked {
                                Image(systemName: "checkmark")
                                    .scaledFont(size: 18, weight: .bold)
                                    .foregroundColor(.white)
                                    .transition(.scale.combined(with: .opacity))
                            } else {
                                Text("\(i + 1)")
                                    .scaledFont(size: 16, weight: .bold)
                                    .foregroundColor(Theme.textSecondary)
                            }
                        }
                    }
                    .buttonStyle(PlainButtonStyle())
                    .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isChecked)
                    .accessibilityLabel("Serie \(i + 1) de \(ExerciseCatalog.displayName(id: exercise.id, storedName: exercise.name))")
                    .accessibilityValue(isChecked ? "Completada" : "Pendiente")
                    .accessibilityAddTraits(.isButton)
                }
            }
        }
        .padding(16)
        .glassCard()
        .opacity(checkedSets.allSatisfy { $0 } ? 0.6 : 1.0)
    }
}

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
