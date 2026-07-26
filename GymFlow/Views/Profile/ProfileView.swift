import SwiftUI
import SwiftData
import UserNotifications
import UIKit
import UniformTypeIdentifiers

struct ProfileView: View {
    @AppStorage("gymflow.userName") private var userName: String = ""
    @AppStorage(AppLanguage.storageKey) private var languageCode = AppLanguage.spanish.rawValue
    @Environment(\.modelContext) private var modelContext
    @Query private var routines: [Routine]
    @Query private var logs: [WorkoutLog]

    @State private var showEditName = false
    @State private var nameInput = ""
    @State private var notificationStatus: UNAuthorizationStatus = .notDetermined
    @State private var showExportAlert = false
    @State private var showSiriTipAlert = false
    @State private var showImporter = false
    @State private var importResultMessage = ""
    @State private var showImportResultAlert = false

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.background.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 24) {
                        profileHeader

                        HStack(spacing: 10) {
                            StatCard(value: "\(routines.count)", label: "Rutinas", color: Theme.blue)
                            StatCard(value: "\(logs.filter { $0.isCompleted }.count)", label: "Completados", color: Theme.green)
                            StatCard(value: "\(totalSetsCompleted())", label: "Series", color: Theme.amber)
                        }

                        if notificationStatus == .denied {
                            PermissionDeniedBanner()
                        }

                        VStack(spacing: 0) {
                            Menu {
                                ForEach(AppLanguage.allCases) { language in
                                    Button(action: { selectLanguage(language) }) {
                                        if languageCode == language.rawValue {
                                            Label(language.displayName, systemImage: "checkmark")
                                        } else {
                                            Text(language.displayName)
                                        }
                                    }
                                }
                            } label: {
                                SettingsRowView(icon: "globe", tint: Theme.blue, title: "Idioma") {
                                    Text((AppLanguage(rawValue: languageCode) ?? .spanish).displayName)
                                        .scaledFont(size: 13)
                                        .foregroundColor(Theme.textSecondary)
                                }
                            }
                            .accessibilityElement(children: .combine)
                            Divider().background(Color.white.opacity(0.08))

                            SettingsRowView(icon: "bell.fill", tint: Theme.amber, title: "Notificaciones") {
                                notificationStatusView
                            }
                            .accessibilityElement(children: .combine)
                            Divider().background(Color.white.opacity(0.08))

                            Button(action: { showSiriTipAlert = true }) {
                                SettingsRowView(icon: "waveform", tint: Theme.pink, title: "Atajos de Siri") {
                                    Image(systemName: "chevron.right")
                                        .scaledFont(size: 13, weight: .semibold)
                                        .foregroundColor(Theme.textSecondary)
                                        .accessibilityHidden(true)
                                }
                            }
                            .accessibilityElement(children: .combine)
                            .accessibilityAddTraits(.isButton)
                            Divider().background(Color.white.opacity(0.08))

                            SettingsRowView(icon: "chart.bar.fill", tint: Theme.blue, title: "Estadísticas") {
                                Text("\(logs.count) entrenamientos")
                                    .scaledFont(size: 13)
                                    .foregroundColor(Theme.textSecondary)
                            }
                            .accessibilityElement(children: .combine)
                            Divider().background(Color.white.opacity(0.08))

                            Button(action: { showExportAlert = true }) {
                                SettingsRowView(icon: "square.and.arrow.up.fill", tint: Theme.purple, title: "Exportar datos") {
                                    Image(systemName: "chevron.right")
                                        .scaledFont(size: 13, weight: .semibold)
                                        .foregroundColor(Theme.textSecondary)
                                        .accessibilityHidden(true)
                                }
                            }
                            .accessibilityElement(children: .combine)
                            .accessibilityAddTraits(.isButton)
                            Divider().background(Color.white.opacity(0.08))

                            Button(action: { showImporter = true }) {
                                SettingsRowView(icon: "tray.and.arrow.down.fill", tint: Theme.teal, title: "Importar desde la PWA") {
                                    Image(systemName: "chevron.right")
                                        .scaledFont(size: 13, weight: .semibold)
                                        .foregroundColor(Theme.textSecondary)
                                        .accessibilityHidden(true)
                                }
                            }
                            .accessibilityElement(children: .combine)
                            .accessibilityAddTraits(.isButton)
                        }
                        .glassCard()

                        Text("GymFlow v\(appVersion)")
                            .scaledFont(size: 12)
                            .foregroundColor(Theme.textSecondary.opacity(0.6))
                            .padding(.top, 8)
                    }
                    .padding()
                }
            }
            .navigationTitle("Perfil")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Theme.cardBackground, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .onAppear(perform: refreshNotificationStatus)
            .alert("Editar nombre", isPresented: $showEditName) {
                TextField("Tu nombre", text: $nameInput)
                Button("Cancelar", role: .cancel) {}
                Button("Guardar") {
                    let trimmed = nameInput.trimmingCharacters(in: .whitespaces)
                    if !trimmed.isEmpty { userName = trimmed }
                }
            }
            .alert("Próximamente", isPresented: $showExportAlert) {
                Button("Entendido", role: .cancel) {}
            } message: {
                Text("La exportación de datos estará disponible en una futura actualización.")
            }
            .alert("Atajos de Siri", isPresented: $showSiriTipAlert) {
                Button("Entendido", role: .cancel) {}
            } message: {
                Text("Mientras entrenas, prueba decir \"Oye Siri, marca serie en GymFlow\" para avanzar sin soltar las pesas.")
            }
            .fileImporter(isPresented: $showImporter, allowedContentTypes: [.json]) { result in
                handleImportResult(result)
            }
            .alert("Importar datos", isPresented: $showImportResultAlert) {
                Button("Entendido", role: .cancel) {}
            } message: {
                Text(importResultMessage)
            }
        }
    }

    private func handleImportResult(_ result: Result<URL, Error>) {
        let language = AppLanguage.current
        switch result {
        case .success(let url):
            let needsAccess = url.startAccessingSecurityScopedResource()
            defer { if needsAccess { url.stopAccessingSecurityScopedResource() } }
            do {
                let migration = try DataMigrationService.importData(from: url, into: modelContext)
                importResultMessage = importedSummary(migration, language: language)
            } catch {
                importResultMessage = importFailureMessage(error, language: language)
            }
        case .failure(let error):
            importResultMessage = importFailureMessage(error, language: language)
        }
        showImportResultAlert = true
    }

    private func importedSummary(_ migration: MigrationResult, language: AppLanguage) -> String {
        if language == .english {
            let routineWord = migration.importedRoutines == 1 ? "routine" : "routines"
            let logWord = migration.importedLogs == 1 ? "workout" : "workouts"
            return "Imported \(migration.importedRoutines) \(routineWord) and \(migration.importedLogs) \(logWord) from your history."
        }
        let routineWord = migration.importedRoutines == 1 ? "rutina" : "rutinas"
        let logWord = migration.importedLogs == 1 ? "entrenamiento" : "entrenamientos"
        return "Se importaron \(migration.importedRoutines) \(routineWord) y \(migration.importedLogs) \(logWord) del historial."
    }

    private func importFailureMessage(_ error: Error, language: AppLanguage) -> String {
        language == .english
            ? "Couldn't import: \(error.localizedDescription)"
            : "No se pudo importar: \(error.localizedDescription)"
    }

    private var profileHeader: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(Theme.amber.opacity(0.15))
                    .frame(width: 84, height: 84)
                Text(initials)
                    .scaledFont(size: 30, weight: .heavy)
                    .foregroundColor(Theme.amber)
            }

            Button(action: {
                nameInput = userName
                showEditName = true
            }) {
                HStack(spacing: 6) {
                    Text(displayName)
                        .scaledFont(size: 20, weight: .bold)
                        .foregroundColor(Theme.text)
                    Image(systemName: "pencil")
                        .scaledFont(size: 13)
                        .foregroundColor(Theme.textSecondary)
                        .accessibilityHidden(true)
                }
            }
            .accessibilityLabel("Nombre: \(displayName)")
            .accessibilityHint("Toca dos veces para editar tu nombre")
        }
        .padding(.top, 12)
    }

    private var displayName: String {
        userName.trimmingCharacters(in: .whitespaces).isEmpty ? "GymFlow" : userName
    }

    private var initials: String {
        let parts = displayName.split(separator: " ")
        let letters = parts.prefix(2).compactMap { $0.first }
        return letters.isEmpty ? "G" : String(letters).uppercased()
    }

    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    }

    private func totalSetsCompleted() -> Int {
        logs.flatMap { $0.exerciseLogs }.reduce(0) { $0 + $1.setsCompleted }
    }

    @ViewBuilder
    private var notificationStatusView: some View {
        switch notificationStatus {
        case .authorized, .provisional, .ephemeral:
            Text("Activadas")
                .scaledFont(size: 13, weight: .semibold)
                .foregroundColor(Theme.green)
        case .denied:
            Text("Desactivadas")
                .scaledFont(size: 13, weight: .semibold)
                .foregroundColor(Theme.red)
        default:
            Button(action: requestNotificationPermission) {
                Text("Activar")
                    .scaledFont(size: 13, weight: .bold)
                    .foregroundColor(Theme.amber)
            }
        }
    }

    private func selectLanguage(_ language: AppLanguage) {
        languageCode = language.rawValue
        NotificationService.registerCategories()
    }

    private func requestNotificationPermission() {
        NotificationService.shared.requestPermission { _ in
            refreshNotificationStatus()
        }
    }

    private func refreshNotificationStatus() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                notificationStatus = settings.authorizationStatus
            }
        }
    }
}

struct PermissionDeniedBanner: View {
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "bell.slash.fill")
                .scaledFont(size: 18)
                .foregroundColor(Theme.red)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 6) {
                Group {
                    Text("Notificaciones desactivadas")
                        .scaledFont(size: 14, weight: .bold)
                        .foregroundColor(Theme.text)
                    Text("No recibirás recordatorios de tus rutinas. Actívalas desde Ajustes de iOS.")
                        .scaledFont(size: 13)
                        .foregroundColor(Theme.textSecondary)
                }
                .accessibilityElement(children: .combine)

                Button(action: openSettings) {
                    Text("Abrir Ajustes")
                        .scaledFont(size: 13, weight: .bold)
                        .foregroundColor(Theme.amber)
                }
                .padding(.top, 2)
            }

            Spacer()
        }
        .padding(14)
        .background(Theme.red.opacity(0.1))
        .cornerRadius(14)
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Theme.red.opacity(0.25), lineWidth: 1)
        )
    }

    private func openSettings() {
        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
        UIApplication.shared.open(url)
    }
}

struct SettingsRowView<Trailing: View>: View {
    let icon: String
    let tint: Color
    let title: LocalizedStringKey
    @ViewBuilder var trailing: Trailing

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(tint.opacity(0.15))
                    .frame(width: 32, height: 32)
                Image(systemName: icon)
                    .scaledFont(size: 14, weight: .semibold)
                    .foregroundColor(tint)
                    .accessibilityHidden(true)
            }
            Text(title)
                .scaledFont(size: 15, weight: .medium)
                .foregroundColor(Theme.text)
            Spacer()
            trailing
        }
        .padding(14)
    }
}
