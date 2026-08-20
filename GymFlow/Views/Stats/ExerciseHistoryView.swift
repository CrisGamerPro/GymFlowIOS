import SwiftUI
import SwiftData
import Charts

/// Progresión de un ejercicio en el tiempo, con sus marcas personales.
struct ExerciseHistoryView: View {
    let exerciseId: String
    let storedName: String

    @Environment(\.modelContext) private var modelContext
    @State private var points: [ExerciseHistoryPoint] = []
    @State private var records = PersonalRecords()
    @State private var metric: Metric = .weight

    enum Metric: String, CaseIterable, Identifiable {
        case weight, volume, reps

        var id: String { rawValue }

        var label: String {
            let en = AppLanguage.current == .english
            switch self {
            case .weight: return en ? "Weight" : "Peso"
            case .volume: return en ? "Volume" : "Volumen"
            case .reps:   return en ? "Reps"   : "Reps"
            }
        }
    }

    private var displayName: String {
        ExerciseCatalog.displayName(id: exerciseId, storedName: storedName)
    }

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()

            if points.isEmpty {
                emptyState
            } else {
                ScrollView {
                    VStack(spacing: 20) {
                        recordsRow
                        chartCard
                        sessionsCard
                    }
                    .padding()
                }
            }
        }
        .navigationTitle(displayName)
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(Theme.cardBackground, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .onAppear(perform: load)
    }

    private func load() {
        points = PersonalRecordService.history(for: exerciseId, in: modelContext)
        records = PersonalRecordService.records(for: exerciseId, in: modelContext)
        // Si nunca se registró carga, el gráfico de peso saldría plano en 0.
        if records.maxWeight == 0 { metric = .reps }
    }

    // MARK: - Estados

    private var emptyState: some View {
        VStack(spacing: 10) {
            Text("📈").scaledFont(size: 44).opacity(0.7)
            Text("Sin historial todavía")
                .scaledFont(size: 17, weight: .bold)
                .foregroundColor(Theme.text)
            Text("Haz este ejercicio en un entrenamiento y aquí verás tu progresión.")
                .scaledFont(size: 14)
                .foregroundColor(Theme.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
    }

    private var recordsRow: some View {
        HStack(spacing: 10) {
            RecordTile(value: records.maxWeight > 0 ? "\(fmt(records.maxWeight))kg" : "—",
                       label: "Máximo", date: records.maxWeightDate, tint: Theme.amber)
            RecordTile(value: records.maxReps > 0 ? "\(records.maxReps)" : "—",
                       label: "Más reps", date: records.maxRepsDate, tint: Theme.blue)
            RecordTile(value: records.bestOneRepMax > 0 ? "\(fmt(records.bestOneRepMax))kg" : "—",
                       label: "1RM est.", date: nil, tint: Theme.green)
        }
    }

    private var chartCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Picker("Métrica", selection: $metric) {
                ForEach(Metric.allCases) { m in
                    Text(m.label).tag(m)
                }
            }
            .pickerStyle(.segmented)

            Chart(points) { point in
                LineMark(
                    x: .value("Fecha", point.date),
                    y: .value(metric.label, metricValue(point))
                )
                .foregroundStyle(Theme.amber)
                .interpolationMethod(.monotone)

                PointMark(
                    x: .value("Fecha", point.date),
                    y: .value(metric.label, metricValue(point))
                )
                .foregroundStyle(Theme.amber)
                .symbolSize(45)

                AreaMark(
                    x: .value("Fecha", point.date),
                    y: .value(metric.label, metricValue(point))
                )
                .foregroundStyle(
                    LinearGradient(
                        colors: [Theme.amber.opacity(0.28), Theme.amber.opacity(0.02)],
                        startPoint: .top, endPoint: .bottom
                    )
                )
                .interpolationMethod(.monotone)
            }
            .chartXAxis {
                AxisMarks(values: .automatic(desiredCount: 4)) { value in
                    AxisGridLine().foregroundStyle(Color.white.opacity(0.07))
                    AxisValueLabel {
                        if let date = value.as(Date.self) {
                            Text(date, format: .dateTime.day().month(.abbreviated))
                                .scaledFont(size: 10)
                                .foregroundColor(Theme.textSecondary)
                        }
                    }
                }
            }
            .chartYAxis {
                AxisMarks(position: .leading, values: .automatic(desiredCount: 4)) { value in
                    AxisGridLine().foregroundStyle(Color.white.opacity(0.07))
                    AxisValueLabel {
                        if let v = value.as(Double.self) {
                            Text(fmt(v))
                                .scaledFont(size: 10)
                                .foregroundColor(Theme.textSecondary)
                        }
                    }
                }
            }
            .frame(height: 200)
        }
        .padding(16)
        .glassCard()
    }

    private var sessionsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Sesiones")
                .scaledFont(size: 15, weight: .bold)
                .foregroundColor(Theme.text)

            ForEach(points.reversed().prefix(12)) { point in
                HStack(spacing: 10) {
                    Text(point.date, format: .dateTime.day().month(.abbreviated).year())
                        .scaledFont(size: 13)
                        .foregroundColor(Theme.textSecondary)

                    Spacer()

                    if point.maxWeight > 0 {
                        Text("\(fmt(point.maxWeight))kg")
                            .scaledFont(size: 13, weight: .bold)
                            .foregroundColor(Theme.amber)
                    }
                    Text("\(point.setsCompleted)×\(seriesRepLabel(point))")
                        .scaledFont(size: 13, weight: .semibold)
                        .foregroundColor(Theme.text)
                }
                .accessibilityElement(children: .combine)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .glassCard()
    }

    // MARK: - Ayudas

    private func metricValue(_ p: ExerciseHistoryPoint) -> Double {
        switch metric {
        case .weight: return p.maxWeight
        case .volume: return p.volume
        case .reps:   return Double(p.totalReps)
        }
    }

    private func seriesRepLabel(_ p: ExerciseHistoryPoint) -> String {
        guard p.setsCompleted > 0 else { return "0" }
        return String(p.totalReps / p.setsCompleted)
    }

    private func fmt(_ v: Double) -> String {
        v == v.rounded() ? String(Int(v)) : String(format: "%.1f", v)
    }
}

// MARK: - Baldosa de récord

private struct RecordTile: View {
    let value: String
    let label: LocalizedStringKey
    let date: Date?
    let tint: Color

    var body: some View {
        VStack(spacing: 3) {
            Text(value)
                .scaledFont(size: 19, weight: .heavy)
                .foregroundColor(tint)
                .minimumScaleFactor(0.6)
                .lineLimit(1)
            Text(label)
                .scaledFont(size: 10, weight: .medium)
                .foregroundColor(Theme.textSecondary)
                .textCase(.uppercase)
            if let date {
                Text(date, format: .dateTime.day().month(.abbreviated))
                    .scaledFont(size: 9)
                    .foregroundColor(Theme.textSecondary.opacity(0.7))
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .glassCard()
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(label)
        .accessibilityValue(value)
    }
}
