import Foundation

/// Datos que la app deja escritos para que el widget los lea.
///
/// Copia idéntica de GymFlow/Models/WidgetSnapshot.swift — con
/// grupos sincronizados de Xcode cada carpeta pertenece a un solo target,
/// mismo patrón que WorkoutActivityAttributes.swift.
///
/// El widget NO puede abrir el store de SwiftData de la app (proceso
/// distinto, y montar el contenedor desde una extensión es frágil). En vez de
/// eso la app publica este JSON en el App Group cada vez que algo cambia.
struct WidgetSnapshot: Codable {
    struct RoutineEntry: Codable, Identifiable {
        var id: String
        var name: String
        var icon: String
        var colorHex: String
        var exerciseCount: Int
        /// Minutos desde medianoche, o nil si la rutina no tiene hora.
        var timeMinutes: Int?
    }

    var generatedAt: Date
    var streak: Int
    var completedThisWeek: Int
    var totalRoutines: Int
    /// Rutinas de hoy, ya ordenadas por hora.
    var todayRoutines: [RoutineEntry]
    /// True si hay un entrenamiento en curso ahora mismo.
    var hasActiveWorkout: Bool
    var activeRoutineName: String?
    var activeProgress: Double

    static let empty = WidgetSnapshot(
        generatedAt: .distantPast, streak: 0, completedThisWeek: 0,
        totalRoutines: 0, todayRoutines: [], hasActiveWorkout: false,
        activeRoutineName: nil, activeProgress: 0
    )
}

/// Configuración compartida del App Group. Si cambias el identificador,
/// cámbialo TAMBIÉN en GymFlow.entitlements y GymFlowWidget.entitlements.
enum WidgetBridge {
    static let appGroupId = "group.cl.subject.gymflow.app"
    static let snapshotFilename = "widget-snapshot.json"
    static let widgetKind = "GymFlowTodayWidget"

    static var snapshotURL: URL? {
        FileManager.default
            .containerURL(forSecurityApplicationGroupIdentifier: appGroupId)?
            .appendingPathComponent(snapshotFilename)
    }

    static func read() -> WidgetSnapshot {
        guard let url = snapshotURL,
              let data = try? Data(contentsOf: url),
              let snapshot = try? JSONDecoder.snapshotDecoder.decode(WidgetSnapshot.self, from: data)
        else { return .empty }
        return snapshot
    }
}

extension JSONDecoder {
    static var snapshotDecoder: JSONDecoder {
        let d = JSONDecoder()
        d.dateDecodingStrategy = .iso8601
        return d
    }
}

extension JSONEncoder {
    static var snapshotEncoder: JSONEncoder {
        let e = JSONEncoder()
        e.dateEncodingStrategy = .iso8601
        return e
    }
}
