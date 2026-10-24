import SwiftUI
import SwiftData

struct EntryCard: View {
    @Bindable var entry: WorkoutEntry
    let session: WorkoutSession
    let onSetCompleted: () -> Void
    let onToggleSuperset: () -> Void
    let onRemove: () -> Void

    @Environment(\.modelContext) private var context
    @AppStorage("unitSystem") private var unitRaw = UnitSystem.kg.rawValue
    @State private var previous: [PreviousSet] = []

    private var unit: UnitSystem { UnitSystem(rawValue: unitRaw) ?? .kg }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            header
            columnHeaders
            ForEach(Array(entry.sortedSets.enumerated()), id: \.element.persistentModelID) { _, set in
                SetRowView(set: set,
                           label: label(for: set),
                           previous: previousText(for: set),
                           onCompleted: onSetCompleted,
                           onDelete: { delete(set) })
            }
            Button { addSet() } label: {
                Label(L("workout.add.set"), systemImage: "plus").font(.system(size: 14, weight: .semibold))
            }
            .buttonStyle(VGGhostButtonStyle())
        }
        .vgCard()
        .overlay(alignment: .leading) {
            if entry.supersetGroup != nil {
                RoundedRectangle(cornerRadius: 2).fill(Theme.accent).frame(width: 3).padding(.vertical, 18)
                    .offset(x: -0.5)
            }
        }
        .task(id: entry.exercise?.id) {
            if let ex = entry.exercise { previous = HistoryService.previousSets(for: ex, context: context) }
        }
    }

    private var header: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 4) {
                if let g = entry.supersetGroup {
                    Text("\(L("workout.superset")) \(g)".uppercased(with: Localizer.locale))
                        .font(.system(size: 10, weight: .bold)).tracking(1.4).foregroundStyle(Theme.accent)
                }
                Text(entry.exercise?.displayName ?? L("exercise.deleted"))
                    .font(.system(size: 18, weight: .semibold)).foregroundStyle(Theme.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)
                if let m = entry.exercise?.primaryMuscle {
                    Text(m.title).font(.system(size: 13)).foregroundStyle(Theme.textSecondary)
                }
            }
            Spacer()
            Menu {
                Button(entry.supersetGroup == nil ? L("workout.superset.link") : L("workout.superset.unlink"),
                       systemImage: "link") { onToggleSuperset() }
                Button(L("workout.remove.exercise"), systemImage: "trash", role: .destructive) { onRemove() }
            } label: {
                Image(systemName: "ellipsis").font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(Theme.textSecondary).frame(width: 36, height: 36)
            }
        }
    }

    private var columnHeaders: some View {
        HStack(spacing: 8) {
            Text("#").frame(width: 30)
            Text(L("workout.col.prev")).frame(width: 64, alignment: .leading)
            Text(unit.symbol.uppercased()).frame(maxWidth: .infinity)
            Text(L("workout.col.reps")).frame(maxWidth: .infinity)
            Text("RIR").frame(width: 46)
            Color.clear.frame(width: 40, height: 1)
        }
        .font(.system(size: 10, weight: .semibold)).tracking(1.2)
        .foregroundStyle(Theme.textSecondary)
    }

    /// Numeracja tylko serii roboczych; rozgrzewka/dropset/upadek dostają literę.
    private func label(for set: WorkoutSet) -> String {
        if let b = set.kind.badge { return b }
        let n = entry.sortedSets.filter { $0.kind != .warmup }.firstIndex { $0.persistentModelID == set.persistentModelID } ?? 0
        return "\(n + 1)"
    }

    private func previousText(for set: WorkoutSet) -> String {
        let working = entry.sortedSets.filter { $0.kind != .warmup }
        guard set.kind != .warmup,
              let idx = working.firstIndex(where: { $0.persistentModelID == set.persistentModelID }),
              idx < previous.count else { return "–" }
        let p = previous[idx]
        return "\(Fmt.weight(p.weightKg, unit: unit))×\(p.reps)"
    }

    private func addSet() {
        let last = entry.sortedSets.last
        let ref: PreviousSet? = last == nil ? previous.first : nil
        let set = WorkoutSet(order: entry.sets.count,
                             weightKg: last?.weightKg ?? ref?.weightKg ?? 0,
                             reps: last?.reps ?? ref?.reps ?? 0)
        context.insert(set)
        entry.sets.append(set)
        Haptics.tap()
    }

    private func delete(_ set: WorkoutSet) {
        let id = set.persistentModelID
        context.delete(set)
        for (i, s) in entry.sortedSets.filter({ $0.persistentModelID != id }).enumerated() { s.order = i }
    }
}
