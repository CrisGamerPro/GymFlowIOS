import Foundation
import SwiftData

/// Rutina lista para usar. Los ejercicios se referencian por id del catálogo,
/// así que si el catálogo cambia de nombres o traducciones, las plantillas
/// siguen funcionando.
struct RoutineTemplate: Identifiable {
    struct Item {
        let exerciseId: String
        let sets: Int
        let value: Int
        /// Peso sugerido en kg. 0 = peso corporal o "ajústalo tú".
        let weight: Double

        init(_ exerciseId: String, sets: Int, value: Int, weight: Double = 0) {
            self.exerciseId = exerciseId
            self.sets = sets
            self.value = value
            self.weight = weight
        }
    }

    let id: String
    let nameES: String
    let nameEN: String
    let descES: String
    let descEN: String
    let icon: String
    let colorHex: String
    /// Días sugeridos (0 = lunes). El usuario los puede cambiar al guardar.
    let days: [Int]
    let items: [Item]

    var name: String { AppLanguage.current == .english ? nameEN : nameES }
    var desc: String { AppLanguage.current == .english ? descEN : descES }

    /// Nivel, para agrupar en el selector.
    let level: Level

    enum Level: String, CaseIterable {
        case beginner, intermediate, advanced

        var label: String {
            let en = AppLanguage.current == .english
            switch self {
            case .beginner:     return en ? "Beginner"     : "Principiante"
            case .intermediate: return en ? "Intermediate" : "Intermedio"
            case .advanced:     return en ? "Advanced"     : "Avanzado"
            }
        }
    }
}

struct RoutineTemplates {
    static let all: [RoutineTemplate] = [

        // ─────────── PRINCIPIANTE ───────────

        RoutineTemplate(
            id: "full_body_beginner",
            nameES: "Cuerpo Completo", nameEN: "Full Body",
            descES: "Todo el cuerpo en una sesión. Ideal para empezar con 3 días por semana.",
            descEN: "Whole body in one session. Great starting point at 3 days a week.",
            icon: "💪", colorHex: "#4A9EFF",
            days: [0, 2, 4],
            items: [
                .init("trote", sets: 1, value: 8),
                .init("squat", sets: 3, value: 12),
                .init("flex", sets: 3, value: 10),
                .init("remo", sets: 3, value: 10, weight: 20),
                .init("plancha", sets: 3, value: 30),
                .init("abs", sets: 3, value: 15),
            ],
            level: .beginner
        ),

        RoutineTemplate(
            id: "home_no_equipment",
            nameES: "En Casa Sin Equipo", nameEN: "Home, No Equipment",
            descES: "Solo peso corporal. Sin pesas, sin máquinas, sin excusas.",
            descEN: "Bodyweight only. No weights, no machines, no excuses.",
            icon: "🏠", colorHex: "#32D74B",
            days: [0, 2, 4],
            items: [
                .init("cuerda", sets: 3, value: 2),
                .init("squat", sets: 3, value: 15),
                .init("flex", sets: 3, value: 12),
                .init("lunge", sets: 3, value: 12),
                .init("plancha", sets: 3, value: 40),
                .init("mtn", sets: 3, value: 20),
                .init("burpee", sets: 3, value: 8),
            ],
            level: .beginner
        ),

        RoutineTemplate(
            id: "cardio_core",
            nameES: "Cardio y Core", nameEN: "Cardio & Core",
            descES: "Sesión corta para días de descanso activo.",
            descEN: "Short session for active recovery days.",
            icon: "🔥", colorHex: "#FF9F0A",
            days: [1, 3],
            items: [
                .init("trote", sets: 1, value: 20),
                .init("plancha", sets: 3, value: 45),
                .init("russian", sets: 3, value: 20),
                .init("elevacion", sets: 3, value: 15),
                .init("supman", sets: 3, value: 15),
                .init("espalda_str", sets: 2, value: 45),
            ],
            level: .beginner
        ),

        // ─────────── INTERMEDIO ───────────

        RoutineTemplate(
            id: "push",
            nameES: "Empuje (Push)", nameEN: "Push Day",
            descES: "Pecho, hombro y tríceps. Parte de la rutina Push/Pull/Legs.",
            descEN: "Chest, shoulders and triceps. Part of Push/Pull/Legs.",
            icon: "🏋️", colorHex: "#E8A135",
            days: [0, 3],
            items: [
                .init("bench", sets: 4, value: 10, weight: 40),
                .init("press_inclinado", sets: 3, value: 10, weight: 30),
                .init("shoulder", sets: 3, value: 10, weight: 20),
                .init("aperturas", sets: 3, value: 12, weight: 10),
                .init("tricep", sets: 3, value: 12, weight: 15),
                .init("dips", sets: 3, value: 10),
            ],
            level: .intermediate
        ),

        RoutineTemplate(
            id: "pull",
            nameES: "Tracción (Pull)", nameEN: "Pull Day",
            descES: "Espalda y bíceps. Parte de la rutina Push/Pull/Legs.",
            descEN: "Back and biceps. Part of Push/Pull/Legs.",
            icon: "🧲", colorHex: "#BF5AF2",
            days: [1, 4],
            items: [
                .init("pull", sets: 4, value: 8),
                .init("remo", sets: 4, value: 10, weight: 35),
                .init("jalon", sets: 3, value: 12, weight: 30),
                .init("polea", sets: 3, value: 12, weight: 30),
                .init("face_pull", sets: 3, value: 15, weight: 12),
                .init("bicep", sets: 3, value: 12, weight: 12),
            ],
            level: .intermediate
        ),

        RoutineTemplate(
            id: "legs",
            nameES: "Piernas (Legs)", nameEN: "Leg Day",
            descES: "Cuádriceps, femoral y glúteo. Parte de la rutina Push/Pull/Legs.",
            descEN: "Quads, hamstrings and glutes. Part of Push/Pull/Legs.",
            icon: "🦵", colorHex: "#FF453A",
            days: [2, 5],
            items: [
                .init("squat", sets: 4, value: 10, weight: 50),
                .init("peso", sets: 3, value: 8, weight: 60),
                .init("lunge", sets: 3, value: 12, weight: 16),
                .init("hip_thrust", sets: 4, value: 12, weight: 40),
                .init("ext_quad", sets: 3, value: 15, weight: 30),
                .init("femoral", sets: 3, value: 12, weight: 25),
            ],
            level: .intermediate
        ),

        RoutineTemplate(
            id: "upper",
            nameES: "Torso", nameEN: "Upper Body",
            descES: "Todo el tren superior. Combina con «Pierna» para 4 días.",
            descEN: "Full upper body. Pair with «Lower Body» for a 4-day split.",
            icon: "💪", colorHex: "#5AC8FA",
            days: [0, 3],
            items: [
                .init("bench", sets: 4, value: 10, weight: 40),
                .init("remo", sets: 4, value: 10, weight: 35),
                .init("shoulder", sets: 3, value: 10, weight: 20),
                .init("jalon", sets: 3, value: 12, weight: 30),
                .init("bicep", sets: 3, value: 12, weight: 12),
                .init("tricep", sets: 3, value: 12, weight: 15),
            ],
            level: .intermediate
        ),

        RoutineTemplate(
            id: "lower",
            nameES: "Pierna", nameEN: "Lower Body",
            descES: "Todo el tren inferior más core. Combina con «Torso».",
            descEN: "Full lower body plus core. Pair with «Upper Body».",
            icon: "🦵", colorHex: "#FF6482",
            days: [1, 4],
            items: [
                .init("squat", sets: 4, value: 10, weight: 50),
                .init("peso", sets: 3, value: 8, weight: 60),
                .init("hip_thrust", sets: 3, value: 12, weight: 40),
                .init("lunge", sets: 3, value: 12, weight: 16),
                .init("plancha", sets: 3, value: 45),
                .init("russian", sets: 3, value: 20),
            ],
            level: .intermediate
        ),

        // ─────────── AVANZADO ───────────

        RoutineTemplate(
            id: "hiit_functional",
            nameES: "Funcional HIIT", nameEN: "Functional HIIT",
            descES: "Circuito de alta intensidad. Descansos cortos, ritmo alto.",
            descEN: "High-intensity circuit. Short rests, high pace.",
            icon: "⚡", colorHex: "#FF9F0A",
            days: [1, 4],
            items: [
                .init("cuerda", sets: 3, value: 3),
                .init("kettlebell", sets: 4, value: 15, weight: 16),
                .init("box_jump", sets: 4, value: 10),
                .init("battle_ropes", sets: 4, value: 30),
                .init("wall_ball", sets: 4, value: 15, weight: 9),
                .init("burpee", sets: 3, value: 12),
                .init("farmers_walk", sets: 3, value: 40, weight: 24),
            ],
            level: .advanced
        ),

        RoutineTemplate(
            id: "strength_heavy",
            nameES: "Fuerza Pesada", nameEN: "Heavy Strength",
            descES: "Pocas repeticiones, mucha carga. Descansa 3 minutos entre series.",
            descEN: "Low reps, heavy load. Rest 3 minutes between sets.",
            icon: "🎯", colorHex: "#E8A135",
            days: [0, 2, 4],
            items: [
                .init("squat", sets: 5, value: 5, weight: 70),
                .init("bench", sets: 5, value: 5, weight: 55),
                .init("peso", sets: 3, value: 5, weight: 80),
                .init("shoulder", sets: 3, value: 6, weight: 30),
                .init("pull", sets: 4, value: 6),
            ],
            level: .advanced
        ),

        RoutineTemplate(
            id: "mobility",
            nameES: "Movilidad y Estiramiento", nameEN: "Mobility & Stretch",
            descES: "Sesión de recuperación. Sin carga, todo control y respiración.",
            descEN: "Recovery session. No load, all control and breathing.",
            icon: "🧘", colorHex: "#32D74B",
            days: [6],
            items: [
                .init("caminata", sets: 1, value: 10),
                .init("yoga", sets: 1, value: 15),
                .init("espalda_str", sets: 2, value: 45),
                .init("hip_flexor", sets: 2, value: 45),
                .init("pigeon", sets: 2, value: 60),
                .init("foam_roll", sets: 1, value: 10),
            ],
            level: .beginner
        ),
    ]

    static func templates(level: RoutineTemplate.Level) -> [RoutineTemplate] {
        all.filter { $0.level == level }
    }

    /// Crea una Routine real a partir de la plantilla y la inserta.
    /// Los ejercicios que no existan en el catálogo se ignoran en silencio,
    /// para que un id obsoleto no rompa la plantilla completa.
    @discardableResult
    static func createRoutine(from template: RoutineTemplate,
                              in context: ModelContext,
                              time: Date? = nil) -> Routine {
        let routine = Routine(
            name: template.name,
            desc: template.desc,
            colorHex: template.colorHex,
            icon: template.icon,
            days: template.days,
            time: time
        )
        context.insert(routine)

        var order = 0
        for item in template.items {
            guard let catalogEx = ExerciseCatalog.all.first(where: { $0.id == item.exerciseId }) else { continue }
            let exercise = Exercise(
                id: catalogEx.id,
                name: catalogEx.name,
                icon: catalogEx.icon,
                category: catalogEx.category,
                unit: catalogEx.unit,
                sets: item.sets,
                defaultValue: item.value,
                order: order,
                defaultWeight: item.weight
            )
            exercise.routine = routine
            routine.exercises.append(exercise)
            context.insert(exercise)
            order += 1
        }

        try? context.save()
        return routine
    }
}
