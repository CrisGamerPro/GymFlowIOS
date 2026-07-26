import SwiftUI
import SwiftData

struct ScheduleView: View {
    @Query(sort: \Routine.createdAt) private var routines: [Routine]
    @State private var selectedDay: Int = ScheduleView.todayGymFlowWeekday()
    @AppStorage(AppLanguage.storageKey) private var languageCode = AppLanguage.spanish.rawValue

    private var language: AppLanguage { AppLanguage(rawValue: languageCode) ?? .spanish }
    private var dayNames: [String] { language.dayFullNames }

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.background.ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        WeekStripView(selectedDay: $selectedDay, routines: routines)

                        VStack(alignment: .leading, spacing: 12) {
                            Text(dayTitle)
                                .scaledFont(size: 20, weight: .heavy)
                                .foregroundColor(Theme.text)

                            let dayRoutines = routines(for: selectedDay)
                            if dayRoutines.isEmpty {
                                VStack(spacing: 8) {
                                    Text("🌴")
                                        .scaledFont(size: 32)
                                    Text("Sin rutinas este día")
                                        .scaledFont(size: 14)
                                        .foregroundColor(Theme.textSecondary)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 24)
                                .glassCard()
                            } else {
                                ForEach(dayRoutines) { routine in
                                    NavigationLink(destination: ActiveWorkoutView(routine: routine)) {
                                        TodayRoutineCard(routine: routine)
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                }
                            }
                        }
                        .id(selectedDay)
                        .transition(.opacity)

                        VStack(alignment: .leading, spacing: 12) {
                            Text("Resto de la semana")
                                .scaledFont(size: 13, weight: .semibold)
                                .foregroundColor(Theme.textSecondary)
                                .textCase(.uppercase)

                            ForEach(upcomingDays(), id: \.self) { day in
                                UpcomingDayRow(
                                    dayName: dayNames[day],
                                    count: routines(for: day).count
                                ) {
                                    withAnimation { selectedDay = day }
                                }
                            }
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Agenda")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Theme.cardBackground, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
    }

    private var dayTitle: String {
        let name = dayNames[selectedDay]
        guard selectedDay == ScheduleView.todayGymFlowWeekday() else { return name }
        return language == .english ? "Today · \(name)" : "Hoy · \(name)"
    }

    private func routines(for day: Int) -> [Routine] {
        routines.filter { $0.days.contains(day) }
    }

    private func upcomingDays() -> [Int] {
        (1...6).map { (selectedDay + $0) % 7 }
    }

    static func todayGymFlowWeekday() -> Int {
        let weekday = Calendar.current.component(.weekday, from: Date())
        // iOS: 1=Dom, 2=Lun... GymFlow: 0=Lun, 1=Mar...6=Dom
        return (weekday == 1) ? 6 : weekday - 2
    }
}

struct WeekStripView: View {
    @Binding var selectedDay: Int
    let routines: [Routine]
    @AppStorage(AppLanguage.storageKey) private var languageCode = AppLanguage.spanish.rawValue

    private var language: AppLanguage { AppLanguage(rawValue: languageCode) ?? .spanish }
    private var dayLetters: [String] { language.dayLetters }
    private var fullDayNames: [String] { language.dayFullNames }

    var body: some View {
        HStack(spacing: 8) {
            ForEach(0..<7, id: \.self) { day in
                let isSelected = day == selectedDay
                let isToday = day == ScheduleView.todayGymFlowWeekday()
                let hasRoutines = routines.contains { $0.days.contains(day) }

                Button(action: { withAnimation(.spring(response: 0.3)) { selectedDay = day } }) {
                    VStack(spacing: 6) {
                        Text(dayLetters[day])
                            .scaledFont(size: 13, weight: .bold)
                            .foregroundColor(isSelected ? .black : (isToday ? Theme.amber : Theme.textSecondary))

                        Circle()
                            .fill(hasRoutines ? (isSelected ? Color.black : Theme.amber) : Color.clear)
                            .frame(width: 5, height: 5)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(isSelected ? Theme.amber : Color.white.opacity(0.05))
                    .cornerRadius(14)
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(isToday && !isSelected ? Theme.amber.opacity(0.4) : Color.clear, lineWidth: 1)
                    )
                }
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(accessibilityDayLabel(day: day, isToday: isToday))
                .accessibilityValue(hasRoutines ? "Con rutinas" : "Sin rutinas")
                .accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : .isButton)
            }
        }
    }

    private func accessibilityDayLabel(day: Int, isToday: Bool) -> String {
        let name = fullDayNames[day]
        guard isToday else { return name }
        return language == .english ? "\(name), today" : "\(name), hoy"
    }
}

struct UpcomingDayRow: View {
    let dayName: String
    let count: Int
    let onTap: () -> Void
    @AppStorage(AppLanguage.storageKey) private var languageCode = AppLanguage.spanish.rawValue

    private var routineCountLabel: String {
        let language = AppLanguage(rawValue: languageCode) ?? .spanish
        if count == 0 {
            return language == .english ? "No routines" : "Sin rutinas"
        }
        if language == .english {
            return "\(count) routine\(count == 1 ? "" : "s")"
        }
        return "\(count) rutina\(count == 1 ? "" : "s")"
    }

    var body: some View {
        Button(action: onTap) {
            HStack {
                Text(dayName)
                    .scaledFont(size: 15, weight: .semibold)
                    .foregroundColor(Theme.text)
                Spacer()
                Text(routineCountLabel)
                    .scaledFont(size: 13)
                    .foregroundColor(count == 0 ? Theme.textSecondary : Theme.amber)
                Image(systemName: "chevron.right")
                    .scaledFont(size: 12, weight: .semibold)
                    .foregroundColor(Theme.textSecondary)
                    .accessibilityHidden(true)
            }
            .padding(14)
            .glassCard()
        }
        .buttonStyle(PlainButtonStyle())
    }
}
