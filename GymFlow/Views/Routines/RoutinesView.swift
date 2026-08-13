import SwiftUI
import SwiftData

struct RoutinesView: View {
    @Binding var showCreateModal: Bool
    @Query(sort: \Routine.createdAt, order: .reverse) private var routines: [Routine]
    @Environment(\.modelContext) private var modelContext
    @State private var routineToEdit: Routine?
    
    var body: some View {
        NavigationStack {
            ZStack {
                Theme.background.ignoresSafeArea()
                
                if routines.isEmpty {
                    VStack(spacing: 16) {
                        Text("💪")
                            .scaledFont(size: 52)
                            .opacity(0.6)
                        Text("Sin rutinas aún")
                            .scaledFont(size: 18, weight: .bold)
                            .foregroundColor(Theme.text)
                        Text("Crea tu primera rutina para empezar a entrenar.")
                            .scaledFont(size: 14)
                            .foregroundColor(Theme.textSecondary)
                        
                        Button(action: { showCreateModal = true }) {
                            Text("＋ Nueva Rutina")
                                .scaledFont(size: 16, weight: .bold)
                                .foregroundColor(.black)
                                .padding(.horizontal, 24)
                                .padding(.vertical, 14)
                                .background(Theme.amber)
                                .cornerRadius(16)
                        }
                        .padding(.top, 20)
                    }
                } else {
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(routines) { routine in
                                RoutineCard(routine: routine)
                                    .transition(.opacity.combined(with: .scale(scale: 0.95)))
                                    .onTapGesture {
                                        routineToEdit = routine
                                    }
                                    .contextMenu {
                                        Button(role: .destructive) {
                                            deleteRoutine(routine)
                                        } label: {
                                            Label("Eliminar", systemImage: "trash")
                                        }
                                    }
                                    .accessibilityElement(children: .combine)
                                    .accessibilityAddTraits(.isButton)
                                    .accessibilityHint("Toca dos veces para editar. Mantén presionado para más opciones.")
                            }
                        }
                        .padding()
                        .animation(.easeInOut(duration: 0.25), value: routines.count)
                    }
                }
            }
            .navigationTitle("Mis Rutinas")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Theme.cardBackground, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .sheet(item: $routineToEdit) { routine in
                RoutineEditorView(routineToEdit: routine)
            }
        }
    }

    @MainActor
    private func deleteRoutine(_ routine: Routine) {
        // Si esta rutina está en curso, corta la sesión primero: si no, la
        // sesión quedaría apuntando a un objeto SwiftData ya eliminado.
        if ActiveWorkoutSession.shared.isRunning(routineId: routine.id) {
            ActiveWorkoutSession.shared.cancelActiveWorkout(external: true)
        }
        withAnimation {
            NotificationService.shared.cancelNotifications(for: routine)
            modelContext.delete(routine)
            try? modelContext.save()
        }
    }
}

struct RoutineCard: View {
    let routine: Routine
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color(hex: routine.colorHex).opacity(0.2))
                        .frame(width: 44, height: 44)
                    Text(routine.icon)
                        .scaledFont(size: 22)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(routine.name)
                        .scaledFont(size: 18, weight: .bold)
                        .foregroundColor(Theme.text)
                    if !routine.desc.isEmpty {
                        Text(routine.desc)
                            .scaledFont(size: 13)
                            .foregroundColor(Theme.textSecondary)
                            .lineLimit(1)
                    }
                }
                
                Spacer()
                
                if let time = routine.time {
                    Text(time, style: .time)
                        .scaledFont(size: 13, weight: .bold)
                        .foregroundColor(Theme.amber)
                }
            }
            
            // Exercises pills
            if !routine.exercises.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack {
                        ForEach(routine.orderedExercises.prefix(4), id: \.id) { exercise in
                            HStack(spacing: 4) {
                                Text(exercise.icon)
                                Text(ExerciseCatalog.displayName(id: exercise.id, storedName: exercise.name))
                            }
                            .scaledFont(size: 12)
                            .foregroundColor(Theme.textSecondary)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .background(Color.white.opacity(0.1))
                            .cornerRadius(20)
                        }
                        if routine.exercises.count > 4 {
                            Text("+\(routine.exercises.count - 4) más")
                                .scaledFont(size: 12)
                                .foregroundColor(Theme.textSecondary)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 4)
                                .background(Color.white.opacity(0.1))
                                .cornerRadius(20)
                        }
                    }
                }
            }
            
            // Days chips
            HStack(spacing: 5) {
                let dayNames = AppLanguage.current.dayLetters
                ForEach(0..<7, id: \.self) { i in
                    let isOn = routine.days.contains(i)
                    Text(dayNames[i])
                        .scaledFont(size: 11, weight: .bold)
                        .foregroundColor(isOn ? Theme.amber : Theme.textSecondary.opacity(0.5))
                        .frame(width: 28, height: 28)
                        .background(isOn ? Theme.amber.opacity(0.15) : Color.white.opacity(0.05))
                        .cornerRadius(14)
                        .overlay(
                            RoundedRectangle(cornerRadius: 14)
                                .stroke(isOn ? Theme.amber.opacity(0.3) : Color.clear, lineWidth: 1)
                        )
                }
            }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(activeDaysSummary)
        }
        .padding(18)
        .glassCard()
    }

    private var activeDaysSummary: String {
        let language = AppLanguage.current
        let active = routine.days.sorted().map { language.dayFullNames[$0] }
        if active.isEmpty {
            return language == .english ? "No days assigned" : "Sin días asignados"
        }
        let prefix = language == .english ? "Days" : "Días"
        return "\(prefix): \(active.joined(separator: ", "))"
    }
}
