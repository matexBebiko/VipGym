import ActivityKit
import Foundation

/// Współdzielone między aplikacją a rozszerzeniem Live Activity.
struct WorkoutActivityAttributes: ActivityAttributes {
    struct ContentState: Codable, Hashable {
        var workoutStartedAt: Date
        var restStartedAt: Date?
        var restEndsAt: Date?
        var exerciseName: String
        var setsCompleted: Int
    }

    var workoutTitle: String
    var labelRest: String
    var labelWorkout: String
    var labelSets: String
}
