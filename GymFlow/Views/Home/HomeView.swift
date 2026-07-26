import SwiftUI
import SwiftData

struct HomeView: View {
    @AppStorage("gymflow.userName") private var userName: String = ""
    @Query private var routines: [Routine]
    @Query private var progress: [WorkoutLog]

    var body: some View {
        NavigationStack {
            ScrollView {
            VStack(spacing: 20) {
                GreetingCard(userName: userName, routinesCount: routines.count)
                
                StatsRow(totalRoutines: routines.count, streak: calculateStreak())
                
                VStack(alignment: .leading, spacing: 12) {
                    Text("Hoy")
                        .scaledFont(size: 20, weight: .heavy)
                        .foregroundColor(Theme.text)
                    
                    let todayRoutines = getTodayRoutines()
                    if todayRoutines.isEmpty {
                        VStack(spacing: 8) {
                            Text("🌟")
                                .scaledFont(size: 36)
                            Text("No tienes rutinas para hoy.")
                                .foregroundColor(Theme.text)
                            Text("Descansa o crea una rutina nueva.")
                                .scaledFont(size: 13)
                                .foregroundColor(Theme.textSecondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 28)
                        .glassCard()
                    } else {
                        ForEach(todayRoutines) { routine in
                            NavigationLink(destination: ActiveWorkoutView(routine: routine)) {
                                TodayRoutineCard(routine: routine)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                }
            }
            .padding()
        }
    }
    }
    
    private func getTodayRoutines() -> [Routine] {
        let calendar = Calendar.current
        // Map iOS weekday (1=Sun, 2=Mon...) to GymFlow weekday (0=Mon, 1=Tue...)
        let weekday = calendar.component(.weekday, from: Date())
        let gymflowWeekday = (weekday == 1) ? 6 : weekday - 2
        
        return routines.filter { $0.days.contains(gymflowWeekday) }
    }
    
    private func calculateStreak() -> Int {
        // Dummy implementation for Phase 1
        return progress.count
    }
}

struct GreetingCard: View {
    let userName: String
    let routinesCount: Int
    @AppStorage(AppLanguage.storageKey) private var languageCode = AppLanguage.spanish.rawValue

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(greetingTime())
                    .scaledFont(size: 13, weight: .semibold)
                    .foregroundColor(Theme.amber)
                    .textCase(.uppercase)

                Text("\(displayName) 👋")
                    .scaledFont(size: 30, weight: .heavy)
                    .foregroundColor(Theme.text)
                
                Text("\(routinesCount) rutinas creadas")
                    .scaledFont(size: 14)
                    .foregroundColor(Theme.textSecondary)
            }
            Spacer()
        }
        .padding(22)
        .background(Theme.amber.opacity(0.13))
        .cornerRadius(22)
        .overlay(
            RoundedRectangle(cornerRadius: 22)
                .stroke(Theme.amber.opacity(0.28), lineWidth: 1)
        )
        .accessibilityElement(children: .combine)
    }
    
    private var displayName: String {
        userName.trimmingCharacters(in: .whitespaces).isEmpty ? "GymFlow" : userName
    }

    private func greetingTime() -> String {
        let language = AppLanguage(rawValue: languageCode) ?? .spanish
        let hour = Calendar.current.component(.hour, from: Date())
        return language.greeting(hour: hour)
    }
}

struct StatsRow: View {
    let totalRoutines: Int
    let streak: Int
    
    var body: some View {
        HStack(spacing: 10) {
            StatCard(value: "\(streak)", label: "Racha", color: Theme.amber)
            StatCard(value: "\(totalRoutines)", label: "Rutinas", color: Theme.green)
            StatCard(value: "0", label: "Esta semana", color: Theme.blue)
        }
    }
}

struct StatCard: View {
    let value: String
    let label: LocalizedStringKey
    let color: Color

    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .scaledFont(size: 28, weight: .heavy)
                .foregroundColor(color)
                .contentTransition(.numericText())
                .animation(.spring(response: 0.4, dampingFraction: 0.7), value: value)
            Text(label)
                .scaledFont(size: 11, weight: .medium)
                .foregroundColor(Theme.textSecondary)
                .textCase(.uppercase)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .glassCard()
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(label)
        .accessibilityValue(value)
    }
}

struct TodayRoutineCard: View {
    let routine: Routine
    
    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color(hex: routine.colorHex).opacity(0.2))
                    .frame(width: 44, height: 44)
                Text(routine.icon)
                    .scaledFont(size: 22)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(routine.name)
                    .scaledFont(size: 16, weight: .bold)
                    .foregroundColor(Theme.text)
                Text("\(routine.exercises.count) ejercicios")
                    .scaledFont(size: 13)
                    .foregroundColor(Theme.textSecondary)
            }
            
            Spacer()
            
            if let time = routine.time {
                Text(time, style: .time)
                    .scaledFont(size: 13, weight: .semibold)
                    .foregroundColor(Theme.amber)
            }
            
            Circle()
                .stroke(Color.white.opacity(0.3), lineWidth: 2)
                .frame(width: 26, height: 26)
                .accessibilityHidden(true)
        }
        .padding(16)
        .glassCard()
        .accessibilityElement(children: .combine)
        .accessibilityHint("Toca dos veces para iniciar el entrenamiento")
    }
}
