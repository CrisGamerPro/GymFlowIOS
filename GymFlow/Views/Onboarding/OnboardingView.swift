import SwiftUI

struct OnboardingView: View {
    @AppStorage("gymflow.userName") private var userName: String = ""
    @AppStorage("gymflow.hasCompletedOnboarding") private var hasCompletedOnboarding: Bool = false
    @AppStorage(AppLanguage.storageKey) private var languageCode = AppLanguage.spanish.rawValue

    /// Se llama al terminar el onboarding. `startCreatingRoutine` indica si el
    /// usuario eligió crear su primera rutina de inmediato.
    var onFinish: (_ startCreatingRoutine: Bool) -> Void

    @State private var step = 0
    @State private var nameInput = ""

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()

            Group {
                switch step {
                case 0: languageStep
                case 1: nameStep
                default: firstRoutineStep
                }
            }
            .transition(.opacity.combined(with: .move(edge: .trailing)))
            .id(step)
        }
        .animation(.easeInOut(duration: 0.3), value: step)
    }

    // MARK: - Paso 0: Idioma

    private var languageStep: some View {
        VStack(spacing: 28) {
            Spacer()

            Text("🌐")
                .scaledFont(size: 64)

            VStack(spacing: 8) {
                Text("Choose your language")
                    .scaledFont(size: 22, weight: .heavy)
                    .foregroundColor(Theme.text)
                Text("Elige tu idioma")
                    .scaledFont(size: 22, weight: .heavy)
                    .foregroundColor(Theme.text)
            }

            VStack(spacing: 12) {
                ForEach(AppLanguage.allCases) { language in
                    Button(action: { selectLanguage(language) }) {
                        HStack(spacing: 12) {
                            Text(language.flagEmoji)
                                .scaledFont(size: 24)
                            Text(language.displayName)
                                .scaledFont(size: 17, weight: .bold)
                                .foregroundColor(Theme.text)
                            Spacer()
                            if languageCode == language.rawValue {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(Theme.amber)
                            }
                        }
                        .padding(16)
                        .glassCard()
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(languageCode == language.rawValue ? Theme.amber.opacity(0.5) : Color.clear, lineWidth: 1.5)
                        )
                    }
                    .accessibilityLabel(language.displayName)
                    .accessibilityAddTraits(languageCode == language.rawValue ? [.isButton, .isSelected] : .isButton)
                }
            }
            .padding(.horizontal, 24)

            Spacer()

            Button(action: { withAnimation { step = 1 } }) {
                Text("Continuar / Continue")
                    .scaledFont(size: 16, weight: .bold)
                    .foregroundColor(.black)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Theme.amber)
                    .cornerRadius(16)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 40)
        }
    }

    private func selectLanguage(_ language: AppLanguage) {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            languageCode = language.rawValue
        }
        NotificationService.registerCategories()
    }

    // MARK: - Paso 1: Nombre

    private var nameStep: some View {
        VStack(spacing: 28) {
            Spacer()

            Text("🏋️")
                .scaledFont(size: 64)

            VStack(spacing: 8) {
                Text("Bienvenido a GymFlow")
                    .scaledFont(size: 26, weight: .heavy)
                    .foregroundColor(Theme.text)
                Text("¿Cómo quieres que te llamemos?")
                    .scaledFont(size: 15)
                    .foregroundColor(Theme.textSecondary)
                    .multilineTextAlignment(.center)
            }

            TextField("Tu nombre", text: $nameInput)
                .scaledFont(size: 18, weight: .medium)
                .foregroundColor(Theme.text)
                .multilineTextAlignment(.center)
                .padding(16)
                .background(Color(hex: "#2C2C2E"))
                .cornerRadius(14)
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(Color(hex: "#3A3A3C"), lineWidth: 1)
                )
                .submitLabel(.done)
                .onSubmit(continueFromNameStep)
                .padding(.horizontal, 24)

            Spacer()

            Button(action: continueFromNameStep) {
                Text("Continuar")
                    .scaledFont(size: 16, weight: .bold)
                    .foregroundColor(.black)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Theme.amber.opacity(canContinue ? 1 : 0.4))
                    .cornerRadius(16)
            }
            .disabled(!canContinue)
            .padding(.horizontal, 24)
            .padding(.bottom, 40)
        }
    }

    private var canContinue: Bool {
        !nameInput.trimmingCharacters(in: .whitespaces).isEmpty
    }

    private func continueFromNameStep() {
        guard canContinue else { return }
        userName = nameInput.trimmingCharacters(in: .whitespaces)
        withAnimation { step = 2 }
    }

    // MARK: - Paso 2: Cómo crear tu primera rutina

    private var firstRoutineStep: some View {
        VStack(spacing: 28) {
            Spacer()

            Text("👋 Hola, \(userName)")
                .scaledFont(size: 22, weight: .heavy)
                .foregroundColor(Theme.text)

            VStack(alignment: .leading, spacing: 18) {
                Text("Así creas tu primera rutina")
                    .scaledFont(size: 18, weight: .bold)
                    .foregroundColor(Theme.text)

                onboardingStep(number: "1", icon: "plus.circle.fill", text: "Toca el botón ＋ en la barra inferior")
                onboardingStep(number: "2", icon: "paintpalette.fill", text: "Elige un nombre, color e ícono")
                onboardingStep(number: "3", icon: "calendar", text: "Selecciona los días y la hora en que entrenas")
                onboardingStep(number: "4", icon: "figure.strengthtraining.traditional", text: "Agrega tus ejercicios desde el catálogo")
                onboardingStep(number: "5", icon: "checkmark.seal.fill", text: "Guarda y te avisaremos 1 hora antes")
            }
            .padding(20)
            .glassCard()
            .padding(.horizontal, 24)

            Spacer()

            VStack(spacing: 12) {
                Button(action: { finish(startCreatingRoutine: true) }) {
                    Text("Crear mi primera rutina")
                        .scaledFont(size: 16, weight: .bold)
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Theme.amber)
                        .cornerRadius(16)
                }

                Button(action: { finish(startCreatingRoutine: false) }) {
                    Text("Lo haré más tarde")
                        .scaledFont(size: 14, weight: .semibold)
                        .foregroundColor(Theme.textSecondary)
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 40)
        }
    }

    private func onboardingStep(number: String, icon: String, text: LocalizedStringKey) -> some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(Theme.amber.opacity(0.15))
                    .frame(width: 32, height: 32)
                Image(systemName: icon)
                    .scaledFont(size: 14, weight: .bold)
                    .foregroundColor(Theme.amber)
                    .accessibilityHidden(true)
            }
            Text(text)
                .scaledFont(size: 14)
                .foregroundColor(Theme.textSecondary)
            Spacer()
        }
        .accessibilityElement(children: .combine)
    }

    private func finish(startCreatingRoutine: Bool) {
        hasCompletedOnboarding = true
        onFinish(startCreatingRoutine)
    }
}
