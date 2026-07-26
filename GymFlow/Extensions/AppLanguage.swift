import Foundation

/// Idioma elegido por el usuario en el onboarding (o cambiado luego desde
/// Perfil). Es independiente del idioma del sistema — así alguien con el
/// iPhone en inglés puede seguir usando GymFlow en español, y viceversa.
enum AppLanguage: String, CaseIterable, Identifiable {
    case spanish = "es"
    case english = "en"

    static let storageKey = "gymflow.languageCode"

    var id: String { rawValue }

    var locale: Locale { Locale(identifier: rawValue) }

    var displayName: String {
        switch self {
        case .spanish: return "Español"
        case .english: return "English"
        }
    }

    var flagEmoji: String {
        switch self {
        case .spanish: return "🇪🇸"
        case .english: return "🇺🇸"
        }
    }

    /// Lee la preferencia guardada. Para código fuera de SwiftUI (servicios,
    /// intents de Siri) donde no hay @Environment(\.locale) disponible.
    static var current: AppLanguage {
        let code = UserDefaults.standard.string(forKey: storageKey) ?? "es"
        return AppLanguage(rawValue: code) ?? .spanish
    }

    /// Abreviaturas de un día para los selectores de fecha (círculos chicos).
    var dayLetters: [String] {
        switch self {
        case .spanish: return ["L", "M", "X", "J", "V", "S", "D"]
        case .english: return ["Mo", "Tu", "We", "Th", "Fr", "Sa", "Su"]
        }
    }

    /// Nombres completos de los días, en orden GymFlow (0 = lunes).
    var dayFullNames: [String] {
        switch self {
        case .spanish:
            return ["Lunes", "Martes", "Miércoles", "Jueves", "Viernes", "Sábado", "Domingo"]
        case .english:
            return ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"]
        }
    }

    func greeting(hour: Int) -> String {
        switch self {
        case .spanish:
            if hour < 12 { return "Buenos días" }
            if hour < 19 { return "Buenas tardes" }
            return "Buenas noches"
        case .english:
            if hour < 12 { return "Good morning" }
            if hour < 19 { return "Good afternoon" }
            return "Good evening"
        }
    }
}

/// Localiza una cadena fuera del árbol de SwiftUI (contenido de
/// notificaciones, mensajes de error, diálogos de Siri) usando el idioma
/// elegido por el usuario en vez del idioma del sistema.
func L(_ key: String.LocalizationValue) -> String {
    String(localized: key, locale: AppLanguage.current.locale)
}
