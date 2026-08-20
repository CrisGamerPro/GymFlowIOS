import Foundation
import SwiftData

// MARK: - Tipos

/// Un punto de la historia de un ejercicio: una sesión donde se hizo.
struct ExerciseHistoryPoint: Identifiable {
    let id: UUID
    let date: Date
    let maxWeight: Double
    let volume: Double
    let totalReps: Int
    let setsCompleted: Int
    let estimatedOneRepMax: Double
}

/// Marcas personales de un ejercicio.
struct PersonalRecords {
    var maxWeight: Double = 0
    var maxWeightDate: Date?
    var maxVolume: Double = 0
    var maxVolumeDate: Date?
    var maxReps: Int = 0
    var maxRepsDate: Date?
    var bestOneRepMax: Double = 0

    var hasAny: Bool { maxWeight > 0 || maxVolume > 0 || maxReps > 0 }
}

/// Récords batidos al terminar un entrenamiento, para celebrarlos.
struct BrokenRecord: Identifiable {
    enum Kind { case weight, volume, reps }

    let id = UUID()
    let exerciseName: String
    let kind: Kind
    let newValue: Double
    let previousValue: Double

    var improvement: Double { newValue - previousValue }

    var label: String {
        let en = AppLanguage.current == .english
        switch kind {
        case .weight: return en ? "Max weight"  : "Peso máximo"
        case .volume: return en ? "Max volume"  : "Volumen máximo"
        case .reps:   return en ? "Most reps"   : "Más repeticiones"
        }
    }

    var valueLabel: String {
        switch kind {
        case .weight: return "\(formatted(newValue)) kg"
        case .volume: return "\(formatted(newValue)) kg"
        case .reps:   return "\(Int(newValue))"
        }
    }

    private func formatted(_ v: Double) -> String {
        v == v.rounded() ? String(Int(v)) : String(format: "%.1f", v)
    }
}

// MARK: - Servicio

struct PersonalRecordService {

    /// Historial de un ejercicio, más antiguo primero. Solo sesiones donde se
    /// completó al menos una serie: las abandonadas no dicen nada del progreso.
    static func history(for exerciseId: String, in context: ModelContext) -> [ExerciseHistoryPoint] {
        let logs = fetchExerciseLogs(exerciseId: exerciseId, in: context)
        return logs.compactMap { log -> ExerciseHistoryPoint? in
            guard let date = log.workoutLog?.date, log.setsCompleted > 0 else { return nil }
            return ExerciseHistoryPoint(
                id: log.id, date: date,
                maxWeight: log.maxWeight, volume: log.totalVolume,
                totalReps: log.totalReps, setsCompleted: log.setsCompleted,
                estimatedOneRepMax: log.bestEstimatedOneRepMax
            )
        }
        .sorted { $0.date < $1.date }
    }

    /// Marcas personales de un ejercicio. `excluding` sirve para comparar
    /// contra el pasado sin contar la sesión que se acaba de guardar.
    static func records(for exerciseId: String, in context: ModelContext,
                        excluding excludedLogId: UUID? = nil) -> PersonalRecords {
        let logs = fetchExerciseLogs(exerciseId: exerciseId, in: context)
            .filter { $0.id != excludedLogId }

        var pr = PersonalRecords()
        for log in logs {
            guard let date = log.workoutLog?.date, log.setsCompleted > 0 else { continue }
            if log.maxWeight > pr.maxWeight {
                pr.maxWeight = log.maxWeight
                pr.maxWeightDate = date
            }
            if log.totalVolume > pr.maxVolume {
                pr.maxVolume = log.totalVolume
                pr.maxVolumeDate = date
            }
            if log.totalReps > pr.maxReps {
                pr.maxReps = log.totalReps
                pr.maxRepsDate = date
            }
            pr.bestOneRepMax = max(pr.bestOneRepMax, log.bestEstimatedOneRepMax)
        }
        return pr
    }

    /// Último peso usado por ejercicio, para precargar el siguiente
    /// entrenamiento. Solo mira series completadas con carga declarada.
    static func lastUsedWeights(in context: ModelContext) -> [String: Double] {
        var result: [String: Double] = [:]
        var latestDate: [String: Date] = [:]

        let descriptor = FetchDescriptor<ExerciseLog>()
        guard let logs = try? context.fetch(descriptor) else { return [:] }

        for log in logs {
            guard let date = log.workoutLog?.date, log.maxWeight > 0 else { continue }
            if let known = latestDate[log.exerciseId], known >= date { continue }
            latestDate[log.exerciseId] = date
            result[log.exerciseId] = log.maxWeight
        }
        return result
    }

    /// Compara los registros recién guardados contra el historial anterior.
    /// Devuelve solo mejoras reales — igualar una marca no es batirla.
    static func detectBrokenRecords(in workoutLog: WorkoutLog,
                                    context: ModelContext) -> [BrokenRecord] {
        var broken: [BrokenRecord] = []

        for exLog in workoutLog.exerciseLogs where exLog.setsCompleted > 0 {
            let previous = records(for: exLog.exerciseId, in: context, excluding: exLog.id)
            let name = ExerciseCatalog.displayName(id: exLog.exerciseId, storedName: exLog.exerciseName)

            // Sin carga declarada no hay récord de peso ni de volumen que valga.
            if exLog.maxWeight > 0, exLog.maxWeight > previous.maxWeight {
                broken.append(BrokenRecord(exerciseName: name, kind: .weight,
                                           newValue: exLog.maxWeight,
                                           previousValue: previous.maxWeight))
            } else if exLog.totalVolume > 0, exLog.totalVolume > previous.maxVolume {
                // El volumen solo se reporta si no hubo récord de peso: si
                // subiste la carga, ese es el titular, no el volumen.
                broken.append(BrokenRecord(exerciseName: name, kind: .volume,
                                           newValue: exLog.totalVolume,
                                           previousValue: previous.maxVolume))
            } else if exLog.maxWeight == 0, exLog.totalReps > previous.maxReps, previous.maxReps > 0 {
                // Ejercicios de peso corporal: la marca son las repeticiones.
                broken.append(BrokenRecord(exerciseName: name, kind: .reps,
                                           newValue: Double(exLog.totalReps),
                                           previousValue: Double(previous.maxReps)))
            }
        }
        return broken
    }

    // MARK: - Privado

    private static func fetchExerciseLogs(exerciseId: String, in context: ModelContext) -> [ExerciseLog] {
        let descriptor = FetchDescriptor<ExerciseLog>(
            predicate: #Predicate { $0.exerciseId == exerciseId }
        )
        return (try? context.fetch(descriptor)) ?? []
    }
}
