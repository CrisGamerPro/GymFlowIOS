import Foundation
import SwiftData

/// Formato real exportado por la PWA (ver `exportData()` en index.html).
/// Los campos coinciden con el objeto interno de rutina de la PWA, no con
/// nombres "ideales" — por eso `id` es un string (uid() de la PWA) y el
/// progreso referencia `routineId` + `ts` (timestamp epoch en ms).
private struct ExportedExercise: Codable {
    let id: String
    let name: String
    let icon: String
    let unit: String
    let sets: Int
    let value: Int
}

private struct ExportedRoutine: Codable {
    let id: String
    let name: String
    let desc: String?
    let color: String?
    let icon: String?
    let days: [Int]
    let time: String?
    let exercises: [ExportedExercise]?
}

private struct ExportedProgress: Codable {
    let routineId: String
    let date: String
    let ts: Double?
}

private struct ExportedData: Codable {
    let version: Int
    let exportedAt: String?
    let routines: [ExportedRoutine]
    let progress: [ExportedProgress]?
}

struct MigrationResult {
    let importedRoutines: Int
    let importedLogs: Int
}

enum DataMigrationError: LocalizedError {
    case invalidFormat
    case unsupportedVersion(Int)

    var errorDescription: String? {
        let english = AppLanguage.current == .english
        switch self {
        case .invalidFormat:
            return english
                ? "The file doesn't match GymFlow's expected export format."
                : "El archivo no tiene el formato esperado de exportación de GymFlow."
        case .unsupportedVersion(let version):
            return english
                ? "Unsupported export version (\(version))."
                : "Versión de exportación no soportada (\(version))."
        }
    }
}

struct DataMigrationService {
    /// Importa un archivo `GymFlow_Export.json` generado por la PWA.
    /// Crea las rutinas y ejercicios como nuevos, y reconstruye el historial
    /// de entrenamientos completados (sin detalle por serie, ya que la PWA
    /// solo registraba la rutina completa como "hecha").
    static func importData(from url: URL, into modelContext: ModelContext) throws -> MigrationResult {
        let data = try Data(contentsOf: url)

        let export: ExportedData
        do {
            export = try JSONDecoder().decode(ExportedData.self, from: data)
        } catch {
            throw DataMigrationError.invalidFormat
        }

        guard export.version == 1 else {
            throw DataMigrationError.unsupportedVersion(export.version)
        }

        // Mapa del id de la PWA (string) → Routine recién creada, para poder
        // enlazar el historial de progreso con la rutina correcta.
        var routineIdMap: [String: Routine] = [:]

        for exported in export.routines {
            let routine = Routine(
                name: exported.name,
                desc: exported.desc ?? "",
                colorHex: exported.color ?? "#E8A135",
                icon: exported.icon ?? "🏋️",
                days: exported.days,
                time: parseTime(exported.time)
            )
            modelContext.insert(routine)

            for (index, ex) in (exported.exercises ?? []).enumerated() {
                let category = ExerciseCatalog.all.first(where: { $0.id == ex.id })?.category ?? "Personalizado"
                let exercise = Exercise(
                    id: ex.id,
                    name: ex.name,
                    icon: ex.icon,
                    category: category,
                    unit: ex.unit,
                    sets: max(1, ex.sets),
                    defaultValue: ex.value,
                    order: index
                )
                exercise.routine = routine
                routine.exercises.append(exercise)
            }

            routineIdMap[exported.id] = routine
        }

        var importedLogs = 0
        for entry in export.progress ?? [] {
            guard let routine = routineIdMap[entry.routineId] else { continue }
            let date = parseDate(entry.date) ?? Date()
            let completedAt = entry.ts.map { Date(timeIntervalSince1970: $0 / 1000) } ?? date

            let workoutLog = WorkoutLog(
                routineId: routine.id,
                routineName: routine.name,
                date: date,
                completedAt: completedAt,
                isCompleted: true
            )
            modelContext.insert(workoutLog)
            importedLogs += 1
        }

        try modelContext.save()
        return MigrationResult(importedRoutines: export.routines.count, importedLogs: importedLogs)
    }

    private static func parseTime(_ timeString: String?) -> Date? {
        guard let timeString else { return nil }
        let parts = timeString.split(separator: ":")
        guard parts.count == 2, let hour = Int(parts[0]), let minute = Int(parts[1]) else { return nil }
        return Calendar.current.date(from: DateComponents(hour: hour, minute: minute))
    }

    private static func parseDate(_ dateString: String) -> Date? {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.timeZone = .current
        return formatter.date(from: dateString)
    }
}
