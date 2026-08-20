import Foundation
import SwiftData
import WidgetKit

/// Publica el estado de la app en el App Group para que el widget de pantalla
/// de inicio lo lea. Se llama al arrancar, al terminar un entrenamiento y al
/// crear/editar/borrar rutinas.
@MainActor
struct WidgetSnapshotService {

    static func refresh(context: ModelContext) {
        guard let url = WidgetBridge.snapshotURL else {
            // Sin App Group configurado el widget no puede leer nada.
            // No es fatal: la app funciona igual, solo el widget queda vacío.
            return
        }

        let routines = (try? context.fetch(FetchDescriptor<Routine>())) ?? []
        let logs = (try? context.fetch(FetchDescriptor<WorkoutLog>())) ?? []

        let snapshot = buildSnapshot(routines: routines, logs: logs)

        guard let data = try? JSONEncoder.snapshotEncoder.encode(snapshot) else { return }
        try? data.write(to: url, options: .atomic)

        WidgetCenter.shared.reloadTimelines(ofKind: WidgetBridge.widgetKind)
    }

    // MARK: - Construcción

    private static func buildSnapshot(routines: [Routine], logs: [WorkoutLog]) -> WidgetSnapshot {
        let calendar = Calendar.current
        let session = ActiveWorkoutSession.shared

        let today = todayGymFlowWeekday()
        let todayEntries = routines
            .filter { $0.days.contains(today) }
            .map { routine -> WidgetSnapshot.RoutineEntry in
                WidgetSnapshot.RoutineEntry(
                    id: routine.id.uuidString,
                    name: routine.name,
                    icon: routine.icon,
                    colorHex: routine.colorHex,
                    exerciseCount: routine.exercises.count,
                    timeMinutes: routine.time.map { date in
                        let c = calendar.dateComponents([.hour, .minute], from: date)
                        return (c.hour ?? 0) * 60 + (c.minute ?? 0)
                    }
                )
            }
            // Las que tienen hora primero y en orden; las sin hora al final.
            .sorted { a, b in
                switch (a.timeMinutes, b.timeMinutes) {
                case let (x?, y?): return x < y
                case (nil, _?):    return false
                case (_?, nil):    return true
                default:           return a.name < b.name
                }
            }

        return WidgetSnapshot(
            generatedAt: Date(),
            streak: WorkoutStreak.calculate(from: logs),
            completedThisWeek: completedThisWeek(logs: logs, calendar: calendar),
            totalRoutines: routines.count,
            todayRoutines: todayEntries,
            hasActiveWorkout: session.isActive,
            activeRoutineName: session.routine?.name,
            activeProgress: session.progressPercent
        )
    }

    private static func completedThisWeek(logs: [WorkoutLog], calendar: Calendar) -> Int {
        guard let weekStart = calendar.dateInterval(of: .weekOfYear, for: Date())?.start else { return 0 }
        return logs.filter { $0.isCompleted && $0.date >= weekStart }.count
    }

    private static func todayGymFlowWeekday() -> Int {
        let weekday = Calendar.current.component(.weekday, from: Date())
        return weekday == 1 ? 6 : weekday - 2
    }
}
