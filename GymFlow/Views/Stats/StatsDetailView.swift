import SwiftUI
import SwiftData
import Charts

struct StatsDetailView: View {
    @Query private var logs: [WorkoutLog]

    private let dayCount = 14

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 24) {
                    summaryRow
                    chartSection
                    recentSection
                }
                .padding()
            }
        }
        .navigationTitle("Estadísticas")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(Theme.cardBackground, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
    }

    // MARK: - Summary tiles

    private var summaryRow: some View {
        let completed = logs.filter { $0.isCompleted }.count
        let empezadas = logs.count
        let streak = calculateStreak()

        return HStack(spacing: 10) {
            StatCard(value: "\(streak)", label: "Racha 🔥", color: Theme.amber)
            StatCard(value: "\(empezadas)", label: "Empezadas", color: Theme.blue)
            StatCard(value: "\(completed)", label: "Completas", color: Theme.green)
        }
    }

    // MARK: - Bar chart for last N days

    private var chartSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Últimos \(dayCount) días")
                .scaledFont(size: 17, weight: .bold)
                .foregroundColor(Theme.text)

            Chart {
                ForEach(chartData, id: \.day) { entry in
                    if entry.completed > 0 {
                        BarMark(
                            x: .value("Día", entry.shortLabel),
                            y: .value("Completos", entry.completed)
                        )
                        .foregroundStyle(Theme.green)
                        .annotation(position: .top, alignment: .center) {
                            if entry.completed > 0 {
                                Text("\(entry.completed)")
                                    .scaledFont(size: 9, weight: .bold)
                                    .foregroundColor(Theme.green)
                            }
                        }
                    }

                    if entry.partial > 0 {
                        BarMark(
                            x: .value("Día", entry.shortLabel),
                            y: .value("Parciales", entry.partial)
                        )
                        .foregroundStyle(Theme.amber)
                    }
                }
            }
            .chartXAxis {
                AxisMarks(values: .automatic) { value in
                    AxisGridLine(stroke: StrokeStyle(lineWidth: 0))
                    AxisValueLabel {
                        if let str = value.as(String.self) {
                            Text(str)
                                .scaledFont(size: 10)
                                .foregroundColor(Theme.textSecondary)
                        }
                    }
                }
            }
            .chartYAxis {
                AxisMarks(position: .leading, values: .automatic(desiredCount: 3)) { value in
                    AxisGridLine()
                        .foregroundStyle(Color.white.opacity(0.08))
                    AxisValueLabel {
                        if let int = value.as(Int.self) {
                            Text("\(int)")
                                .scaledFont(size: 10)
                                .foregroundColor(Theme.textSecondary)
                        }
                    }
                }
            }
            .chartYScale(domain: 0...max(3, maxBarValue + 1))
            .frame(height: 200)
            .chartLegend(position: .bottom, alignment: .leading, spacing: 8) {
                HStack(spacing: 16) {
                    Label("Completos", systemImage: "circle.fill")
                        .scaledFont(size: 12)
                        .foregroundColor(Theme.green)
                    Label("Parciales", systemImage: "circle.fill")
                        .scaledFont(size: 12)
                        .foregroundColor(Theme.amber)
                }
            }
        }
        .padding(16)
        .glassCard()
    }

    // MARK: - Recent workouts list

    private var recentSection: some View {
        let recent = logs
            .sorted { $0.date > $1.date }
            .prefix(10)

        return VStack(alignment: .leading, spacing: 12) {
            Text("Recientes")
                .scaledFont(size: 17, weight: .bold)
                .foregroundColor(Theme.text)

            if recent.isEmpty {
                Text("Sin entrenamientos registrados.")
                    .scaledFont(size: 14)
                    .foregroundColor(Theme.textSecondary)
                    .padding(.vertical, 12)
            } else {
                ForEach(Array(recent)) { log in
                    LogRow(log: log)
                }
            }
        }
        .padding(16)
        .glassCard()
    }

    // MARK: - Data helpers

    private struct DayEntry {
        let day: Date
        let shortLabel: String
        let completed: Int
        let partial: Int
    }

    private var chartData: [DayEntry] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let shortFmt = DateFormatter()
        shortFmt.dateFormat = "d/M"

        return (0..<dayCount).reversed().map { offset -> DayEntry in
            let day = calendar.date(byAdding: .day, value: -offset, to: today)!
            let dayLogs = logs.filter { calendar.isDate($0.date, inSameDayAs: day) }
            let completed = dayLogs.filter { $0.isCompleted }.count
            let partial = dayLogs.filter { !$0.isCompleted }.count
            return DayEntry(day: day, shortLabel: shortFmt.string(from: day),
                            completed: completed, partial: partial)
        }
    }

    private var maxBarValue: Int {
        chartData.map { $0.completed + $0.partial }.max() ?? 0
    }

    private func calculateStreak() -> Int {
        let calendar = Calendar.current
        let completedDays = Set(
            logs.filter { $0.isCompleted }.map { calendar.startOfDay(for: $0.date) }
        ).sorted(by: >)

        guard !completedDays.isEmpty else { return 0 }
        var streak = 0
        var current = calendar.startOfDay(for: Date())
        for day in completedDays {
            if day == current {
                streak += 1
                current = calendar.date(byAdding: .day, value: -1, to: current)!
            } else { break }
        }
        return streak
    }
}

// MARK: - Log row

private struct LogRow: View {
    let log: WorkoutLog

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(statusColor.opacity(0.15))
                    .frame(width: 36, height: 36)
                Image(systemName: statusIcon)
                    .scaledFont(size: 16, weight: .semibold)
                    .foregroundColor(statusColor)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(log.routineName)
                    .scaledFont(size: 14, weight: .bold)
                    .foregroundColor(Theme.text)
                Text(log.date, style: .date)
                    .scaledFont(size: 12)
                    .foregroundColor(Theme.textSecondary)
            }

            Spacer()

            Text(log.isCompleted ? "Completo" : "Parcial")
                .scaledFont(size: 12, weight: .semibold)
                .foregroundColor(statusColor)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(statusColor.opacity(0.15))
                .cornerRadius(8)
        }
    }

    private var statusColor: Color { log.isCompleted ? Theme.green : Theme.amber }
    private var statusIcon: String { log.isCompleted ? "checkmark.circle.fill" : "circle.dotted" }
}
