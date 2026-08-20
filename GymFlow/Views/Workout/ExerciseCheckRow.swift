import SwiftUI
import UIKit

/// Fila de un ejercicio durante el entrenamiento.
///
/// Tiene dos modos según el ejercicio:
///  · Por repeticiones → lista vertical de series con kg × reps editables.
///  · Por tiempo (min/seg) → cuadrícula de series con cronómetro y 3-2-1.
struct ExerciseCheckRow: View {
    let exercise: Exercise
    let displayIndex: Int
    @ObservedObject var session: ActiveWorkoutSession
    let isPrioritized: Bool
    let isDimmed: Bool
    let isFirst: Bool
    let isLast: Bool
    let onMoveUp: () -> Void
    let onMoveDown: () -> Void

    // Cronómetro por serie (solo ejercicios por tiempo)
    @State private var activeTimerSetIndex: Int? = nil
    @State private var timerPhase: TimerPhase = .idle
    @State private var countdownValue: Int = 3
    @State private var remainingSeconds: Int = 0
    @State private var timerRef: Timer? = nil
    @State private var showInfo = false

    enum TimerPhase { case idle, countdown, running, done }

    // MARK: - Derivados

    private var checks: [Bool] {
        session.checkedSets.indices.contains(displayIndex)
            ? session.checkedSets[displayIndex] : []
    }

    private var completedCount: Int { checks.filter { $0 }.count }
    private var allDone: Bool { !checks.isEmpty && checks.allSatisfy { $0 } }
    private var isTimeBased: Bool { ExerciseCatalog.isTimeBased(unit: exercise.unit) }

    private var pattern: MovementPattern {
        ExerciseAnimationCatalog.pattern(forId: exercise.id, category: exercise.category)
    }

    private var displayName: String {
        ExerciseCatalog.displayName(id: exercise.id, storedName: exercise.name)
    }

    private var animationPlaying: Bool {
        !allDone && !isDimmed && !session.isReorderMode
    }

    private var durationSeconds: Int {
        exercise.unit == "min" ? exercise.defaultValue * 60 : exercise.defaultValue
    }

    // MARK: - Body

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            header

            if session.isReorderMode {
                // En modo ordenar no se editan series: solo se mueve el bloque.
                EmptyView()
            } else if isTimeBased {
                timedSetGrid
            } else {
                weightSetList
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

    // MARK: - Cabecera

    private var header: some View {
        HStack {
            Button(action: { showInfo = true }) {
                ExerciseAnimationTile(
                    pattern: pattern, size: 44,
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
                Text(subtitle)
                    .scaledFont(size: 13)
                    .foregroundColor(Theme.textSecondary)
            }

            Spacer()

            if session.isReorderMode {
                reorderButtons
            } else {
                Text("\(completedCount)/\(checks.count)")
                    .scaledFont(size: 14, weight: .bold)
                    .foregroundColor(allDone ? Theme.green : Theme.textSecondary)
                    .contentTransition(.numericText())
                    .animation(.spring(response: 0.3, dampingFraction: 0.7), value: completedCount)
            }
        }
    }

    private var subtitle: String {
        if isTimeBased {
            return "\(exercise.defaultValue) \(ExerciseCatalog.displayUnit(exercise.unit))"
        }
        let target = session.weight(exIndex: displayIndex, setIndex: 0)
        if target > 0 {
            return "\(formatWeight(target)) kg × \(exercise.defaultValue)"
        }
        return "\(exercise.defaultValue) \(ExerciseCatalog.displayUnit(exercise.unit))"
    }

    private var reorderButtons: some View {
        HStack(spacing: 4) {
            Button(action: { tapFeedback(); onMoveUp() }) {
                Image(systemName: "chevron.up.circle.fill")
                    .scaledFont(size: 26)
                    .foregroundColor(isFirst ? Theme.textSecondary.opacity(0.3) : Theme.blue)
            }
            .disabled(isFirst)

            Button(action: { tapFeedback(); onMoveDown() }) {
                Image(systemName: "chevron.down.circle.fill")
                    .scaledFont(size: 26)
                    .foregroundColor(isLast ? Theme.textSecondary.opacity(0.3) : Theme.blue)
            }
            .disabled(isLast)
        }
    }

    // MARK: - Series con peso (por repeticiones)

    private var weightSetList: some View {
        VStack(spacing: 6) {
            weightListHeader

            ForEach(checks.indices, id: \.self) { i in
                WeightSetRow(
                    number: i + 1,
                    isChecked: checks[i],
                    weight: weightBinding(i),
                    reps: repsBinding(i),
                    showsWeight: exercise.usesWeight,
                    exerciseName: displayName,
                    onToggle: { toggleSet(i) }
                )
            }
        }
    }

    private var weightListHeader: some View {
        HStack(spacing: 8) {
            Text("#")
                .frame(width: 20)
            if exercise.usesWeight {
                Text("KG").frame(width: 58)
            }
            Text(ExerciseCatalog.displayUnit(exercise.unit).uppercased())
                .frame(width: 52)
            Spacer()
            Text("").frame(width: 40)
        }
        .scaledFont(size: 9, weight: .bold)
        .foregroundColor(Theme.textSecondary.opacity(0.7))
        .accessibilityHidden(true)
    }

    /// Al cambiar el peso de una serie se propaga a las siguientes PENDIENTES.
    /// Es lo habitual en series rectas y evita teclear lo mismo 4 veces; si
    /// haces pirámide, editas cada serie antes de hacerla y listo.
    private func weightBinding(_ setIndex: Int) -> Binding<Double> {
        Binding(
            get: { session.weight(exIndex: displayIndex, setIndex: setIndex) },
            set: { session.applyWeightToRemaining($0, exIndex: displayIndex, fromSet: setIndex) }
        )
    }

    private func repsBinding(_ setIndex: Int) -> Binding<Int> {
        Binding(
            get: { session.reps(exIndex: displayIndex, setIndex: setIndex) },
            set: { session.setRepCount($0, exIndex: displayIndex, setIndex: setIndex) }
        )
    }

    // MARK: - Series por tiempo

    private var timedSetGrid: some View {
        HStack(spacing: 12) {
            ForEach(checks.indices, id: \.self) { i in
                timedSetButton(index: i)
            }
        }
    }

    @ViewBuilder
    private func timedSetButton(index: Int) -> some View {
        let isChecked = checks.indices.contains(index) ? checks[index] : false
        let isActiveTimer = activeTimerSetIndex == index

        Button(action: { handleTimedTap(index: index) }) {
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
        .accessibilityLabel("Serie \(index + 1) de \(displayName)")
        .accessibilityValue(isChecked ? "Completada" : "Pendiente")
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
        case .idle:
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

    // MARK: - Acciones

    private func toggleSet(_ index: Int) {
        session.toggleSet(exIndex: displayIndex, setIndex: index)
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }

    private func handleTimedTap(index: Int) {
        if checks.indices.contains(index), checks[index] {
            // Ya marcada — desmarcar
            session.toggleSet(exIndex: displayIndex, setIndex: index)
            if activeTimerSetIndex == index { cancelTimer() }
            return
        }
        if activeTimerSetIndex == index {
            cancelTimer()   // segundo toque = cancelar el cronómetro
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
                    timerPhase = .running
                    remainingSeconds = durationSeconds
                    UINotificationFeedbackGenerator().notificationOccurred(.success)
                }
            } else if timerPhase == .running {
                if remainingSeconds > 1 {
                    remainingSeconds -= 1
                } else {
                    t.invalidate()
                    timerPhase = .done
                    UINotificationFeedbackGenerator().notificationOccurred(.success)
                    UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
                    // Guarda los segundos realmente cronometrados
                    session.setRepCount(durationSeconds, exIndex: displayIndex, setIndex: index)
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        session.toggleSet(exIndex: displayIndex, setIndex: index)
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

    private func tapFeedback() {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }

    private func formatSeconds(_ s: Int) -> String {
        String(format: "%d:%02d", s / 60, s % 60)
    }

    private func formatWeight(_ w: Double) -> String {
        w == w.rounded() ? String(Int(w)) : String(format: "%.1f", w)
    }
}

// MARK: - Fila de una serie con peso

private struct WeightSetRow: View {
    let number: Int
    let isChecked: Bool
    @Binding var weight: Double
    @Binding var reps: Int
    let showsWeight: Bool
    let exerciseName: String
    let onToggle: () -> Void

    var body: some View {
        HStack(spacing: 8) {
            Text("\(number)")
                .scaledFont(size: 13, weight: .bold)
                .foregroundColor(isChecked ? Theme.green : Theme.textSecondary)
                .frame(width: 20)

            if showsWeight {
                NumberField(value: $weight, width: 58, step: 2.5,
                            label: "Peso serie \(number) de \(exerciseName)")
            }

            IntField(value: $reps, width: 52,
                     label: "Repeticiones serie \(number) de \(exerciseName)")

            Spacer(minLength: 4)

            Button(action: onToggle) {
                ZStack {
                    RoundedRectangle(cornerRadius: 9)
                        .fill(isChecked ? Theme.green : Color(hex: "#2C2C2E"))
                        .frame(width: 40, height: 34)
                        .overlay(
                            RoundedRectangle(cornerRadius: 9)
                                .stroke(isChecked ? Theme.green : Color(hex: "#3A3A3C"), lineWidth: 1)
                        )
                    Image(systemName: "checkmark")
                        .scaledFont(size: 15, weight: .bold)
                        .foregroundColor(isChecked ? .white : Theme.textSecondary.opacity(0.5))
                }
            }
            .buttonStyle(PlainButtonStyle())
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isChecked)
            .accessibilityLabel("Serie \(number) de \(exerciseName)")
            .accessibilityValue(isChecked ? "Completada" : "Pendiente")
        }
        .padding(.vertical, 3)
        .opacity(isChecked ? 0.65 : 1.0)
    }
}

// MARK: - Campos numéricos compactos

private struct NumberField: View {
    @Binding var value: Double
    let width: CGFloat
    let step: Double
    let label: String

    var body: some View {
        TextField("0", value: $value, format: .number.precision(.fractionLength(0...1)))
            .keyboardType(.decimalPad)
            .multilineTextAlignment(.center)
            .scaledFont(size: 15, weight: .semibold)
            .foregroundColor(Theme.text)
            .frame(width: width)
            .padding(.vertical, 7)
            .background(Color(hex: "#2C2C2E"))
            .cornerRadius(9)
            .accessibilityLabel(label)
    }
}

private struct IntField: View {
    @Binding var value: Int
    let width: CGFloat
    let label: String

    var body: some View {
        TextField("0", value: $value, format: .number)
            .keyboardType(.numberPad)
            .multilineTextAlignment(.center)
            .scaledFont(size: 15, weight: .semibold)
            .foregroundColor(Theme.text)
            .frame(width: width)
            .padding(.vertical, 7)
            .background(Color(hex: "#2C2C2E"))
            .cornerRadius(9)
            .accessibilityLabel(label)
    }
}
