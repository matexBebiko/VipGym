import SwiftUI
import SwiftData

struct SessionDetailView: View {
    let session: WorkoutSession
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Environment(WorkoutCoordinator.self) private var coordinator
    @AppStorage("unitSystem") private var unitRaw = UnitSystem.kg.rawValue
    @State private var confirmDelete = false

    private var unit: UnitSystem { UnitSystem(rawValue: unitRaw) ?? .kg }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                HStack(spacing: 12) {
                    VGStatTile(label: L("detail.volume"), value: Fmt.volume(session.totalVolumeKg, unit: unit), unit: unit.symbol)
                    VGStatTile(label: L("detail.duration"), value: Fmt.shortDuration(session.duration))
                }

                ForEach(session.sortedEntries) { entry in
                    VStack(alignment: .leading, spacing: 10) {
                        Text(entry.exercise?.displayName ?? L("exercise.deleted"))
                            .font(.system(size: 17, weight: .semibold)).foregroundStyle(Theme.accent)
                        ForEach(Array(entry.sortedSets.filter(\.isCompleted).enumerated()), id: \.element.persistentModelID) { i, set in
                            HStack {
                                Text(set.kind.badge ?? "\(i + 1)")
                                    .font(Theme.mono(13)).foregroundStyle(Theme.textSecondary).frame(width: 28, alignment: .leading)
                                Text("\(Fmt.weight(set.weightKg, unit: unit)) \(unit.symbol) × \(set.reps)")
                                    .font(Theme.mono(16)).foregroundStyle(Theme.textPrimary)
                                Spacer()
                                if let rir = set.rir {
                                    Text("RIR \(rir)").font(Theme.mono(13)).foregroundStyle(Theme.textSecondary)
                                }
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .vgCard()
                }

                Button(L("detail.repeat")) {
                    coordinator.startWorkout(context: context, from: session)
                }
                .buttonStyle(VGGhostButtonStyle())
                .disabled(coordinator.activeSession != nil)

                Button(L("detail.delete"), role: .destructive) { confirmDelete = true }
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(Theme.danger)
                    .frame(maxWidth: .infinity)
                    .padding(.top, 4)
            }
            .padding(20)
        }
        .background(Theme.bg.ignoresSafeArea())
        .navigationTitle(session.title)
        .navigationBarTitleDisplayMode(.inline)
        .confirmationDialog(L("detail.delete.confirm"), isPresented: $confirmDelete, titleVisibility: .visible) {
            Button(L("detail.delete"), role: .destructive) {
                context.delete(session)
                try? context.save()
                dismiss()
            }
        }
    }
}
