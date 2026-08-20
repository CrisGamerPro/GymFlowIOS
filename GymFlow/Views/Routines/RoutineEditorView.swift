import SwiftUI
import SwiftData
import UniformTypeIdentifiers

struct RoutineEditorView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    var routineToEdit: Routine?

    @State private var name: String = ""
    @State private var desc: String = ""
    @State private var colorHex: String = Theme.palette[0]
    @State private var icon: String = Theme.icons[0]
    @State private var days: Set<Int> = []
    @State private var time: Date = Calendar.current.date(from: DateComponents(hour: 7, minute: 0)) ?? Date()
    @State private var hasTime: Bool = true

    @State private var exercises: [Exercise] = []
    @State private var draggedIndex: Int? = nil
    @State private var showExercisePicker = false

    init(routineToEdit: Routine? = nil) {
        self.routineToEdit = routineToEdit
    }

    private var navTitle: String {
        routineToEdit == nil ? "Nueva Rutina" : "Editar Rutina"
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.background.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {
                        basicInfoSection
                        designSection
                        scheduleSection

                        RoutineExercisesSection(
                            exercises: $exercises,
                            draggedIndex: $draggedIndex,
                            onAdd: { showExercisePicker = true }
                        )

                        saveButton
                    }
                    .padding()
                }
            }
            .navigationTitle(navTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") { dismiss() }
                        .foregroundColor(Theme.amber)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Guardar") { saveRoutine() }
                        .foregroundColor(Theme.amber)
                        .fontWeight(.bold)
                }
            }
            .toolbarBackground(Theme.cardBackground, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .onAppear(perform: loadData)
            .sheet(isPresented: $showExercisePicker) {
                ExercisePickerView(selectedExercises: $exercises)
            }
        }
    }

    // MARK: - Secciones

    private var basicInfoSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            formField(label: "Nombre") {
                TextField("ej. Piernas y Glúteos", text: $name)
                    .textFieldStyle(CustomTextFieldStyle())
            }
            formField(label: "Descripción (opcional)") {
                TextField("Notas sobre esta rutina...", text: $desc)
                    .textFieldStyle(CustomTextFieldStyle())
            }
        }
    }

    private var designSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            formField(label: "Color") {
                ColorPickerGrid(selectedColor: $colorHex)
            }
            formField(label: "Ícono") {
                IconPickerGrid(selectedIcon: $icon)
            }
        }
    }

    @ViewBuilder
    private var scheduleSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            formField(label: "Días") {
                DayPickerRow(selectedDays: $days)
            }

            Toggle(isOn: $hasTime) {
                Text("Recordatorio")
                    .scaledFont(size: 13, weight: .semibold)
                    .foregroundColor(Theme.textSecondary)
                    .textCase(.uppercase)
            }
            .tint(Theme.amber)

            if hasTime {
                DatePicker("Hora", selection: $time, displayedComponents: .hourAndMinute)
                    .colorScheme(.dark)
                    .scaledFont(size: 16, weight: .medium)
                    .foregroundColor(Theme.text)
            }
        }
    }

    private var saveButton: some View {
        Button(action: saveRoutine) {
            Text("Guardar Rutina")
                .scaledFont(size: 16, weight: .bold)
                .foregroundColor(.black)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(Theme.amber)
                .cornerRadius(16)
        }
        .padding(.top, 10)
        .padding(.bottom, 40)
    }

    private func formField<Content: View>(label: LocalizedStringKey, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(label)
                .scaledFont(size: 13, weight: .semibold)
                .foregroundColor(Theme.textSecondary)
                .textCase(.uppercase)
                .tracking(0.5)
            content()
        }
    }

    private func loadData() {
        guard let routine = routineToEdit else { return }
        name = routine.name
        desc = routine.desc
        colorHex = routine.colorHex
        icon = routine.icon
        days = Set(routine.days)
        if let t = routine.time { time = t; hasTime = true } else { hasTime = false }
        exercises = routine.orderedExercises.map { ex in
            Exercise(id: ex.id, name: ex.name, icon: ex.icon, category: ex.category,
                     unit: ex.unit, sets: ex.sets, defaultValue: ex.defaultValue, order: ex.order,
                     defaultWeight: ex.defaultWeight, restSeconds: ex.restSeconds)
        }
    }

    @MainActor
    private func saveRoutine() {
        guard !name.trimmingCharacters(in: .whitespaces).isEmpty else { return }

        let routine: Routine
        if let existing = routineToEdit {
            routine = existing
            routine.name = name; routine.desc = desc; routine.colorHex = colorHex
            routine.icon = icon; routine.days = Array(days)
            routine.time = hasTime ? time : nil; routine.updatedAt = Date()
            for ex in routine.exercises { modelContext.delete(ex) }
            routine.exercises = []
        } else {
            routine = Routine(name: name, desc: desc, colorHex: colorHex, icon: icon,
                              days: Array(days), time: hasTime ? time : nil)
            modelContext.insert(routine)
        }

        for (i, ex) in exercises.enumerated() {
            ex.order = i
            ex.routine = routine
            routine.exercises.append(ex)
            modelContext.insert(ex)
        }
        try? modelContext.save()
        WidgetSnapshotService.refresh(context: modelContext)

        if routine.time != nil && !routine.days.isEmpty {
            NotificationService.shared.requestPermission { granted in
                if granted { NotificationService.shared.scheduleNotifications(for: routine) }
            }
        } else {
            NotificationService.shared.cancelNotifications(for: routine)
        }
        dismiss()
    }
}

// MARK: - Sección de ejercicios (extraída para no reventar el type-checker)

struct RoutineExercisesSection: View {
    @Binding var exercises: [Exercise]
    @Binding var draggedIndex: Int?
    let onAdd: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            header

            if exercises.isEmpty {
                Text("Sin ejercicios. Toca \"＋ Agregar\".")
                    .scaledFont(size: 14)
                    .foregroundColor(Theme.textSecondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 20)
            } else {
                VStack(spacing: 8) {
                    ForEach(exercises.indices, id: \.self) { index in
                        row(at: index)
                    }
                }
            }
        }
        .animation(.easeInOut(duration: 0.2), value: exercises.count)
    }

    private var header: some View {
        HStack {
            Text("Ejercicios")
                .scaledFont(size: 13, weight: .semibold)
                .foregroundColor(Theme.textSecondary)
                .textCase(.uppercase)

            Spacer()

            Button(action: onAdd) {
                HStack(spacing: 4) {
                    Image(systemName: "plus").accessibilityHidden(true)
                    Text("Agregar")
                }
                .scaledFont(size: 14, weight: .bold)
                .foregroundColor(Theme.text)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .glassCard()
            }
        }
    }

    @ViewBuilder
    private func row(at index: Int) -> some View {
        ExerciseRowEdit(
            exercise: $exercises[index],
            onRemove: { remove(at: index) }
        )
        .overlay(alignment: .leading) {
            Image(systemName: "line.3.horizontal")
                .scaledFont(size: 16)
                .foregroundColor(Theme.textSecondary.opacity(0.6))
                .padding(.leading, 6)
                .accessibilityHidden(true)
        }
        .onDrag {
            draggedIndex = index
            return NSItemProvider(object: "\(index)" as NSString)
        }
        .onDrop(
            of: [UTType.text],
            delegate: ExerciseReorderDelegate(
                targetIndex: index,
                exercises: $exercises,
                draggedIndex: $draggedIndex
            )
        )
        .transition(.opacity.combined(with: .move(edge: .trailing)))
    }

    /// El índice viene capturado en el closure de la fila: si el array ya
    /// encogió (doble tap, animación en curso) sería un índice fuera de rango.
    private func remove(at index: Int) {
        guard exercises.indices.contains(index) else { return }
        withAnimation { exercises.remove(at: index) }
    }
}

// MARK: - Drag-to-reorder delegate

struct ExerciseReorderDelegate: DropDelegate {
    let targetIndex: Int
    @Binding var exercises: [Exercise]
    @Binding var draggedIndex: Int?

    func dropEntered(info: DropInfo) {
        guard let from = draggedIndex, from != targetIndex,
              exercises.indices.contains(from),
              exercises.indices.contains(targetIndex) else { return }
        withAnimation(.easeInOut(duration: 0.2)) {
            exercises.move(fromOffsets: IndexSet(integer: from),
                           toOffset: targetIndex > from ? targetIndex + 1 : targetIndex)
        }
        draggedIndex = targetIndex
    }

    func dropUpdated(info: DropInfo) -> DropProposal? {
        DropProposal(operation: .move)
    }

    func performDrop(info: DropInfo) -> Bool {
        draggedIndex = nil
        return true
    }
}

// MARK: - Supporting views (shared with DataExportService-free files)

struct CustomTextFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .scaledFont(size: 16)
            .foregroundColor(Theme.text)
            .padding(14)
            .background(Color(hex: "#2C2C2E"))
            .cornerRadius(12)
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color(hex: "#3A3A3C"), lineWidth: 1))
    }
}

struct ExerciseRowEdit: View {
    @Binding var exercise: Exercise
    var onRemove: () -> Void

    @State private var showInfo = false

    private var pattern: MovementPattern {
        ExerciseAnimationCatalog.pattern(forId: exercise.id, category: exercise.category)
    }

    var body: some View {
        VStack(spacing: 10) {
            topRow
            fieldsRow
        }
        .padding(12)
        .background(Color(hex: "#1C1C1E"))
        .cornerRadius(12)
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color(hex: "#3A3A3C"), lineWidth: 1))
        .sheet(isPresented: $showInfo) {
            ExerciseInfoSheet(exercise: exercise)
        }
    }

    /// Nombre, animación y botón de eliminar.
    private var topRow: some View {
        HStack(spacing: 12) {
            // Toca la animación para ver la ficha del ejercicio.
            // Va desplazada a la derecha para no chocar con el asa de arrastre.
            Button(action: { showInfo = true }) {
                ExerciseAnimationTile(pattern: pattern, size: 38)
            }
            .buttonStyle(PlainButtonStyle())
            .padding(.leading, 18)
            .accessibilityLabel("Cómo se hace \(exerciseDisplayName)")

            VStack(alignment: .leading, spacing: 2) {
                Text(exerciseDisplayName)
                    .scaledFont(size: 15, weight: .bold)
                    .foregroundColor(Theme.text)
                Text(summary)
                    .scaledFont(size: 12)
                    .foregroundColor(Theme.textSecondary)
            }

            Spacer()

            Button(action: onRemove) {
                Image(systemName: "xmark")
                    .scaledFont(size: 16, weight: .bold)
                    .foregroundColor(Theme.red)
                    .padding(6)
            }
            .accessibilityLabel("Eliminar \(exerciseDisplayName)")
        }
    }

    /// Series, valor, peso objetivo y descanso.
    private var fieldsRow: some View {
        HStack(spacing: 8) {
            field(label: "Series", width: 42) {
                TextField("", value: $exercise.sets, format: .number)
                    .accessibilityLabel("Series de \(exerciseDisplayName)")
            }

            field(label: ExerciseCatalog.displayUnit(exercise.unit).capitalized, width: 48) {
                TextField("", value: $exercise.defaultValue, format: .number)
                    .accessibilityLabel("\(ExerciseCatalog.displayUnit(exercise.unit)) de \(exerciseDisplayName)")
            }

            if exercise.usesWeight {
                field(label: "Kg", width: 52) {
                    TextField("0", value: $exercise.defaultWeight,
                              format: .number.precision(.fractionLength(0...1)))
                        .accessibilityLabel("Peso objetivo de \(exerciseDisplayName)")
                }
            }

            field(label: restLabel, width: 52) {
                // 0 = usar el descanso global de Ajustes; el placeholder lo dice.
                TextField(defaultRestPlaceholder, value: $exercise.restSeconds, format: .number)
                    .accessibilityLabel("Descanso en segundos de \(exerciseDisplayName)")
            }

            Spacer(minLength: 0)
        }
    }

    private func field<Content: View>(label: String, width: CGFloat,
                                      @ViewBuilder content: () -> Content) -> some View {
        VStack(spacing: 2) {
            Text(label)
                .scaledFont(size: 9)
                .foregroundColor(Theme.textSecondary)
            content()
                .keyboardType(.decimalPad)
                .multilineTextAlignment(.center)
                .scaledFont(size: 14, weight: .semibold)
                .foregroundColor(Theme.text)
                .frame(width: width)
                .padding(.vertical, 5)
                .background(Color(hex: "#2C2C2E"))
                .cornerRadius(7)
        }
    }

    private var summary: String {
        var parts = ["\(exercise.sets) \(setsWord) × \(exercise.defaultValue) \(ExerciseCatalog.displayUnit(exercise.unit))"]
        if exercise.usesWeight, exercise.defaultWeight > 0 {
            let w = exercise.defaultWeight == exercise.defaultWeight.rounded()
                ? String(Int(exercise.defaultWeight))
                : String(format: "%.1f", exercise.defaultWeight)
            parts.append("\(w) kg")
        }
        return parts.joined(separator: " · ")
    }

    private var exerciseDisplayName: String {
        ExerciseCatalog.displayName(id: exercise.id, storedName: exercise.name)
    }

    private var setsWord: String {
        AppLanguage.current == .english ? "sets" : "series"
    }

    private var restLabel: String {
        AppLanguage.current == .english ? "Rest s" : "Desc. s"
    }

    private var defaultRestPlaceholder: String {
        String(ActiveWorkoutSession.globalDefaultRest)
    }
}
