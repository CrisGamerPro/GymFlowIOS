import Foundation
import UserNotifications

class NotificationService {
    static let shared = NotificationService()

    static let reminderCategoryIdentifier = "ROUTINE_REMINDER"
    static let startNowActionIdentifier = "START_NOW"
    static let snoozeActionIdentifier = "SNOOZE_15"

    private init() {}

    /// Registra las acciones de notificación ("Iniciar ahora" / "Posponer 15 min").
    /// Debe llamarse una vez al iniciar la app, antes de programar notificaciones,
    /// y de nuevo si el usuario cambia el idioma (para refrescar los títulos).
    static func registerCategories() {
        let english = AppLanguage.current == .english
        let startNow = UNNotificationAction(
            identifier: startNowActionIdentifier,
            title: english ? "Start now" : "Iniciar ahora",
            options: [.foreground]
        )
        let snooze = UNNotificationAction(
            identifier: snoozeActionIdentifier,
            title: english ? "Snooze 15 min" : "Posponer 15 min",
            options: []
        )
        let category = UNNotificationCategory(
            identifier: reminderCategoryIdentifier,
            actions: [startNow, snooze],
            intentIdentifiers: [],
            options: []
        )
        UNUserNotificationCenter.current().setNotificationCategories([category])
    }

    func requestPermission(completion: @escaping (Bool) -> Void) {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if let error = error {
                print("Error requesting notification permission: \(error)")
            }
            DispatchQueue.main.async {
                completion(granted)
            }
        }
    }

    /// Reprograma una notificación 15 minutos en el futuro, conservando su contenido.
    func snoozeNotification(originalContent: UNNotificationContent) {
        let content = UNMutableNotificationContent()
        content.title = originalContent.title
        content.body = originalContent.body
        content.sound = .default
        content.userInfo = originalContent.userInfo
        content.categoryIdentifier = originalContent.categoryIdentifier

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 15 * 60, repeats: false)
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request)
    }

    func scheduleNotifications(for routine: Routine) {
        cancelNotifications(for: routine)

        guard let time = routine.time else { return }

        let english = AppLanguage.current == .english
        let content = UNMutableNotificationContent()
        content.title = english ? "Time to train! 💪" : "¡Hora de entrenar! 💪"
        content.body = english
            ? "Your routine '\(routine.name)' starts in an hour."
            : "Tu rutina '\(routine.name)' empieza en una hora."
        content.sound = .default
        content.categoryIdentifier = NotificationService.reminderCategoryIdentifier
        // Datos para el deep link → ActiveWorkoutView
        content.userInfo = ["routineId": routine.id.uuidString]
        
        let calendar = Calendar.current
        let timeComponents = calendar.dateComponents([.hour, .minute], from: time)
        guard let hour = timeComponents.hour, let minute = timeComponents.minute else { return }
        
        // Calcular 1 hora antes
        var targetHour = hour - 1
        var targetMinute = minute
        if targetHour < 0 {
            targetHour += 24
        }
        
        for day in routine.days {
            // GymFlow days: 0=Mon, 1=Tue...
            // Apple Calendar weekday: 1=Sun, 2=Mon...
            let appleWeekday = (day == 6) ? 1 : day + 2
            
            var dateComponents = DateComponents()
            dateComponents.weekday = appleWeekday
            dateComponents.hour = targetHour
            dateComponents.minute = targetMinute
            
            let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
            
            // Unique identifier for each day of this routine
            let requestIdentifier = "\(routine.id.uuidString)-\(day)"
            let request = UNNotificationRequest(identifier: requestIdentifier, content: content, trigger: trigger)
            
            UNUserNotificationCenter.current().add(request) { error in
                if let error = error {
                    print("Error scheduling notification: \(error)")
                }
            }
        }
    }
    
    func cancelNotifications(for routine: Routine) {
        let identifiers = (0..<7).map { "\(routine.id.uuidString)-\($0)" }
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: identifiers)
    }
    
    func cancelAllNotifications() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
    }
}
