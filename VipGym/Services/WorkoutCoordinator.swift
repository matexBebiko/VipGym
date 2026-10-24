import SwiftUI
import SwiftData
import ActivityKit
import UserNotifications

/// Steruje aktywnym treningiem: sesja, timer przerwy, powiadomienie i Live Activity na ekranie blokady.
@MainActor @Observable
final class WorkoutCoordinator {
    var activeSession: WorkoutSession?
    var isPresentingWorkout = false
    var restStartDate: Date?
    var restEndDate: Date?
    var currentExerciseName = ""

    @ObservationIgnored private var activity: Activity<WorkoutActivityAttributes>?
    @ObservationIgnored private var restTask: Task<Void, Never>?
    @ObservationIgnored private let notificationID = "vipgym.rest.finished"
    @ObservationIgnored private let defaults = UserDefaults.standard

    static var defaultRestSeconds: Int {
        let v = UserDefaults.standard.integer(forKey: "defaultRestSeconds")
        return v > 0 ? v : 240
    }

    var isResting: Bool { restEndDate != nil }
    var setsCompleted: Int { activeSession?.completedSets.count ?? 0 }

    // MARK: Sesja

    /// Po restarcie aplikacji wznawia niezakończony trening.
    func recover(context: ModelContext) {
        guard activeSession == nil else { return }
        var d = FetchDescriptor<WorkoutSession>(
            predicate: #Predicate { $0.endedAt == nil },
            sortBy: [SortDescriptor(\.startedAt, order: .reverse)])
        d.fetchLimit = 1
        guard let s = try? context.fetch(d).first else { return }
        activeSession = s
        let end = defaults.double(forKey: "restEndDate"), start = defaults.double(forKey: "restStartDate")
        if end > Date.now.timeIntervalSince1970, start > 0, start < end {
            restStartDate = Date(timeIntervalSince1970: start)
            restEndDate = Date(timeIntervalSince1970: end)
        }
        attachOrStartActivity()
    }

    func startWorkout(context: ModelContext, from template: WorkoutSession? = nil) {
        guard activeSession == nil else { isPresentingWorkout = true; return }
        let weekday = Date.now.formatted(Date.FormatStyle().weekday(.wide).locale(Localizer.locale)).capitalized
        let s = WorkoutSession(title: weekday)
        context.insert(s)

        if let template {
            for (i, old) in template.sortedEntries.enumerated() {
                guard let ex = old.exercise else { continue }
                let e = WorkoutEntry(order: i, exercise: ex)
                e.supersetGroup = old.supersetGroup
                context.insert(e)
                s.entries.append(e)
                let prev = old.sortedSets.filter { $0.isCompleted && $0.kind != .warmup }
                for (j, p) in prev.enumerated() {
                    let set = WorkoutSet(order: j, weightKg: p.weightKg, reps: p.reps)
                    context.insert(set)
                    e.sets.append(set)
                }
            }
        }
        try? context.save()
        activeSession = s
        isPresentingWorkout = true
        requestNotificationPermission()
        attachOrStartActivity()
    }

    /// Kończy trening: usuwa niezatwierdzone serie i puste ćwiczenia.
    func finishWorkout(context: ModelContext) {
        guard let s = activeSession else { return }
        for entry in s.entries {
            for set in entry.sets where !set.isCompleted { context.delete(set) }
        }
        for entry in s.entries where entry.sets.allSatisfy({ !$0.isCompleted }) { context.delete(entry) }
        if s.entries.allSatisfy({ $0.sets.allSatisfy({ !$0.isCompleted }) }) {
            context.delete(s)
        } else {
            s.endedAt = .now
        }
        try? context.save()
        tearDown()
    }

    func discardWorkout(context: ModelContext) {
        guard let s = activeSession else { return }
        context.delete(s)
        try? context.save()
        tearDown()
    }

    private func tearDown() {
        skipRest(updateActivity: false)
        endActivity()
        activeSession = nil
        isPresentingWorkout = false
        currentExerciseName = ""
    }

    // MARK: Timer przerwy

    func startRest(seconds: Int, exerciseName: String) {
        currentExerciseName = exerciseName
        let start = Date.now
        applyRest(start: start, end: start.addingTimeInterval(Double(max(5, seconds))))
    }

    func adjustRest(by delta: Int) {
        guard let start = restStartDate, let end = restEndDate else { return }
        let newEnd = end.addingTimeInterval(Double(delta))
        if newEnd.timeIntervalSinceNow <= 1 { skipRest(); return }
        applyRest(start: min(start, .now), end: newEnd)
    }

    func skipRest(updateActivity: Bool = true) {
        restTask?.cancel()
        restStartDate = nil
        restEndDate = nil
        defaults.removeObject(forKey: "restEndDate")
        defaults.removeObject(forKey: "restStartDate")
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [notificationID])
        if updateActivity { pushUpdate() }
    }

    func noteSetCompleted(exerciseName: String) {
        currentExerciseName = exerciseName
        if !isResting { pushUpdate() }
    }

    private func applyRest(start: Date, end: Date) {
        restStartDate = start
        restEndDate = end
        defaults.set(start.timeIntervalSince1970, forKey: "restStartDate")
        defaults.set(end.timeIntervalSince1970, forKey: "restEndDate")
        scheduleNotification(after: end.timeIntervalSinceNow)
        pushUpdate()

        restTask?.cancel()
        restTask = Task { [weak self] in
            try? await Task.sleep(for: .seconds(max(0, end.timeIntervalSinceNow)))
            guard !Task.isCancelled, let self, self.restEndDate == end else { return }
            Haptics.success()
        }
    }

    // MARK: Powiadomienia

    private func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { _, _ in }
    }

    private func scheduleNotification(after seconds: TimeInterval) {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: [notificationID])
        let content = UNMutableNotificationContent()
        content.title = L("notif.rest.title")
        content.body = L("notif.rest.body")
        content.sound = .default
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: max(1, seconds), repeats: false)
        center.add(UNNotificationRequest(identifier: notificationID, content: content, trigger: trigger))
    }

    // MARK: Live Activity

    private func makeState() -> WorkoutActivityAttributes.ContentState? {
        guard let s = activeSession else { return nil }
        return .init(workoutStartedAt: s.startedAt, restStartedAt: restStartDate, restEndsAt: restEndDate,
                     exerciseName: currentExerciseName, setsCompleted: setsCompleted)
    }

    private func attachOrStartActivity() {
        guard ActivityAuthorizationInfo().areActivitiesEnabled, let state = makeState(),
              let s = activeSession else { return }
        if let existing = Activity<WorkoutActivityAttributes>.activities.first {
            activity = existing
            pushUpdate()
            return
        }
        let attrs = WorkoutActivityAttributes(workoutTitle: s.title, labelRest: L("live.rest"),
                                              labelWorkout: L("live.workout"), labelSets: L("live.sets"))
        activity = try? Activity.request(attributes: attrs,
                                         content: ActivityContent(state: state, staleDate: nil))
    }

    private func pushUpdate() {
        guard let activity, let state = makeState() else { return }
        Task { await activity.update(ActivityContent(state: state, staleDate: nil)) }
    }

    private func endActivity() {
        let all = Activity<WorkoutActivityAttributes>.activities
        activity = nil
        Task {
            for a in all { await a.end(nil, dismissalPolicy: .immediate) }
        }
    }
}
