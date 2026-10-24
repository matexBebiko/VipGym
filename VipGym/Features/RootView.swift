import SwiftUI
import SwiftData

enum RootTab: Hashable { case workout, exercises, progress, coach, settings }

struct RootView: View {
    @AppStorage("appLanguage") private var language = "system"
    @AppStorage("appearance") private var appearance = AppAppearance.dark.rawValue
    @Environment(\.modelContext) private var context
    @Environment(WorkoutCoordinator.self) private var coordinator
    @State private var tab: RootTab = .workout

    var body: some View {
        @Bindable var coordinator = coordinator
        TabView(selection: $tab) {
            Tab(L("tab.workout"), systemImage: "figure.strengthtraining.traditional", value: RootTab.workout) {
                WorkoutHomeView()
            }
            Tab(L("tab.exercises"), systemImage: "list.bullet.rectangle", value: RootTab.exercises) {
                ExercisesView()
            }
            Tab(L("tab.progress"), systemImage: "chart.xyaxis.line", value: RootTab.progress) {
                ComingSoonView(title: L("tab.progress"), message: L("soon.progress"), symbol: "chart.xyaxis.line")
            }
            Tab(L("tab.coach"), systemImage: "sparkles", value: RootTab.coach) {
                ComingSoonView(title: L("tab.coach"), message: L("soon.coach"), symbol: "sparkles")
            }
            Tab(L("tab.settings"), systemImage: "slider.horizontal.3", value: RootTab.settings) {
                SettingsView()
            }
        }
        .tint(Theme.accent)
        .preferredColorScheme((AppAppearance(rawValue: appearance) ?? .dark).scheme)
        .environment(\.locale, Localizer.locale)
        .fullScreenCover(isPresented: $coordinator.isPresentingWorkout) {
            ActiveWorkoutView()
                .environment(\.locale, Localizer.locale)
                .preferredColorScheme((AppAppearance(rawValue: appearance) ?? .dark).scheme)
        }
        .id(language)
        .task { coordinator.recover(context: context) }
    }
}
