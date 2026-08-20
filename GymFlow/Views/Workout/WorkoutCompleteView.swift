import SwiftUI

/// Resumen al terminar: tiempo, series, volumen y los récords batidos.
struct WorkoutCompleteView: View {
    let routineName: String
    let time: TimeInterval
    let volume: Double
    let setsDone: Int
    let records: [BrokenRecord]
    let onFinish: () -> Void

    @State private var showContent = false

    var body: some View {
        ScrollView {
            VStack(spacing: 22) {
                celebration
                stats

                if !records.isEmpty {
                    recordsCard
                }

                finishButton
            }
            .padding()
            .padding(.top, 20)
        }
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.1)) {
                showContent = true
            }
        }
    }

    // MARK: - Secciones

    private var celebration: some View {
        VStack(spacing: 14) {
            Text(records.isEmpty ? "🎉" : "🏆")
                .scaledFont(size: 72)
                .scaleEffect(showContent ? 1.0 : 0.5)
                .opacity(showContent ? 1.0 : 0)

            VStack(spacing: 6) {
                Text(headline)
                    .scaledFont(size: 24, weight: .heavy)
                    .foregroundColor(Theme.text)
                    .multilineTextAlignment(.center)
                Text(routineName)
                    .scaledFont(size: 17, weight: .bold)
                    .foregroundColor(Theme.amber)
            }
            .offset(y: showContent ? 0 : 20)
            .opacity(showContent ? 1.0 : 0)
        }
        .accessibilityElement(children: .combine)
    }

    private var headline: String {
        let en = AppLanguage.current == .english
        if !records.isEmpty {
            return en ? "New record!" : "¡Récord nuevo!"
        }
        return en ? "Workout complete!" : "¡Entrenamiento completado!"
    }

    private var stats: some View {
        HStack(spacing: 10) {
            SummaryTile(value: formatTime(time), label: "Tiempo", tint: Theme.amber)
            SummaryTile(value: "\(setsDone)", label: "Series", tint: Theme.blue)
            if volume > 0 {
                SummaryTile(value: volumeLabel, label: "Volumen", tint: Theme.green)
            }
        }
        .offset(y: showContent ? 0 : 20)
        .opacity(showContent ? 1.0 : 0)
    }

    private var recordsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label(recordsTitle, systemImage: "trophy.fill")
                .scaledFont(size: 15, weight: .bold)
                .foregroundColor(Theme.amber)

            ForEach(records) { record in
                RecordRow(record: record)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(Theme.amber.opacity(0.1))
        .cornerRadius(16)
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Theme.amber.opacity(0.3), lineWidth: 1))
        .offset(y: showContent ? 0 : 20)
        .opacity(showContent ? 1.0 : 0)
    }

    private var recordsTitle: String {
        let en = AppLanguage.current == .english
        if records.count == 1 { return en ? "1 record broken" : "1 récord batido" }
        return en ? "\(records.count) records broken" : "\(records.count) récords batidos"
    }

    private var finishButton: some View {
        Button(action: onFinish) {
            Text("Terminar")
                .scaledFont(size: 18, weight: .bold)
                .foregroundColor(.black)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(Theme.amber)
                .cornerRadius(16)
        }
        .padding(.horizontal, 20)
        .padding(.top, 8)
        .padding(.bottom, 30)
        .offset(y: showContent ? 0 : 20)
        .opacity(showContent ? 1.0 : 0)
    }

    // MARK: - Formato

    private var volumeLabel: String {
        volume >= 1000
            ? String(format: "%.1ft", volume / 1000)
            : "\(Int(volume))kg"
    }

    private func formatTime(_ t: TimeInterval) -> String {
        String(format: "%02d:%02d", Int(t) / 60, Int(t) % 60)
    }
}

// MARK: - Piezas

private struct SummaryTile: View {
    let value: String
    let label: LocalizedStringKey
    let tint: Color

    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(size: 22, weight: .heavy).monospacedDigit())
                .foregroundColor(tint)
                .minimumScaleFactor(0.6)
                .lineLimit(1)
            Text(label)
                .scaledFont(size: 10, weight: .medium)
                .foregroundColor(Theme.textSecondary)
                .textCase(.uppercase)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .glassCard()
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(label)
        .accessibilityValue(value)
    }
}

private struct RecordRow: View {
    let record: BrokenRecord

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "arrow.up.circle.fill")
                .scaledFont(size: 17)
                .foregroundColor(Theme.green)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 1) {
                Text(record.exerciseName)
                    .scaledFont(size: 14, weight: .bold)
                    .foregroundColor(Theme.text)
                Text(record.label)
                    .scaledFont(size: 11)
                    .foregroundColor(Theme.textSecondary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 1) {
                Text(record.valueLabel)
                    .scaledFont(size: 15, weight: .heavy)
                    .foregroundColor(Theme.amber)
                if record.previousValue > 0 {
                    Text(deltaLabel)
                        .scaledFont(size: 10, weight: .semibold)
                        .foregroundColor(Theme.green)
                }
            }
        }
        .accessibilityElement(children: .combine)
    }

    private var deltaLabel: String {
        let d = record.improvement
        let formatted = d == d.rounded() ? String(Int(d)) : String(format: "%.1f", d)
        return "+\(formatted)"
    }
}
