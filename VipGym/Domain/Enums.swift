import SwiftUI

enum MuscleGroup: String, CaseIterable, Identifiable, Codable {
    case chest, lats, middleBack, lowerBack, traps, shoulders, biceps, triceps, forearms
    case abdominals, quadriceps, hamstrings, glutes, calves, adductors, abductors, neck
    var id: String { rawValue }
    var title: String { L("muscle.\(rawValue)") }
}

enum Equipment: String, CaseIterable, Identifiable, Codable {
    case barbell, dumbbell, machine, smith, cable, bodyweight, kettlebell, bands, ezBar
    case medicineBall, exerciseBall, foamRoll, other
    var id: String { rawValue }
    var title: String { L("equipment.\(rawValue)") }
}

enum ExerciseCategory: String, CaseIterable, Codable {
    case strength, powerlifting, olympic, strongman, plyometrics, cardio, stretching
    var title: String { L("category.\(rawValue)") }
}

enum ExerciseLevel: String, Codable {
    case beginner, intermediate, expert
    var title: String { L("level.\(rawValue)") }
}

enum SetKind: String, CaseIterable, Identifiable, Codable {
    case working, warmup, dropset, failure
    var id: String { rawValue }
    var title: String { L("kind.\(rawValue)") }
    var badge: String? {
        switch self {
        case .working: return nil
        case .warmup: return "W"
        case .dropset: return "D"
        case .failure: return "F"
        }
    }
}

enum UnitSystem: String, CaseIterable, Identifiable {
    case kg, lb
    var id: String { rawValue }
    var symbol: String { rawValue }
    private static let factor = 2.2046226218
    func fromKg(_ kg: Double) -> Double { self == .kg ? kg : kg * Self.factor }
    func toKg(_ value: Double) -> Double { self == .kg ? value : value / Self.factor }
}

enum AppAppearance: String, CaseIterable, Identifiable {
    case dark, light, system
    var id: String { rawValue }
    var title: String { L("settings.appearance.\(rawValue)") }
    var scheme: ColorScheme? {
        switch self {
        case .dark: return .dark
        case .light: return .light
        case .system: return nil
        }
    }
}
