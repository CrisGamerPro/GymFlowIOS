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

    // Export
    @State private var exportFileURL: URL? = nil
    @State private var showShareSheet = false
    @State private var exportError: String? = nil
    @State private var showExportErrorAlert = false

    // Import
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
                            // Idioma
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

                            // Notificaciones
                            SettingsRowView(icon: "bell.fill", tint: Theme.amber, title: "Notificaciones") {
                                notificationStatusView
                            }
                            .accessibilityElement(children: .combine)
                            Divider().background(Color.white.opacity(0.08))

                            // Siri
                            NavigationLink(destination: SiriShortcutsView()) {
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

                            // Estadísticas → detalle con gráfico
                            NavigationLink(destination: StatsDetailView()) {
                                SettingsRowView(icon: "chart.bar.fill", tint: Theme.blue, title: "Estadísticas") {
                                    HStack(spacing: 4) {
                                        Text("\(logs.count) entrenamientos")
                                            .scaledFont(size: 13)
                                            .foregroundColor(Theme.textSecondary)
                                        Image(systemName: "chevron.right")
                                            .scaledFont(size: 13, weight: .semibold)
                                            .foregroundColor(Theme.textSecondary)
                                            .accessibilityHidden(true)
                                    }
                                }
                            }
                            .accessibilityElement(children: .combine)
                            .accessibilityAddTraits(.isButton)
                            Divider().background(Color.white.opacity(0.08))

                            // Exportar datos
                            Button(action: exportData) {
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

                            // Importar datos
                            Button(action: { showImporter = true }) {
                                SettingsRowView(icon: "tray.and.arrow.down.fill", tint: Theme.teal, title: "Importar datos") {
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
            .sheet(isPresented: $showShareSheet) {
                if let url = exportFileURL {
                    ShareSheet(url: url)
                }
            }
            .alert("Editar nombre", isPresented: $showEditName) {
                TextField("Tu nombre", text: $nameInput)
                Button("Cancelar", role: .cancel) {}
                Button("Guardar") {
                    let t = nameInput.trimmingCharacters(in: .whitespaces)
                    if !t.isEmpty { userName = t }
                }
            }
            .alert("Error al exportar", isPresented: $showExportErrorAlert) {
                Button("Entendido", role: .cancel) {}
            } message: {
                Text(exportError ?? "Error desconocido")
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

    // MARK: - Export

    private func exportData() {
        let service = DataExportService.shared
        let backup = service.createBackup(routines: Array(routines), logs: Array(logs))
        do {
            let url = try service.saveToTemporaryFile(backup)
            exportFileURL = url
            showShareSheet = true
        } catch {
            exportError = error.localizedDescription
            showExportErrorAlert = true
        }
    }

    // MARK: - Import

    private func handleImportResult(_ result: Result<URL, Error>) {
        switch result {
        case .success(let url):
            let needsAccess = url.startAccessingSecurityScopedResource()
            defer { if needsAccess { url.stopAccessingSecurityScopedResource() } }
            do {
                let migration = try DataExportService.shared.smartImport(from: url, into: modelContext)
                let language = AppLanguage.current
                if language == .english {
                    importResultMessage = "Imported \(migration.importedRoutines) routine(s) and \(migration.importedLogs) workout(s)."
                } else {
                    importResultMessage = "Se importaron \(migration.importedRoutines) rutina(s) y \(migration.importedLogs) entrenamiento(s)."
                }
            } catch {
                importResultMessage = AppLanguage.current == .english
                    ? "Couldn't import: \(error.localizedDescription)"
                    : "No se pudo importar: \(error.localizedDescription)"
            }
        case .failure(let error):
            importResultMessage = AppLanguage.current == .english
                ? "Couldn't open file: \(error.localizedDescription)"
                : "No se pudo abrir el archivo: \(error.localizedDescription)"
        }
        showImportResultAlert = true
    }

    // MARK: - Profile Header

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
        // Las notificaciones ya programadas guardan su texto tal cual se creó,
        // así que hay que reprogramarlas para que cambien de idioma.
        for routine in routines where routine.time != nil && !routine.days.isEmpty {
            NotificationService.shared.scheduleNotifications(for: routine)
        }
    }

    private func requestNotificationPermission() {
        NotificationService.shared.requestPermission { _ in refreshNotificationStatus() }
    }

    private func refreshNotificationStatus() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async { notificationStatus = settings.authorizationStatus }
        }
    }
}

// MARK: - ShareSheet (UIActivityViewController wrapper)

struct ShareSheet: UIViewControllerRepresentable {
    let url: URL

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: [url], applicationActivities: nil)
    }

    func updateUIViewController(_ vc: UIActivityViewController, context: Context) {}
}

// MARK: - Supporting views

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

                Button(action: {
                    guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
                    UIApplication.shared.open(url)
                }) {
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
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Theme.red.opacity(0.25), lineWidth: 1))
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
