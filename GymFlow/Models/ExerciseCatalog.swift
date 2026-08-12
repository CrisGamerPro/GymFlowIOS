import Foundation

struct CatalogExercise: Identifiable, Hashable {
    let id: String
    let name: String
    let icon: String
    let category: String
    let unit: String
    let defaultSets: Int
    let defaultValue: Int
}

struct ExerciseCatalog {
    static let all: [CatalogExercise] = [
        // MARK: Cardio
        CatalogExercise(id: "trote",       name: "Trote",              icon: "🏃",  category: "Cardio",      unit: "min", defaultSets: 1, defaultValue: 20),
        CatalogExercise(id: "bici",        name: "Bicicleta",          icon: "🚴",  category: "Cardio",      unit: "min", defaultSets: 1, defaultValue: 30),
        CatalogExercise(id: "remar",       name: "Remar",              icon: "🚣",  category: "Cardio",      unit: "min", defaultSets: 1, defaultValue: 15),
        CatalogExercise(id: "cuerda",      name: "Saltar la cuerda",   icon: "🪢",  category: "Cardio",      unit: "min", defaultSets: 3, defaultValue: 3),
        CatalogExercise(id: "elip",        name: "Elíptica",           icon: "⚙️",  category: "Cardio",      unit: "min", defaultSets: 1, defaultValue: 20),
        CatalogExercise(id: "nata",        name: "Natación",           icon: "🏊",  category: "Cardio",      unit: "min", defaultSets: 1, defaultValue: 30),
        CatalogExercise(id: "box",         name: "Boxeo / Sombra",     icon: "🥊",  category: "Cardio",      unit: "min", defaultSets: 3, defaultValue: 5),
        CatalogExercise(id: "hiit",        name: "HIIT",               icon: "⚡",  category: "Cardio",      unit: "min", defaultSets: 1, defaultValue: 20),
        CatalogExercise(id: "sprints",     name: "Sprints",            icon: "💨",  category: "Cardio",      unit: "min", defaultSets: 6, defaultValue: 1),
        CatalogExercise(id: "escaladora",  name: "Escaladora",         icon: "🧗",  category: "Cardio",      unit: "min", defaultSets: 1, defaultValue: 15),
        CatalogExercise(id: "remo_erg",    name: "Remo Ergómetro",     icon: "🚣",  category: "Cardio",      unit: "min", defaultSets: 1, defaultValue: 20),
        CatalogExercise(id: "caminata",    name: "Caminata Rápida",    icon: "🚶",  category: "Cardio",      unit: "min", defaultSets: 1, defaultValue: 30),
        CatalogExercise(id: "cinta",       name: "Cinta de Correr",    icon: "🏃",  category: "Cardio",      unit: "min", defaultSets: 1, defaultValue: 25),
        CatalogExercise(id: "aerobicos",   name: "Aeróbicos",          icon: "🎽",  category: "Cardio",      unit: "min", defaultSets: 1, defaultValue: 30),
        CatalogExercise(id: "step",        name: "Step",               icon: "🪜",  category: "Cardio",      unit: "min", defaultSets: 3, defaultValue: 5),

        // MARK: Fuerza
        CatalogExercise(id: "bench",       name: "Press Banca",           icon: "🏋️", category: "Fuerza", unit: "reps", defaultSets: 4, defaultValue: 10),
        CatalogExercise(id: "manc",        name: "Mancuernas",            icon: "💪", category: "Fuerza", unit: "reps", defaultSets: 3, defaultValue: 12),
        CatalogExercise(id: "flex",        name: "Flexiones",             icon: "🤸", category: "Fuerza", unit: "reps", defaultSets: 4, defaultValue: 15),
        CatalogExercise(id: "squat",       name: "Sentadillas",           icon: "🦵", category: "Fuerza", unit: "reps", defaultSets: 4, defaultValue: 12),
        CatalogExercise(id: "pull",        name: "Dominadas",             icon: "🧲", category: "Fuerza", unit: "reps", defaultSets: 3, defaultValue: 8),
        CatalogExercise(id: "lunge",       name: "Zancadas",              icon: "🚶", category: "Fuerza", unit: "reps", defaultSets: 3, defaultValue: 12),
        CatalogExercise(id: "shoulder",    name: "Press Hombro",          icon: "🏋️", category: "Fuerza", unit: "reps", defaultSets: 3, defaultValue: 10),
        CatalogExercise(id: "bicep",       name: "Curl Bíceps",           icon: "💪", category: "Fuerza", unit: "reps", defaultSets: 3, defaultValue: 12),
        CatalogExercise(id: "tricep",      name: "Extensión Tríceps",     icon: "💪", category: "Fuerza", unit: "reps", defaultSets: 3, defaultValue: 12),
        CatalogExercise(id: "jalon",       name: "Jalón al Pecho",        icon: "🏋️", category: "Fuerza", unit: "reps", defaultSets: 3, defaultValue: 10),
        CatalogExercise(id: "dips",        name: "Fondos",                icon: "🤸", category: "Fuerza", unit: "reps", defaultSets: 3, defaultValue: 10),
        CatalogExercise(id: "remo",        name: "Remo con Barra",        icon: "🏋️", category: "Fuerza", unit: "reps", defaultSets: 3, defaultValue: 10),
        CatalogExercise(id: "peso",        name: "Peso Muerto",           icon: "🏋️", category: "Fuerza", unit: "reps", defaultSets: 3, defaultValue: 8),
        CatalogExercise(id: "hip_thrust",  name: "Hip Thrust",            icon: "🍑", category: "Fuerza", unit: "reps", defaultSets: 4, defaultValue: 12),
        CatalogExercise(id: "face_pull",   name: "Face Pull",             icon: "🎯", category: "Fuerza", unit: "reps", defaultSets: 3, defaultValue: 15),
        CatalogExercise(id: "aperturas",   name: "Aperturas Mancuerna",   icon: "🦅", category: "Fuerza", unit: "reps", defaultSets: 3, defaultValue: 12),
        CatalogExercise(id: "arnold",      name: "Arnold Press",          icon: "💪", category: "Fuerza", unit: "reps", defaultSets: 3, defaultValue: 10),
        CatalogExercise(id: "curl_martillo", name: "Curl Martillo",       icon: "🔨", category: "Fuerza", unit: "reps", defaultSets: 3, defaultValue: 12),
        CatalogExercise(id: "ext_quad",    name: "Extensión Cuádriceps",  icon: "🦵", category: "Fuerza", unit: "reps", defaultSets: 3, defaultValue: 15),
        CatalogExercise(id: "femoral",     name: "Femoral Acostado",      icon: "🦵", category: "Fuerza", unit: "reps", defaultSets: 3, defaultValue: 12),
        CatalogExercise(id: "polea",       name: "Remo en Polea",         icon: "🏋️", category: "Fuerza", unit: "reps", defaultSets: 3, defaultValue: 12),
        CatalogExercise(id: "press_inclinado", name: "Press Inclinado",   icon: "📐", category: "Fuerza", unit: "reps", defaultSets: 4, defaultValue: 10),
        CatalogExercise(id: "remo_un_brazo",   name: "Remo Un Brazo",     icon: "💪", category: "Fuerza", unit: "reps", defaultSets: 3, defaultValue: 10),
        CatalogExercise(id: "reverse_fly", name: "Reverse Fly",           icon: "🦅", category: "Fuerza", unit: "reps", defaultSets: 3, defaultValue: 15),
        CatalogExercise(id: "press_cerrado", name: "Press Cerrado",       icon: "🏋️", category: "Fuerza", unit: "reps", defaultSets: 3, defaultValue: 10),

        // MARK: Core
        CatalogExercise(id: "abs",         name: "Abdominales",         icon: "🫀", category: "Core", unit: "reps", defaultSets: 3, defaultValue: 20),
        CatalogExercise(id: "plancha",     name: "Plancha",             icon: "🧘", category: "Core", unit: "seg",  defaultSets: 3, defaultValue: 45),
        CatalogExercise(id: "burpee",      name: "Burpees",             icon: "💥", category: "Core", unit: "reps", defaultSets: 3, defaultValue: 10),
        CatalogExercise(id: "mtn",         name: "Mountain Climbers",   icon: "🏔️", category: "Core", unit: "reps", defaultSets: 3, defaultValue: 20),
        CatalogExercise(id: "russian",     name: "Russian Twists",      icon: "🔄", category: "Core", unit: "reps", defaultSets: 3, defaultValue: 20),
        CatalogExercise(id: "elevacion",   name: "Elevación de Piernas",icon: "🦵", category: "Core", unit: "reps", defaultSets: 3, defaultValue: 15),
        CatalogExercise(id: "supman",      name: "Superman",            icon: "🦸", category: "Core", unit: "reps", defaultSets: 3, defaultValue: 15),
        CatalogExercise(id: "crunches",    name: "Crunches",            icon: "🫀", category: "Core", unit: "reps", defaultSets: 3, defaultValue: 20),
        CatalogExercise(id: "dead_bug",    name: "Dead Bug",            icon: "🐛", category: "Core", unit: "reps", defaultSets: 3, defaultValue: 10),
        CatalogExercise(id: "hollow",      name: "Hollow Body",         icon: "🧘", category: "Core", unit: "seg",  defaultSets: 3, defaultValue: 30),
        CatalogExercise(id: "bird_dog",    name: "Bird Dog",            icon: "🐦", category: "Core", unit: "reps", defaultSets: 3, defaultValue: 12),
        CatalogExercise(id: "v_ups",       name: "V-Ups",               icon: "✌️", category: "Core", unit: "reps", defaultSets: 3, defaultValue: 15),
        CatalogExercise(id: "rueda",       name: "Rueda Abdominal",     icon: "⭕", category: "Core", unit: "reps", defaultSets: 3, defaultValue: 10),
        CatalogExercise(id: "windshield",  name: "Windshield Wipers",   icon: "🔄", category: "Core", unit: "reps", defaultSets: 3, defaultValue: 12),

        // MARK: Funcional
        CatalogExercise(id: "kettlebell",  name: "Kettlebell Swing",    icon: "🔔", category: "Funcional", unit: "reps", defaultSets: 4, defaultValue: 15),
        CatalogExercise(id: "battle_ropes",name: "Battle Ropes",        icon: "🌊", category: "Funcional", unit: "seg",  defaultSets: 4, defaultValue: 30),
        CatalogExercise(id: "box_jump",    name: "Box Jump",            icon: "📦", category: "Funcional", unit: "reps", defaultSets: 4, defaultValue: 10),
        CatalogExercise(id: "farmers_walk",name: "Farmer's Walk",       icon: "🚜", category: "Funcional", unit: "seg",  defaultSets: 4, defaultValue: 30),
        CatalogExercise(id: "get_up",      name: "Turkish Get-Up",      icon: "🎯", category: "Funcional", unit: "reps", defaultSets: 3, defaultValue: 5),
        CatalogExercise(id: "wall_ball",   name: "Wall Ball",           icon: "⚽", category: "Funcional", unit: "reps", defaultSets: 4, defaultValue: 15),

        // MARK: Flexibilidad
        CatalogExercise(id: "yoga",        name: "Yoga",                icon: "🧘", category: "Flexibilidad", unit: "min", defaultSets: 1, defaultValue: 20),
        CatalogExercise(id: "foam_roll",   name: "Foam Roll",           icon: "🫧", category: "Flexibilidad", unit: "min", defaultSets: 1, defaultValue: 10),
        CatalogExercise(id: "hip_flexor",  name: "Hip Flexor Stretch",  icon: "🦵", category: "Flexibilidad", unit: "seg", defaultSets: 2, defaultValue: 45),
        CatalogExercise(id: "espalda_str", name: "Estiramiento Espalda",icon: "🌿", category: "Flexibilidad", unit: "seg", defaultSets: 2, defaultValue: 45),
        CatalogExercise(id: "pigeon",      name: "Pigeon Pose",         icon: "🕊️", category: "Flexibilidad", unit: "seg", defaultSets: 2, defaultValue: 60),
    ]

    // MARK: - Translation tables (display-only, never touch stored data)

    private static let englishNames: [String: String] = [
        // Cardio
        "trote": "Jog", "bici": "Cycling", "remar": "Rowing",
        "cuerda": "Jump Rope", "elip": "Elliptical", "nata": "Swimming",
        "box": "Shadow Boxing", "hiit": "HIIT", "sprints": "Sprints",
        "escaladora": "Stair Climber", "remo_erg": "Rowing Machine",
        "caminata": "Brisk Walk", "cinta": "Treadmill", "aerobicos": "Aerobics",
        "step": "Step",
        // Fuerza
        "bench": "Bench Press", "manc": "Dumbbell Press", "flex": "Push-Ups",
        "squat": "Squats", "pull": "Pull-Ups", "lunge": "Lunges",
        "shoulder": "Shoulder Press", "bicep": "Bicep Curl",
        "tricep": "Tricep Extension", "jalon": "Lat Pulldown", "dips": "Dips",
        "remo": "Barbell Row", "peso": "Deadlift", "hip_thrust": "Hip Thrust",
        "face_pull": "Face Pull", "aperturas": "Dumbbell Fly",
        "arnold": "Arnold Press", "curl_martillo": "Hammer Curl",
        "ext_quad": "Leg Extension", "femoral": "Lying Leg Curl",
        "polea": "Cable Row", "press_inclinado": "Incline Press",
        "remo_un_brazo": "Single-Arm Row", "reverse_fly": "Reverse Fly",
        "press_cerrado": "Close-Grip Press",
        // Core
        "abs": "Sit-Ups", "plancha": "Plank", "burpee": "Burpees",
        "mtn": "Mountain Climbers", "russian": "Russian Twists",
        "elevacion": "Leg Raises", "supman": "Superman", "crunches": "Crunches",
        "dead_bug": "Dead Bug", "hollow": "Hollow Body", "bird_dog": "Bird Dog",
        "v_ups": "V-Ups", "rueda": "Ab Wheel", "windshield": "Windshield Wipers",
        // Funcional
        "kettlebell": "Kettlebell Swing", "battle_ropes": "Battle Ropes",
        "box_jump": "Box Jump", "farmers_walk": "Farmer's Walk",
        "get_up": "Turkish Get-Up", "wall_ball": "Wall Ball",
        // Flexibilidad
        "yoga": "Yoga", "foam_roll": "Foam Roll",
        "hip_flexor": "Hip Flexor Stretch", "espalda_str": "Back Stretch",
        "pigeon": "Pigeon Pose",
    ]

    private static let englishCategories: [String: String] = [
        "Todos": "All", "Cardio": "Cardio", "Fuerza": "Strength",
        "Core": "Core", "Funcional": "Functional", "Flexibilidad": "Flexibility",
    ]

    private static let englishUnits: [String: String] = [
        "reps": "reps", "min": "min", "seg": "sec",
    ]

    // MARK: - Public API

    static func displayName(id: String, storedName: String, language: AppLanguage = .current) -> String {
        guard language == .english, let translated = englishNames[id] else { return storedName }
        return translated
    }

    static func displayCategory(_ category: String, language: AppLanguage = .current) -> String {
        guard language == .english, let translated = englishCategories[category] else { return category }
        return translated
    }

    static func displayUnit(_ unit: String, language: AppLanguage = .current) -> String {
        guard language == .english, let translated = englishUnits[unit] else { return unit }
        return translated
    }

    /// Todas las categorías únicas del catálogo, en orden fijo de visualización.
    static var categories: [String] {
        ["Todos", "Cardio", "Fuerza", "Core", "Funcional", "Flexibilidad"]
    }

    /// ¿Este ejercicio se mide en tiempo (min o seg)?
    static func isTimeBased(unit: String) -> Bool {
        unit == "min" || unit == "seg"
    }
}
