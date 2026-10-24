import SwiftUI

struct SettingsView: View {
    @AppStorage("appLanguage") private var language = AppLanguage.system.rawValue
    @AppStorage("appearance") private var appearance = AppAppearance.dark.rawValue
    @AppStorage("unitSystem") private var unitRaw = UnitSystem.kg.rawValue
    @AppStorage("defaultRestSeconds") private var rest = 240

    var body: some View {
        NavigationStack {
            Form {
                Section(L("settings.section.general")) {
                    Picker(L("settings.language"), selection: $language) {
                        ForEach(AppLanguage.allCases) { Text($0.title).tag($0.rawValue) }
                    }
                    Picker(L("settings.appearance"), selection: $appearance) {
                        ForEach(AppAppearance.allCases) { Text($0.title).tag($0.rawValue) }
                    }
                }
                Section(L("settings.section.training")) {
                    Picker(L("settings.units"), selection: $unitRaw) {
                        ForEach(UnitSystem.allCases) { Text($0.symbol).tag($0.rawValue) }
                    }
                    .pickerStyle(.segmented)
                    Stepper(value: $rest, in: 15...900, step: 15) {
                        HStack {
                            Text(L("settings.rest"))
                            Spacer()
                            Text(Fmt.clock(Double(rest))).font(Theme.mono(16)).foregroundStyle(Theme.accent)
                        }
                    }
                }
                Section(L("settings.section.about")) {
                    HStack {
                        Text(L("settings.version"))
                        Spacer()
                        Text(Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "")
                            .foregroundStyle(Theme.textSecondary)
                    }
                    Text(L("settings.privacy")).font(.system(size: 13)).foregroundStyle(Theme.textSecondary)
                }
            }
            .scrollContentBackground(.hidden)
            .background(Theme.bg.ignoresSafeArea())
            .navigationTitle(L("tab.settings"))
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}
