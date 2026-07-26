import Foundation
import Combine
import UserNotifications

/// Recibe las interacciones con notificaciones locales (tap, "Iniciar ahora",
/// "Posponer 15 min") y expone el ID de rutina pendiente para que ContentView
/// navegue a ActiveWorkoutView (deep link).
final class NotificationRouter: NSObject, ObservableObject, UNUserNotificationCenterDelegate {
    static let shared = NotificationRouter()

    @Published var pendingRoutineId: UUID?

    private override init() {
        super.init()
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .sound])
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let userInfo = response.notification.request.content.userInfo
        let routineIdString = userInfo["routineId"] as? String

        switch response.actionIdentifier {
        case NotificationService.snoozeActionIdentifier:
            NotificationService.shared.snoozeNotification(originalContent: response.notification.request.content)

        case UNNotificationDefaultActionIdentifier, NotificationService.startNowActionIdentifier:
            if let idString = routineIdString, let id = UUID(uuidString: idString) {
                DispatchQueue.main.async { [weak self] in
                    self?.pendingRoutineId = id
                }
            }

        default:
            break
        }

        completionHandler()
    }
}
