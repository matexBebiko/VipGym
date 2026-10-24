import SwiftUI
import SwiftData

@main
struct VipGymApp: App {
    let container: ModelContainer
    @State private var coordinator = WorkoutCoordinator()

    init() {
        do {
            container = try ModelContainer(for: Exercise.self, WorkoutSession.self, WorkoutEntry.self, WorkoutSet.self)
        } catch {
            fatalError("Nie można utworzyć bazy danych: \(error)")
        }
        ExerciseSeeder.seedIfNeeded(context: container.mainContext)
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(coordinator)
                .modelContainer(container)
        }
    }
}
