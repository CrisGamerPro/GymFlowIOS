import SwiftUI
import SwiftData
import UserNotifications

@main
struct GymFlowApp: App {
    @AppStorage(AppLanguage.storageKey) private var languageCode = AppLanguage.spanish.rawValue

    init() {
        UNUserNotificationCenter.current().delegate = NotificationRouter.shared
        NotificationService.registerCategories()
    }

    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Routine.self,
            Exercise.self,
            WorkoutLog.self,
            ExerciseLog.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .preferredColorScheme(.dark)
                .environment(\.locale, (AppLanguage(rawValue: languageCode) ?? .spanish).locale)
        }
        .modelContainer(sharedModelContainer)
    }
}
