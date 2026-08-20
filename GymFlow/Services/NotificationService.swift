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

    /// Aviso de fin de descanso. Se dispara al instante (intervalo mínimo de
    /// 1 s porque UNTimeIntervalNotificationTrigger no acepta 0) y solo se
    /// oye si la app está en segundo plano — en primer plano el usuario ya ve
    /// la barra de descanso, así que no hace falta molestarlo.
    func notifyRestFinished() {
        let english = AppLanguage.current == .english
        let content = UNMutableNotificationContent()
        content.title = english ? "Rest over 💥" : "Descanso terminado 💥"
        content.body = english ? "Next set — let's go." : "Siguiente serie — vamos."
        content.sound = .default
        content.interruptionLevel = .timeSensitive

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(
            identifier: "gymflow.rest.\(UUID().uuidString)",
            content: content, trigger: trigger
        )
        UNUserNotificationCenter.current().add(request)
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

        // Recordatorio 1 hora antes. Si eso cruza la medianoche hacia atrás
        // (rutina entre 00:00 y 00:59) hay que retroceder también el DÍA, o
        // la notificación se programaría a las 23:xx del mismo día — es decir,
        // casi 24 horas tarde.
        let crossesMidnight = hour < 1
        let targetHour = crossesMidnight ? hour + 23 : hour - 1
        let targetMinute = minute

        for day in routine.days {
            // GymFlow days: 0=Mon, 1=Tue... 6=Sun
            let notifyDay = crossesMidnight ? (day + 6) % 7 : day
            // Apple Calendar weekday: 1=Sun, 2=Mon...
            let appleWeekday = (notifyDay == 6) ? 1 : notifyDay + 2

            var dateComponents = DateComponents()
            dateComponents.weekday = appleWeekday
            dateComponents.hour = targetHour
            dateComponents.minute = targetMinute

            let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)

            // El identificador usa el día de la RUTINA (no el de la notificación)
            // para que cancelNotifications(for:) siga encontrándolos todos.
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
