import SwiftUI
import AppIntents

/// Pantalla para configurar los atajos de voz.
///
/// Apple exige que las frases integradas (App Shortcuts) incluyan el nombre
/// de la app. Para conseguir una frase libre como "Oye Siri, marca serie",
/// el usuario debe crear un atajo propio en la app Atajos y ponerle ese
/// nombre — `ShortcutsLink` lo lleva directo ahí. Funciona con cuenta de
/// desarrollador gratuita.
struct SiriShortcutsView: View {
    @State private var showMarkSetTip = true
    @State private var showCancelTip = true

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    intro

                    // Tarjetas nativas de Siri: muestran la frase exacta que
                    // el sistema registró para cada intent.
                    VStack(spacing: 12) {
                        SiriTipView(intent: CompleteNextSetIntent(), isVisible: $showMarkSetTip)
                            .siriTipViewStyle(.automatic)
                        SiriTipView(intent: CancelWorkoutIntent(), isVisible: $showCancelTip)
                            .siriTipViewStyle(.automatic)
                    }

                    phrasesCard
                    customPhraseCard
                }
                .padding()
            }
        }
        .navigationTitle("Atajos de Siri")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(Theme.cardBackground, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
    }

    private var intro: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Entrena sin tocar el teléfono")
                .scaledFont(size: 20, weight: .heavy)
                .foregroundColor(Theme.text)
            Text("Marca series con la voz mientras tienes las manos ocupadas.")
                .scaledFont(size: 14)
                .foregroundColor(Theme.textSecondary)
        }
        .accessibilityElement(children: .combine)
    }

    private var phrasesCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Frases listas para usar", systemImage: "waveform")
                .scaledFont(size: 15, weight: .bold)
                .foregroundColor(Theme.text)

            VStack(alignment: .leading, spacing: 8) {
                PhraseRow(text: "Oye Siri, marca serie en GymFlow")
                PhraseRow(text: "Oye Siri, siguiente serie en GymFlow")
                PhraseRow(text: "Oye Siri, serie hecha en GymFlow")
                PhraseRow(text: "Oye Siri, cancela la rutina en GymFlow")
            }

            Text("Apple exige que estas frases incluyan el nombre de la app.")
                .scaledFont(size: 12)
                .foregroundColor(Theme.textSecondary.opacity(0.8))
                .padding(.top, 2)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .glassCard()
    }

    private var customPhraseCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("¿Quieres una frase más corta?", systemImage: "sparkles")
                .scaledFont(size: 15, weight: .bold)
                .foregroundColor(Theme.amber)

            Text("Crea un atajo propio y ponle el nombre que quieras — por ejemplo «Serie». El nombre del atajo es la frase, así que podrás decir solo «Oye Siri, serie».")
                .scaledFont(size: 14)
                .foregroundColor(Theme.textSecondary)

            VStack(alignment: .leading, spacing: 6) {
                StepRow(number: 1, text: "Toca el botón de abajo para abrir Atajos.")
                StepRow(number: 2, text: "Elige «Marcar serie» de GymFlow.")
                StepRow(number: 3, text: "Renombra el atajo con tu frase.")
            }
            .padding(.top, 2)

            ShortcutsLink()
                .shortcutsLinkStyle(.automaticOutline)
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.top, 8)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .glassCard()
    }
}

private struct PhraseRow: View {
    let text: String

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: "quote.opening")
                .scaledFont(size: 11)
                .foregroundColor(Theme.amber.opacity(0.7))
                .accessibilityHidden(true)
            Text(text)
                .scaledFont(size: 14, weight: .medium)
                .foregroundColor(Theme.text)
                .fixedSize(horizontal: false, vertical: true)
        }
        .accessibilityElement(children: .combine)
    }
}

private struct StepRow: View {
    let number: Int
    let text: String

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            ZStack {
                Circle()
                    .fill(Theme.amber.opacity(0.18))
                    .frame(width: 20, height: 20)
                Text("\(number)")
                    .scaledFont(size: 11, weight: .bold)
                    .foregroundColor(Theme.amber)
            }
            Text(text)
                .scaledFont(size: 13)
                .foregroundColor(Theme.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .accessibilityElement(children: .combine)
    }
}
