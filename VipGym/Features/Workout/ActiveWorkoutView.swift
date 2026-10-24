import SwiftUI
import SwiftData

struct ActiveWorkoutView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Environment(WorkoutCoordinator.self) private var coordinator
    @State private var showPicker = false
    @State private var showFinish = false

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                Theme.bg.ignoresSafeArea()
                if let session = coordinator.activeSession {
                    ScrollView {
                        VStack(spacing: 16) {
                            header(session)
                            ForEach(session.sortedEntries) { entry in
                                EntryCard(entry: entry,
                                          session: session,
                                          onSetCompleted: { handleSetCompleted(entry, in: session) },
                                          onToggleSuperset: { toggleSuperset(entry, in: session) },
                                          onRemove: { remove(entry, from: session) })
                            }
                            Button { showPicker = true } label: {
                                Label(L("workout.add.exercise"), systemImage: "plus")
                            }
                            .buttonStyle(VGGhostButtonStyle())
                            Color.clear.frame(height: coordinator.isResting ? 110 : 20)
                        }
                        .padding(.horizontal, 16)
                        .padding(.top, 8)
                    }
                    .scrollDismissesKeyboard(.interactively)

                    if coordinator.isResting { RestBar().transition(.move(edge: .bottom).combined(with: .opacity)) }
                }
            }
            .animation(.snappy, value: coordinator.isResting)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button { dismiss() } label: { Image(systemName: "chevron.down") }
                        .tint(Theme.textPrimary)
                }
                ToolbarItem(placement: .principal) { VGWordmark(size: 17) }
                ToolbarItem(placement: .topBarTrailing) {
                    Button(L("workout.finish")) { showFinish = true }
                        .fontWeight(.semibold).tint(Theme.accent)
                }
            }
            .sheet(isPresented: $showPicker) {
                NavigationStack {
                    ExerciseListView(onPick: { addExercise($0) })
                }
                .presentationDetents([.large])
            }
            .confirmationDialog(L("workout.finish.title"), isPresented: $showFinish, titleVisibility: .visible) {
                Button(L("workout.finish.save")) { coordinator.finishWorkout(context: context) }
                Button(L("workout.finish.discard"), role: .destructive) { coordinator.discardWorkout(context: context) }
                Button(L("common.cancel"), role: .cancel) {}
            } message: { Text(L("workout.finish.message")) }
        }
    }

    private func header(_ session: WorkoutSession) -> some View {
        HStack(alignment: .firstTextBaseline) {
            VStack(alignment: .leading, spacing: 4) {
                VGSectionLabel(L("workout.time"))
                Text(session.startedAt, style: .timer)
                    .font(Theme.mono(34, .bold)).foregroundStyle(Theme.textPrimary).monospacedDigit()
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 4) {
                VGSectionLabel(L("workout.sets.done"))
                Text("\(session.completedSets.count)")
                    .font(Theme.mono(34, .bold)).foregroundStyle(Theme.accent)
            }
        }
        .padding(.horizontal, 4)
        .padding(.top, 4)
    }

    private func addExercise(_ exercise: Exercise) {
        guard let session = coordinator.activeSession else { return }
        let entry = WorkoutEntry(order: session.entries.count, exercise: exercise)
        context.insert(entry)
        session.entries.append(entry)

        let prev = HistoryService.previousSets(for: exercise, context: context).first
        let set = WorkoutSet(order: 0, weightKg: prev?.weightKg ?? 0, reps: prev?.reps ?? 0)
        context.insert(set)
        entry.sets.append(set)
        try? context.save()
        Haptics.tap()
    }

    private func handleSetCompleted(_ entry: WorkoutEntry, in session: WorkoutSession) {
        let name = entry.exercise?.displayName ?? ""
        coordinator.noteSetCompleted(exerciseName: name)
        // W superserii przerwa startuje dopiero po ostatnim ćwiczeniu z grupy.
        let sorted = session.sortedEntries
        if let g = entry.supersetGroup, let i = sorted.firstIndex(where: { $0.order == entry.order }),
           i + 1 < sorted.count, sorted[i + 1].supersetGroup == g { return }
        let seconds = entry.exercise?.restSecondsOverride ?? WorkoutCoordinator.defaultRestSeconds
        coordinator.startRest(seconds: seconds, exerciseName: name)
    }

    private func toggleSuperset(_ entry: WorkoutEntry, in session: WorkoutSession) {
        let sorted = session.sortedEntries
        guard let i = sorted.firstIndex(where: { $0.order == entry.order }) else { return }
        if entry.supersetGroup != nil { entry.supersetGroup = nil; return }
        guard i > 0 else { return }
        let prev = sorted[i - 1]
        if prev.supersetGroup == nil {
            prev.supersetGroup = (sorted.compactMap(\.supersetGroup).max() ?? 0) + 1
        }
        entry.supersetGroup = prev.supersetGroup
    }

    private func remove(_ entry: WorkoutEntry, from session: WorkoutSession) {
        context.delete(entry)
        for (i, e) in session.sortedEntries.filter({ $0.persistentModelID != entry.persistentModelID }).enumerated() { e.order = i }
        try? context.save()
    }
}

// MARK: - Pasek timera przerwy

struct RestBar: View {
    @Environment(WorkoutCoordinator.self) private var coordinator

    var body: some View {
        TimelineView(.periodic(from: .now, by: 0.5)) { timeline in
            let end = coordinator.restEndDate ?? timeline.date
            let start = coordinator.restStartDate ?? timeline.date
            let remaining = end.timeIntervalSince(timeline.date)
            let total = max(1, end.timeIntervalSince(start))
            let done = remaining <= 0

            VStack(spacing: 12) {
                HStack(alignment: .center) {
                    VStack(alignment: .leading, spacing: 2) {
                        VGSectionLabel(done ? L("rest.ready") : L("rest.title"))
                        Text(Fmt.clock(ceil(max(0, remaining))))
                            .font(Theme.mono(38, .bold))
                            .foregroundStyle(done ? Theme.success : Theme.textPrimary)
                            .contentTransition(.numericText())
                    }
                    Spacer()
                    HStack(spacing: 8) {
                        stepButton("-15") { coordinator.adjustRest(by: -15) }
                        stepButton("+15") { coordinator.adjustRest(by: 15) }
                        Button { coordinator.skipRest() } label: {
                            Image(systemName: done ? "xmark" : "forward.end.fill")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundStyle(Theme.onAccent)
                                .frame(width: 44, height: 40)
                                .background(Theme.accent, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                        }
                    }
                }
                ProgressView(value: min(1, max(0, 1 - remaining / total)))
                    .tint(done ? Theme.success : Theme.accent)
            }
            .padding(16)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 24, style: .continuous).strokeBorder(Theme.stroke, lineWidth: 0.5))
            .padding(.horizontal, 12)
            .padding(.bottom, 8)
        }
    }

    private func stepButton(_ title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title).font(Theme.mono(14, .bold)).foregroundStyle(Theme.textPrimary)
                .frame(width: 48, height: 40)
                .background(Theme.surfaceHigh, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
        }
    }
}
