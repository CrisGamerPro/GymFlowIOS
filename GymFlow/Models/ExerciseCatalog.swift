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
        // Cardio
        CatalogExercise(id: "trote", name: "Trote", icon: "🏃", category: "Cardio", unit: "min", defaultSets: 1, defaultValue: 20),
        CatalogExercise(id: "bici", name: "Bicicleta", icon: "🚴", category: "Cardio", unit: "min", defaultSets: 1, defaultValue: 30),
        CatalogExercise(id: "remar", name: "Remar", icon: "🚣", category: "Cardio", unit: "min", defaultSets: 1, defaultValue: 15),
        CatalogExercise(id: "cuerda", name: "Saltar la cuerda", icon: "🪢", category: "Cardio", unit: "min", defaultSets: 3, defaultValue: 3),
        CatalogExercise(id: "elip", name: "Elíptica", icon: "⚙️", category: "Cardio", unit: "min", defaultSets: 1, defaultValue: 20),
        CatalogExercise(id: "nata", name: "Natación", icon: "🏊", category: "Cardio", unit: "min", defaultSets: 1, defaultValue: 30),
        CatalogExercise(id: "box", name: "Boxeo / Sombra", icon: "🥊", category: "Cardio", unit: "min", defaultSets: 3, defaultValue: 5),
        
        // Fuerza
        CatalogExercise(id: "bench", name: "Press Banca", icon: "🏋️", category: "Fuerza", unit: "reps", defaultSets: 4, defaultValue: 10),
        CatalogExercise(id: "manc", name: "Mancuernas", icon: "💪", category: "Fuerza", unit: "reps", defaultSets: 3, defaultValue: 12),
        CatalogExercise(id: "flex", name: "Flexiones", icon: "🤸", category: "Fuerza", unit: "reps", defaultSets: 4, defaultValue: 15),
        CatalogExercise(id: "squat", name: "Sentadillas", icon: "🦵", category: "Fuerza", unit: "reps", defaultSets: 4, defaultValue: 12),
        CatalogExercise(id: "pull", name: "Dominadas", icon: "🧗", category: "Fuerza", unit: "reps", defaultSets: 3, defaultValue: 8),
        CatalogExercise(id: "lunge", name: "Zancadas", icon: "🦿", category: "Fuerza", unit: "reps", defaultSets: 3, defaultValue: 12),
        CatalogExercise(id: "shoulder", name: "Press Hombro", icon: "🏋️", category: "Fuerza", unit: "reps", defaultSets: 3, defaultValue: 10),
        CatalogExercise(id: "bicep", name: "Curl Bíceps", icon: "💪", category: "Fuerza", unit: "reps", defaultSets: 3, defaultValue: 12),
        CatalogExercise(id: "tricep", name: "Extensión Tríceps", icon: "💪", category: "Fuerza", unit: "reps", defaultSets: 3, defaultValue: 12),
        CatalogExercise(id: "jalon", name: "Jalón al Pecho", icon: "🏋️", category: "Fuerza", unit: "reps", defaultSets: 3, defaultValue: 10),
        CatalogExercise(id: "dips", name: "Fondos", icon: "🤸", category: "Fuerza", unit: "reps", defaultSets: 3, defaultValue: 10),
        CatalogExercise(id: "remo", name: "Remo con Barra", icon: "🏋️", category: "Fuerza", unit: "reps", defaultSets: 3, defaultValue: 10),
        CatalogExercise(id: "peso", name: "Peso Muerto", icon: "🏋️", category: "Fuerza", unit: "reps", defaultSets: 3, defaultValue: 8),
        
        // Core
        CatalogExercise(id: "abs", name: "Abdominales", icon: "🫀", category: "Core", unit: "reps", defaultSets: 3, defaultValue: 20),
        CatalogExercise(id: "plancha", name: "Plancha", icon: "🧘", category: "Core", unit: "seg", defaultSets: 3, defaultValue: 45),
        CatalogExercise(id: "burpee", name: "Burpees", icon: "💥", category: "Core", unit: "reps", defaultSets: 3, defaultValue: 10),
        CatalogExercise(id: "mtn", name: "Mountain Climbers", icon: "🏔️", category: "Core", unit: "reps", defaultSets: 3, defaultValue: 20),
        CatalogExercise(id: "russian", name: "Russian Twists", icon: "🔄", category: "Core", unit: "reps", defaultSets: 3, defaultValue: 20),
        CatalogExercise(id: "elevacion", name: "Elevación de Piernas", icon: "🦵", category: "Core", unit: "reps", defaultSets: 3, defaultValue: 15),
        CatalogExercise(id: "supman", name: "Superman", icon: "🦸", category: "Core", unit: "reps", defaultSets: 3, defaultValue: 15)
    ]

    /// GymFlow guarda nombre/categoría/unidad en español directamente en cada
    /// Exercise persistido (para no romper datos ya guardados en el
    /// dispositivo del usuario). Estas tablas traducen SOLO para mostrar en
    /// pantalla cuando el idioma elegido es inglés, sin tocar lo guardado.
    private static let englishNames: [String: String] = [
        "trote": "Jog", "bici": "Cycling", "remar": "Rowing", "cuerda": "Jump Rope",
        "elip": "Elliptical", "nata": "Swimming", "box": "Shadow Boxing",
        "bench": "Bench Press", "manc": "Dumbbell Press", "flex": "Push-Ups",
        "squat": "Squats", "pull": "Pull-Ups", "lunge": "Lunges",
        "shoulder": "Shoulder Press", "bicep": "Bicep Curl", "tricep": "Tricep Extension",
        "jalon": "Lat Pulldown", "dips": "Dips", "remo": "Barbell Row", "peso": "Deadlift",
        "abs": "Sit-Ups", "plancha": "Plank", "burpee": "Burpees",
        "mtn": "Mountain Climbers", "russian": "Russian Twists",
        "elevacion": "Leg Raises", "supman": "Superman"
    ]

    private static let englishCategories: [String: String] = [
        "Todos": "All", "Cardio": "Cardio", "Fuerza": "Strength", "Core": "Core"
    ]

    private static let englishUnits: [String: String] = [
        "reps": "reps", "min": "min", "seg": "sec"
    ]

    /// Nombre a mostrar de un ejercicio ya guardado, según el idioma actual.
    /// Si no hay traducción (ejercicio "Personalizado" importado de la PWA,
    /// por ejemplo), muestra el nombre guardado tal cual.
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
}
