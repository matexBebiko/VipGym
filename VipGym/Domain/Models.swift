import Foundation
import SwiftData

@Model
final class Exercise {
    @Attribute(.unique) var id: String
    var nameEN: String
    var namePL: String?
    var primaryMuscleRaw: String
    var secondaryMusclesRaw: [String]
    var equipmentRaw: String
    var categoryRaw: String
    var levelRaw: String
    var instructions: [String]
    var isCustom: Bool
    var isFavorite: Bool
    var photoFiles: [String]
    var userNotes: String
    var restSecondsOverride: Int?
    var createdAt: Date

    init(id: String, nameEN: String, namePL: String? = nil, primary: MuscleGroup,
         secondary: [MuscleGroup] = [], equipment: Equipment, category: ExerciseCategory = .strength,
         level: ExerciseLevel = .beginner, instructions: [String] = [], isCustom: Bool = false) {
        self.id = id
        self.nameEN = nameEN
        self.namePL = namePL
        self.primaryMuscleRaw = primary.rawValue
        self.secondaryMusclesRaw = secondary.map(\.rawValue)
        self.equipmentRaw = equipment.rawValue
        self.categoryRaw = category.rawValue
        self.levelRaw = level.rawValue
        self.instructions = instructions
        self.isCustom = isCustom
        self.isFavorite = false
        self.photoFiles = []
        self.userNotes = ""
        self.restSecondsOverride = nil
        self.createdAt = .now
    }

    var primaryMuscle: MuscleGroup { MuscleGroup(rawValue: primaryMuscleRaw) ?? .chest }
    var secondaryMuscles: [MuscleGroup] { secondaryMusclesRaw.compactMap(MuscleGroup.init(rawValue:)) }
    var equipment: Equipment { Equipment(rawValue: equipmentRaw) ?? .other }
    var category: ExerciseCategory { ExerciseCategory(rawValue: categoryRaw) ?? .strength }
    var level: ExerciseLevel { ExerciseLevel(rawValue: levelRaw) ?? .beginner }

    var displayName: String {
        if Localizer.isPolish, let pl = namePL, !pl.isEmpty { return pl }
        return nameEN
    }
}

@Model
final class WorkoutSession {
    var id: UUID
    var startedAt: Date
    var endedAt: Date?
    var title: String
    var notes: String
    @Relationship(deleteRule: .cascade, inverse: \WorkoutEntry.session) var entries: [WorkoutEntry] = []

    init(title: String, startedAt: Date = .now) {
        self.id = UUID()
        self.title = title
        self.startedAt = startedAt
        self.notes = ""
    }

    var sortedEntries: [WorkoutEntry] { entries.sorted { $0.order < $1.order } }
    var completedSets: [WorkoutSet] { entries.flatMap(\.sets).filter(\.isCompleted) }
    var totalVolumeKg: Double { ProgressionEngine.volume(of: completedSets) }
    var duration: TimeInterval { (endedAt ?? .now).timeIntervalSince(startedAt) }
}

@Model
final class WorkoutEntry {
    var order: Int
    var supersetGroup: Int?
    var exercise: Exercise?
    var session: WorkoutSession?
    @Relationship(deleteRule: .cascade, inverse: \WorkoutSet.entry) var sets: [WorkoutSet] = []

    init(order: Int, exercise: Exercise) {
        self.order = order
        self.exercise = exercise
    }

    var sortedSets: [WorkoutSet] { sets.sorted { $0.order < $1.order } }
}

@Model
final class WorkoutSet {
    var order: Int
    var weightKg: Double
    var reps: Int
    var rir: Int?
    var kindRaw: String
    var isCompleted: Bool
    var completedAt: Date?
    var entry: WorkoutEntry?

    init(order: Int, weightKg: Double = 0, reps: Int = 0, rir: Int? = nil, kind: SetKind = .working) {
        self.order = order
        self.weightKg = weightKg
        self.reps = reps
        self.rir = rir
        self.kindRaw = kind.rawValue
        self.isCompleted = false
    }

    var kind: SetKind {
        get { SetKind(rawValue: kindRaw) ?? .working }
        set { kindRaw = newValue.rawValue }
    }
}
