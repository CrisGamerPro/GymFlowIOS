import WidgetKit
import SwiftUI

// MARK: - Timeline

struct TodayEntry: TimelineEntry {
    let date: Date
    let snapshot: WidgetSnapshot
}

struct TodayProvider: TimelineProvider {
    func placeholder(in context: Context) -> TodayEntry {
        TodayEntry(date: Date(), snapshot: .preview)
    }

    func getSnapshot(in context: Context, completion: @escaping (TodayEntry) -> Void) {
        let data = context.isPreview ? WidgetSnapshot.preview : WidgetBridge.read()
        completion(TodayEntry(date: Date(), snapshot: data))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<TodayEntry>) -> Void) {
        let entry = TodayEntry(date: Date(), snapshot: WidgetBridge.read())
        // Refresco al cambiar el día: el resto de las actualizaciones las
        // empuja la app con reloadTimelines cuando algo cambia de verdad.
        let nextMidnight = Calendar.current.nextDate(
            after: Date(),
            matching: DateComponents(hour: 0, minute: 1),
            matchingPolicy: .nextTime
        ) ?? Date().addingTimeInterval(3600)

        completion(Timeline(entries: [entry], policy: .after(nextMidnight)))
    }
}

// MARK: - Widget

struct GymFlowTodayWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: WidgetBridge.widgetKind, provider: TodayProvider()) { entry in
            TodayWidgetView(snapshot: entry.snapshot)
                .containerBackground(for: .widget) { WidgetTheme.background }
        }
        .configurationDisplayName("GymFlow")
        .description("Tu rutina de hoy y tu racha.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

// MARK: - Vista

struct TodayWidgetView: View {
    let snapshot: WidgetSnapshot
    @Environment(\.widgetFamily) private var family

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            header

            Spacer(minLength: 6)

            if snapshot.hasActiveWorkout {
                activeWorkout
            } else if snapshot.todayRoutines.isEmpty {
                restDay
            } else {
                routineList
            }

            Spacer(minLength: 0)
        }
    }

    // MARK: Secciones

    private var header: some View {
        HStack(spacing: 6) {
            Text("🏋️").font(.system(size: 13))
            Text("HOY")
                .font(.system(size: 11, weight: .heavy))
                .foregroundStyle(WidgetTheme.textSecondary)
            Spacer()
            if snapshot.streak > 0 {
                Text("\(snapshot.streak)🔥")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(WidgetTheme.amber)
            }
        }
    }

    private var activeWorkout: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(snapshot.activeRoutineName ?? "Entrenando")
                .font(.system(size: 15, weight: .bold))
                .foregroundStyle(WidgetTheme.text)
                .lineLimit(2)

            Text("En curso · \(Int(snapshot.activeProgress * 100))%")
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(WidgetTheme.green)

            ProgressView(value: snapshot.activeProgress)
                .tint(WidgetTheme.amber)
        }
    }

    private var restDay: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("🌟").font(.system(size: 20))
            Text("Día de descanso")
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(WidgetTheme.text)
            if snapshot.completedThisWeek > 0 {
                Text("\(snapshot.completedThisWeek) esta semana")
                    .font(.system(size: 11))
                    .foregroundStyle(WidgetTheme.textSecondary)
            }
        }
    }

    private var routineList: some View {
        VStack(alignment: .leading, spacing: 5) {
            ForEach(snapshot.todayRoutines.prefix(maxRoutines)) { routine in
                RoutineRow(routine: routine, compact: family == .systemSmall)
            }

            let extra = snapshot.todayRoutines.count - maxRoutines
            if extra > 0 {
                Text("+\(extra) más")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(WidgetTheme.textSecondary)
            }
        }
    }

    private var maxRoutines: Int { family == .systemSmall ? 2 : 3 }
}

private struct RoutineRow: View {
    let routine: WidgetSnapshot.RoutineEntry
    let compact: Bool

    var body: some View {
        HStack(spacing: 7) {
            Text(routine.icon).font(.system(size: compact ? 13 : 15))

            VStack(alignment: .leading, spacing: 1) {
                Text(routine.name)
                    .font(.system(size: compact ? 12 : 13, weight: .bold))
                    .foregroundStyle(WidgetTheme.text)
                    .lineLimit(1)

                if !compact {
                    Text("\(routine.exerciseCount) ejercicios")
                        .font(.system(size: 10))
                        .foregroundStyle(WidgetTheme.textSecondary)
                }
            }

            Spacer(minLength: 2)

            if let minutes = routine.timeMinutes {
                Text(timeLabel(minutes))
                    .font(.system(size: compact ? 10 : 11, weight: .semibold))
                    .foregroundStyle(WidgetTheme.amber)
            }
        }
        .padding(.vertical, compact ? 3 : 5)
        .padding(.horizontal, 7)
        .background(Color(hex: routine.colorHex).opacity(0.16))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    private func timeLabel(_ minutes: Int) -> String {
        String(format: "%02d:%02d", minutes / 60, minutes % 60)
    }
}

// MARK: - Paleta del widget
//
// El widget no comparte Theme.swift con la app (está en la carpeta del target
// principal), así que replica los colores que necesita.

enum WidgetTheme {
    static let background = Color(hex: "#111113")
    static let text = Color(hex: "#F5F4F2")
    static let textSecondary = Color(hex: "#F5F4F2").opacity(0.55)
    static let amber = Color(hex: "#E8A135")
    static let green = Color(hex: "#32D74B")
}

extension Color {
    /// Igual que Color+Hex.swift de la app, duplicado porque el widget es
    /// otro target y no ve esa extensión.
    init(hex: String) {
        let cleaned = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var value: UInt64 = 0
        Scanner(string: cleaned).scanHexInt64(&value)

        let r, g, b: Double
        switch cleaned.count {
        case 6:
            r = Double((value & 0xFF0000) >> 16) / 255
            g = Double((value & 0x00FF00) >> 8) / 255
            b = Double(value & 0x0000FF) / 255
        case 3:
            r = Double((value & 0xF00) >> 8) / 15
            g = Double((value & 0x0F0) >> 4) / 15
            b = Double(value & 0x00F) / 15
        default:
            r = 1; g = 1; b = 1
        }
        self.init(.sRGB, red: r, green: g, blue: b, opacity: 1)
    }
}

// MARK: - Datos de muestra para la galería de widgets

extension WidgetSnapshot {
    static let preview = WidgetSnapshot(
        generatedAt: Date(),
        streak: 5,
        completedThisWeek: 3,
        totalRoutines: 4,
        todayRoutines: [
            RoutineEntry(id: "1", name: "Piernas", icon: "🦵",
                         colorHex: "#FF453A", exerciseCount: 6, timeMinutes: 7 * 60),
            RoutineEntry(id: "2", name: "Core", icon: "🫀",
                         colorHex: "#4A9EFF", exerciseCount: 4, timeMinutes: 19 * 60),
        ],
        hasActiveWorkout: false,
        activeRoutineName: nil,
        activeProgress: 0
    )
}
