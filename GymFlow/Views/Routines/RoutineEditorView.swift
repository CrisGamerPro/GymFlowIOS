import SwiftUI
import SwiftData

struct RoutineEditorView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    // Si se pasa una rutina, es modo edición
    var routineToEdit: Routine?
    
    @State private var name: String = ""
    @State private var desc: String = ""
    @State private var colorHex: String = Theme.palette[0]
    @State private var icon: String = Theme.icons[0]
    @State private var days: Set<Int> = []
    @State private var time: Date = Calendar.current.date(from: DateComponents(hour: 7, minute: 0)) ?? Date()
    @State private var hasTime: Bool = true
    
    // Copia temporal de los ejercicios para editar
    @State private var exercises: [Exercise] = []
    @State private var showExercisePicker = false
    
    init(routineToEdit: Routine? = nil) {
        self.routineToEdit = routineToEdit
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Theme.background.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 20) {
                        // Info básica
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
                        
                        // Diseño
                        VStack(alignment: .leading, spacing: 16) {
                            formField(label: "Color") {
                                ColorPickerGrid(selectedColor: $colorHex)
                            }
                            
                            formField(label: "Ícono") {
                                IconPickerGrid(selectedIcon: $icon)
                            }
                        }
                        
                        // Horario
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
                        
                        // Ejercicios
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Text("Ejercicios")
                                    .scaledFont(size: 13, weight: .semibold)
                                    .foregroundColor(Theme.textSecondary)
                                    .textCase(.uppercase)
                                Spacer()
                                Button(action: { showExercisePicker = true }) {
                                    HStack(spacing: 4) {
                                        Image(systemName: "plus")
                                            .accessibilityHidden(true)
                                        Text("Agregar")
                                    }
                                    .scaledFont(size: 14, weight: .bold)
                                    .foregroundColor(Theme.text)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .glassCard()
                                }
                            }

                            if exercises.isEmpty {
                                Text("Sin ejercicios. Toca \"＋ Agregar\".")
                                    .scaledFont(size: 14)
                                    .foregroundColor(Theme.textSecondary)
                                    .frame(maxWidth: .infinity, alignment: .center)
                                    .padding(.vertical, 20)
                            } else {
                                ForEach($exercises.indices, id: \.self) { index in
                                    ExerciseRowEdit(exercise: $exercises[index], onRemove: {
                                        withAnimation {
                                            _ = exercises.remove(at: index)
                                        }
                                    })
                                    .transition(.opacity.combined(with: .move(edge: .trailing)))
                                }
                            }
                        }
                        .animation(.easeInOut(duration: 0.2), value: exercises.count)

                        // Botón de guardar
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
                    .padding()
                }
            }
            .navigationTitle(routineToEdit == nil ? "Nueva Rutina" : "Editar Rutina")
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
        if let routine = routineToEdit {
            name = routine.name
            desc = routine.desc
            colorHex = routine.colorHex
            icon = routine.icon
            days = Set(routine.days)
            if let t = routine.time {
                time = t
                hasTime = true
            } else {
                hasTime = false
            }
            // Realizar copia de ejercicios
            exercises = routine.exercises.sorted(by: { $0.order < $1.order }).map { ex in
                Exercise(id: ex.id, name: ex.name, icon: ex.icon, category: ex.category, unit: ex.unit, sets: ex.sets, defaultValue: ex.defaultValue, order: ex.order)
            }
        }
    }
    
    private func saveRoutine() {
        guard !name.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        
        let routine: Routine
        if let existing = routineToEdit {
            routine = existing
            routine.name = name
            routine.desc = desc
            routine.colorHex = colorHex
            routine.icon = icon
            routine.days = Array(days)
            routine.time = hasTime ? time : nil
            routine.updatedAt = Date()
            
            // Reemplazar ejercicios (eliminar viejos y poner los de la copia)
            for ex in routine.exercises {
                modelContext.delete(ex)
            }
            routine.exercises = []
        } else {
            routine = Routine(name: name, desc: desc, colorHex: colorHex, icon: icon, days: Array(days), time: hasTime ? time : nil)
            modelContext.insert(routine)
        }
        
        
        // Agregar ejercicios a la rutina actualizando el order
        for (i, ex) in exercises.enumerated() {
            ex.order = i
            ex.routine = routine
            routine.exercises.append(ex)
        }
        
        try? modelContext.save()
        
        // Programar notificaciones
        if routine.time != nil && !routine.days.isEmpty {
            NotificationService.shared.requestPermission { granted in
                if granted {
                    NotificationService.shared.scheduleNotifications(for: routine)
                }
            }
        } else {
            NotificationService.shared.cancelNotifications(for: routine)
        }
        
        dismiss()
    }
}

struct CustomTextFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .scaledFont(size: 16)
            .foregroundColor(Theme.text)
            .padding(14)
            .background(Color(hex: "#2C2C2E"))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color(hex: "#3A3A3C"), lineWidth: 1)
            )
    }
}

struct ExerciseRowEdit: View {
    @Binding var exercise: Exercise
    var onRemove: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color(hex: "#2C2C2E"))
                    .frame(width: 36, height: 36)
                Text(exercise.icon)
                    .scaledFont(size: 18)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(ExerciseCatalog.displayName(id: exercise.id, storedName: exercise.name))
                    .scaledFont(size: 15, weight: .bold)
                    .foregroundColor(Theme.text)
                Text("\(exercise.sets) \(setsWord) × \(exercise.defaultValue) \(ExerciseCatalog.displayUnit(exercise.unit))")
                    .scaledFont(size: 12)
                    .foregroundColor(Theme.textSecondary)
            }
            
            Spacer()
            
            HStack(spacing: 6) {
                // Stepper custom or simple text fields for Phase 1
                VStack(spacing: 2) {
                    Text("Series")
                        .scaledFont(size: 9)
                        .foregroundColor(Theme.textSecondary)
                    TextField("", value: $exercise.sets, formatter: NumberFormatter())
                        .keyboardType(.numberPad)
                        .multilineTextAlignment(.center)
                        .frame(width: 36)
                        .padding(.vertical, 4)
                        .background(Color(hex: "#2C2C2E"))
                        .cornerRadius(6)
                        .foregroundColor(Theme.text)
                        .accessibilityLabel(labelJoiner(setsWord.capitalized, exerciseDisplayName))
                }

                Text("×")
                    .foregroundColor(Theme.textSecondary)
                    .scaledFont(size: 12)
                    .accessibilityHidden(true)

                VStack(spacing: 2) {
                    Text(ExerciseCatalog.displayUnit(exercise.unit).capitalized)
                        .scaledFont(size: 9)
                        .foregroundColor(Theme.textSecondary)
                    TextField("", value: $exercise.defaultValue, formatter: NumberFormatter())
                        .keyboardType(.numberPad)
                        .multilineTextAlignment(.center)
                        .frame(width: 44)
                        .padding(.vertical, 4)
                        .background(Color(hex: "#2C2C2E"))
                        .cornerRadius(6)
                        .foregroundColor(Theme.text)
                        .accessibilityLabel(labelJoiner(ExerciseCatalog.displayUnit(exercise.unit).capitalized, exerciseDisplayName))
                }

                Button(action: onRemove) {
                    Image(systemName: "xmark")
                        .scaledFont(size: 16, weight: .bold)
                        .foregroundColor(Theme.red)
                        .padding(.leading, 8)
                }
                .accessibilityLabel("Eliminar \(exerciseDisplayName)")
            }
        }
        .padding(12)
        .background(Color(hex: "#1C1C1E"))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color(hex: "#3A3A3C"), lineWidth: 1)
        )
    }

    private var exerciseDisplayName: String {
        ExerciseCatalog.displayName(id: exercise.id, storedName: exercise.name)
    }

    private var setsWord: String {
        AppLanguage.current == .english ? "sets" : "series"
    }

    private func labelJoiner(_ field: String, _ name: String) -> String {
        AppLanguage.current == .english ? "\(field) for \(name)" : "\(field) de \(name)"
    }
}
