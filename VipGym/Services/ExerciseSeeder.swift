import Foundation
import SwiftData

private struct SeedExercise: Decodable {
    let id: String
    let nameEN: String
    let namePL: String?
    let primary: String
    let secondary: [String]
    let equipment: String
    let category: String
    let level: String
    let instructions: [String]
}

/// Wczytuje wbudowaną bazę ćwiczeń (exercises.json). Własne ćwiczenia użytkownika nigdy nie są nadpisywane.
enum ExerciseSeeder {
    static let version = 1
    private static let versionKey = "exerciseSeedVersion"

    static func seedIfNeeded(context: ModelContext) {
        guard UserDefaults.standard.integer(forKey: versionKey) < version else { return }
        guard let url = Bundle.main.url(forResource: "exercises", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let seeds = try? JSONDecoder().decode([SeedExercise].self, from: data) else { return }

        let existing = (try? context.fetch(FetchDescriptor<Exercise>())) ?? []
        var byId = Dictionary(uniqueKeysWithValues: existing.map { ($0.id, $0) })

        for s in seeds {
            guard let primary = MuscleGroup(rawValue: s.primary),
                  let equipment = Equipment(rawValue: s.equipment) else { continue }
            let category = ExerciseCategory(rawValue: s.category) ?? .strength
            let level = ExerciseLevel(rawValue: s.level) ?? .beginner
            let secondary = s.secondary.compactMap(MuscleGroup.init(rawValue:))

            if let e = byId[s.id] {
                guard !e.isCustom else { continue }
                e.nameEN = s.nameEN; e.namePL = s.namePL
                e.primaryMuscleRaw = primary.rawValue; e.secondaryMusclesRaw = secondary.map(\.rawValue)
                e.equipmentRaw = equipment.rawValue; e.categoryRaw = category.rawValue
                e.levelRaw = level.rawValue; e.instructions = s.instructions
            } else {
                let e = Exercise(id: s.id, nameEN: s.nameEN, namePL: s.namePL, primary: primary,
                                 secondary: secondary, equipment: equipment, category: category,
                                 level: level, instructions: s.instructions)
                context.insert(e)
                byId[s.id] = e
            }
        }
        try? context.save()
        UserDefaults.standard.set(version, forKey: versionKey)
    }
}
