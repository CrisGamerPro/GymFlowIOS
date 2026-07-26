import SwiftUI
import SwiftData

struct ContentView: View {
    @AppStorage("gymflow.hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @Environment(\.modelContext) private var modelContext
    @ObservedObject private var notificationRouter = NotificationRouter.shared

    @State private var selectedTab = 0
    @State private var showCreateModal = false
    @State private var showOnboarding = false
    @State private var deepLinkRoutine: Routine?

    var body: some View {
        ZStack(alignment: .bottom) {
            Theme.background.ignoresSafeArea()

            // Main Content
            Group {
                switch selectedTab {
                case 0:
                    HomeView()
                case 1:
                    RoutinesView(showCreateModal: $showCreateModal)
                case 3:
                    ScheduleView()
                case 4:
                    ProfileView()
                default:
                    HomeView()
                }
            }
            .id(selectedTab)
            .transition(.opacity)
            .padding(.bottom, 64) // Tab bar height

            // Custom Tab Bar
            TabBarView(selectedTab: $selectedTab, showCreateModal: $showCreateModal)
        }
        .fullScreenCover(isPresented: $showCreateModal) {
            RoutineEditorView()
        }
        .fullScreenCover(isPresented: $showOnboarding) {
            OnboardingView { startCreatingRoutine in
                showOnboarding = false
                if startCreatingRoutine {
                    selectedTab = 1
                    showCreateModal = true
                }
            }
        }
        .fullScreenCover(item: $deepLinkRoutine) { routine in
            ActiveWorkoutView(routine: routine)
        }
        .onAppear {
            if !hasCompletedOnboarding {
                showOnboarding = true
            }
        }
        .onChange(of: notificationRouter.pendingRoutineId) { _, newId in
            guard let id = newId else { return }
            notificationRouter.pendingRoutineId = nil
            deepLinkRoutine = fetchRoutine(id: id)
        }
    }

    private func fetchRoutine(id: UUID) -> Routine? {
        let descriptor = FetchDescriptor<Routine>(predicate: #Predicate { $0.id == id })
        return try? modelContext.fetch(descriptor).first
    }
}

// Custom Tab Bar
struct TabBarView: View {
    @Binding var selectedTab: Int
    @Binding var showCreateModal: Bool
    
    var body: some View {
        HStack {
            TabBarItem(icon: "house", title: "Inicio", isSelected: selectedTab == 0) {
                selectTab(0)
            }
            Spacer()
            TabBarItem(icon: "square.grid.2x2", title: "Rutinas", isSelected: selectedTab == 1) {
                selectTab(1)
            }
            Spacer()

            // Center Plus Button
            Button(action: {
                showCreateModal = true
            }) {
                ZStack {
                    Circle()
                        .fill(Theme.amber)
                        .frame(width: 48, height: 48)
                        .shadow(color: Theme.amber.opacity(0.4), radius: 10, y: 4)

                    Image(systemName: "plus")
                        .scaledFont(size: 24, weight: .light)
                        .foregroundColor(.black)
                }
            }
            .offset(y: -16)
            .accessibilityLabel("Nueva rutina")

            Spacer()
            TabBarItem(icon: "calendar", title: "Agenda", isSelected: selectedTab == 3) {
                selectTab(3)
            }
            Spacer()
            TabBarItem(icon: "person", title: "Perfil", isSelected: selectedTab == 4) {
                selectTab(4)
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 10)
        .padding(.bottom, 20)
        .background(
            Theme.cardBackground
                .ignoresSafeArea()
                .overlay(
                    Rectangle()
                        .frame(height: 1)
                        .foregroundColor(Color.white.opacity(0.1)),
                    alignment: .top
                )
        )
    }

    private func selectTab(_ tab: Int) {
        withAnimation(.easeInOut(duration: 0.2)) {
            selectedTab = tab
        }
    }
}

struct TabBarItem: View {
    let icon: String
    let title: LocalizedStringKey
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .scaledFont(size: 22)
                    .scaleEffect(isSelected ? 1.1 : 1.0)
                    .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isSelected)
                Text(title)
                    .scaledFont(size: 10, weight: .medium)
            }
            .foregroundColor(isSelected ? Theme.amber : Theme.textSecondary)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(title)
        .accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : .isButton)
    }
}
