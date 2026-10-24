import Foundation
import SwiftData

struct PreviousSet {
    let weightKg: Double
    let reps: Int
    let rir: Int?
}

/// Czysta logika treningowa, bez zależności od UI.
enum ProgressionEngine {
    /// Szacowane 1RM wzorem Epleya. RIR dolicza "powtórzenia w zapasie" do realnej liczby powtórzeń.
    static func estimatedOneRM(weightKg: Double, reps: Int, rir: Int?) -> Double? {
        guard weightKg > 0, reps > 0 else { return nil }
        let effective = reps + max(0, rir ?? 0)
        if effective <= 1 { return weightKg }
        return weightKg * (1 + Double(effective) / 30)
    }

    /// Objętość = suma (ciężar × powtórzenia) z serii roboczych (bez rozgrzewki).
    static func volume(of sets: [WorkoutSet]) -> Double {
        sets.filter { $0.isCompleted && $0.kind != .warmup }.reduce(0) { $0 + $1.weightKg * Double($1.reps) }
    }

    static func bestOneRM(in sets: [WorkoutSet]) -> Double? {
        sets.filter { $0.isCompleted && $0.kind != .warmup }
            .compactMap { estimatedOneRM(weightKg: $0.weightKg, reps: $0.reps, rir: $0.rir) }
            .max()
    }
}

enum HistoryService {
    /// Serie robocze z ostatniego zakończonego treningu, w którym wystąpiło dane ćwiczenie.
    static func previousSets(for exercise: Exercise, context: ModelContext) -> [PreviousSet] {
        var descriptor = FetchDescriptor<WorkoutSession>(
            predicate: #Predicate { $0.endedAt != nil },
            sortBy: [SortDescriptor(\.startedAt, order: .reverse)])
        descriptor.fetchLimit = 80
        guard let sessions = try? context.fetch(descriptor) else { return [] }
        for session in sessions {
            guard let entry = session.entries.first(where: { $0.exercise?.id == exercise.id }) else { continue }
            let sets = entry.sortedSets.filter { $0.isCompleted && $0.kind != .warmup }
            if !sets.isEmpty { return sets.map { PreviousSet(weightKg: $0.weightKg, reps: $0.reps, rir: $0.rir) } }
        }
        return []
    }
}
