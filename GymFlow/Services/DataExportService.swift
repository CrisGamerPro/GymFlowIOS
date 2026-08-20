import Foundation
import SwiftData

// MARK: - Backup Codable types (v2 — native app format)

struct GymFlowBackup: Codable {
    var version: Int = 2
    var exportedAt: String
    var appVersion: String
    var routines: [BackupRoutine]
    var workoutLogs: [BackupWorkoutLog]
}

struct BackupRoutine: Codable {
    var id: String
    var name: String
    var desc: String
    var colorHex: String
    var icon: String
    var days: [Int]
    var time: String?       // "HH:mm" or nil
    var exercises: [BackupExercise]
}

struct BackupExercise: Codable {
    var id: String
    var name: String
    var icon: String
    var category: String
    var unit: String
    var sets: Int
    var defaultValue: Int
    var order: Int
    // Agregados con el registro de carga. Opcionales para poder leer
    // backups v2 hechos antes de esa función.
    var defaultWeight: Double?
    var restSeconds: Int?
}

struct BackupWorkoutLog: Codable {
    var id: String
    var routineId: String
    var routineName: String
    var date: String        // ISO8601
    var startedAt: String?
    var completedAt: String?
    var isCompleted: Bool
    var exerciseLogs: [BackupExerciseLog]
}

struct BackupExerciseLog: Codable {
    var exerciseId: String
    var exerciseName: String
    var setsCompleted: Int
    var totalSets: Int
    var value: Int
    var isCompleted: Bool
    /// Detalle serie a serie. Opcional: los backups anteriores no lo traen.
    var setRecords: [BackupSetRecord]?
}

struct BackupSetRecord: Codable {
    var weight: Double
    var reps: Int
    var isCompleted: Bool
}

enum DataExportError: LocalizedError {
    case unsupportedVersion(Int)
    case encodingFailed(Error)
    case writeFailed(Error)

    var errorDescription: String? {
        switch self {
        case .unsupportedVersion(let v): return "Formato de archivo no compatible (versión \(v))."
        case .encodingFailed(let e): return "No se pudo codificar: \(e.localizedDescription)"
        case .writeFailed(let e): return "No se pudo escribir el archivo: \(e.localizedDescription)"
        }
    }
}

// MARK: - Service

final class DataExportService {
    static let shared = DataExportService()
    private init() {}

    private let iso = ISO8601DateFormatter()
    // locale POSIX: sin esto, un usuario con calendario budista/árabe
    // generaría "HH:mm" con dígitos no arábigos y el parseo fallaría.
    private let timeFmt: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US_POSIX")
        f.dateFormat = "HH:mm"
        return f
    }()
    private let fileFmt: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US_POSIX")
        f.dateFormat = "yyyy-MM-dd"
        return f
    }()

    // MARK: Export

    func createBackup(routines: [Routine], logs: [WorkoutLog]) -> GymFlowBackup {
        let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"

        let backupRoutines = routines.map { r -> BackupRoutine in
            let exs = r.orderedExercises.map { ex -> BackupExercise in
                BackupExercise(id: ex.id, name: ex.name, icon: ex.icon, category: ex.category,
                               unit: ex.unit, sets: ex.sets, defaultValue: ex.defaultValue,
                               order: ex.order, defaultWeight: ex.defaultWeight,
                               restSeconds: ex.restSeconds)
            }
            return BackupRoutine(
                id: r.id.uuidString, name: r.name, desc: r.desc, colorHex: r.colorHex,
                icon: r.icon, days: r.days,
                time: r.time.map { timeFmt.string(from: $0) },
                exercises: exs
            )
        }

        let backupLogs = logs.map { log -> BackupWorkoutLog in
            let exLogs = log.exerciseLogs.map { el -> BackupExerciseLog in
                BackupExerciseLog(
                    exerciseId: el.exerciseId, exerciseName: el.exerciseName,
                    setsCompleted: el.setsCompleted, totalSets: el.totalSets,
                    value: el.value, isCompleted: el.isCompleted,
                    setRecords: el.setRecords.map {
                        BackupSetRecord(weight: $0.weight, reps: $0.reps, isCompleted: $0.isCompleted)
                    }
                )
            }
            return BackupWorkoutLog(
                id: log.id.uuidString, routineId: log.routineId.uuidString,
                routineName: log.routineName,
                date: iso.string(from: log.date),
                startedAt: log.startedAt.map { iso.string(from: $0) },
                completedAt: log.completedAt.map { iso.string(from: $0) },
                isCompleted: log.isCompleted, exerciseLogs: exLogs
            )
        }

        return GymFlowBackup(
            exportedAt: iso.string(from: Date()),
            appVersion: appVersion,
            routines: backupRoutines,
            workoutLogs: backupLogs
        )
    }

    func saveToTemporaryFile(_ backup: GymFlowBackup) throws -> URL {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let data: Data
        do { data = try encoder.encode(backup) } catch { throw DataExportError.encodingFailed(error) }

        let dateStr = fileFmt.string(from: Date())
        let filename = "gymflow-backup-\(dateStr).json"
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(filename)
        do { try data.write(to: url, options: .atomic) } catch { throw DataExportError.writeFailed(error) }
        return url
    }

    // MARK: Import (v2 only — v1/PWA handled by DataMigrationService)

    func importBackup(from url: URL, into context: ModelContext) throws -> MigrationResult {
        let data = try Data(contentsOf: url)
        let decoder = JSONDecoder()
        let backup = try decoder.decode(GymFlowBackup.self, from: data)

        guard backup.version == 2 else {
            throw DataExportError.unsupportedVersion(backup.version)
        }

        var importedRoutines = 0
        var importedLogs = 0

        for br in backup.routines {
            let routine = Routine(
                name: br.name, desc: br.desc, colorHex: br.colorHex,
                icon: br.icon, days: br.days,
                time: br.time.flatMap { timeFmt.date(from: $0) }
            )
            context.insert(routine)

            for bex in br.exercises.sorted(by: { $0.order < $1.order }) {
                let ex = Exercise(
                    id: bex.id, name: bex.name, icon: bex.icon, category: bex.category,
                    unit: bex.unit, sets: bex.sets, defaultValue: bex.defaultValue, order: bex.order,
                    defaultWeight: bex.defaultWeight ?? 0, restSeconds: bex.restSeconds ?? 0
                )
                ex.routine = routine
                routine.exercises.append(ex)
                context.insert(ex)
            }
            importedRoutines += 1
        }

        for bl in backup.workoutLogs {
            guard let routineId = UUID(uuidString: bl.routineId) else { continue }
            let log = WorkoutLog(
                routineId: routineId,
                routineName: bl.routineName,
                date: iso.date(from: bl.date) ?? Date(),
                startedAt: bl.startedAt.flatMap { iso.date(from: $0) },
                completedAt: bl.completedAt.flatMap { iso.date(from: $0) },
                isCompleted: bl.isCompleted
            )
            context.insert(log)

            for bel in bl.exerciseLogs {
                let exLog = ExerciseLog(
                    exerciseId: bel.exerciseId, exerciseName: bel.exerciseName,
                    setsCompleted: bel.setsCompleted, totalSets: bel.totalSets,
                    value: bel.value, isCompleted: bel.isCompleted,
                    setRecords: (bel.setRecords ?? []).map {
                        SetRecord(weight: $0.weight, reps: $0.reps, isCompleted: $0.isCompleted)
                    }
                )
                exLog.workoutLog = log
                log.exerciseLogs.append(exLog)
                context.insert(exLog)
            }
            importedLogs += 1
        }

        try? context.save()
        return MigrationResult(importedRoutines: importedRoutines, importedLogs: importedLogs)
    }

    // Detect v1 vs v2 and dispatch to the right importer
    func smartImport(from url: URL, into context: ModelContext) throws -> MigrationResult {
        let data = try Data(contentsOf: url)
        if let obj = try? JSONDecoder().decode(GymFlowBackup.self, from: data), obj.version == 2 {
            return try importBackup(from: url, into: context)
        }
        // Fall back to v1 PWA format
        return try DataMigrationService.importData(from: url, into: context)
    }
}
