import SwiftUI
import SwiftData

struct WorkoutHomeView: View {
    @Environment(\.modelContext) private var context
    @Environment(WorkoutCoordinator.self) private var coordinator
    @AppStorage("unitSystem") private var unitRaw = UnitSystem.kg.rawValue
    @Query(filter: #Predicate<WorkoutSession> { $0.endedAt != nil },
           sort: \WorkoutSession.startedAt, order: .reverse) private var sessions: [WorkoutSession]

    private var unit: UnitSystem { UnitSystem(rawValue: unitRaw) ?? .kg }

    private var lastWeek: [WorkoutSession] {
        let from = Calendar.current.date(byAdding: .day, value: -7, to: .now) ?? .now
        return sessions.filter { $0.startedAt >= from }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    heroCard

                    HStack(spacing: 12) {
                        VGStatTile(label: L("home.stat.sessions"), value: "\(lastWeek.count)")
                        VGStatTile(label: L("home.stat.volume"),
                                   value: Fmt.volume(lastWeek.reduce(0) { $0 + $1.totalVolumeKg }, unit: unit),
                                   unit: unit.symbol)
                    }

                    VGSectionLabel(L("home.history"))
                    if sessions.isEmpty {
                        Text(L("home.history.empty"))
                            .font(.system(size: 15)).foregroundStyle(Theme.textSecondary)
                            .frame(maxWidth: .infinity, alignment: .leading).vgCard()
                    } else {
                        VStack(spacing: 10) {
                            ForEach(sessions.prefix(30)) { s in
                                NavigationLink(value: s) { SessionRow(session: s, unit: unit) }
                                    .buttonStyle(.plain)
                            }
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
            }
            .background(Theme.bg.ignoresSafeArea())
            .toolbar { ToolbarItem(placement: .principal) { VGWordmark(size: 19) } }
            .navigationBarTitleDisplayMode(.inline)
            .navigationDestination(for: WorkoutSession.self) { SessionDetailView(session: $0) }
        }
    }

    @ViewBuilder private var heroCard: some View {
        if let s = coordinator.activeSession {
            VStack(alignment: .leading, spacing: 14) {
                VGSectionLabel(L("home.active"))
                HStack(alignment: .firstTextBaseline) {
                    Text(s.startedAt, style: .timer)
                        .font(Theme.mono(40, .bold)).foregroundStyle(Theme.textPrimary)
                        .monospacedDigit()
                    Spacer()
                    Text("\(s.completedSets.count) \(L("home.sets"))")
                        .font(.system(size: 14, weight: .medium)).foregroundStyle(Theme.textSecondary)
                }
                Button(L("home.resume")) { coordinator.isPresentingWorkout = true }
                    .buttonStyle(VGPrimaryButtonStyle())
            }
            .vgCard(padding: 20)
        } else {
            VStack(alignment: .leading, spacing: 14) {
                Text(L("home.ready")).font(.system(size: 26, weight: .bold)).foregroundStyle(Theme.textPrimary)
                Text(L("home.ready.sub")).font(.system(size: 15)).foregroundStyle(Theme.textSecondary)
                Button(L("home.start")) { coordinator.startWorkout(context: context) }
                    .buttonStyle(VGPrimaryButtonStyle())
                    .padding(.top, 4)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .vgCard(padding: 20)
        }
    }
}

struct SessionRow: View {
    let session: WorkoutSession
    let unit: UnitSystem

    var body: some View {
        HStack(spacing: 14) {
            VStack(alignment: .leading, spacing: 4) {
                Text(session.title).font(.system(size: 17, weight: .semibold)).foregroundStyle(Theme.textPrimary)
                Text(session.startedAt, format: .dateTime.day().month(.abbreviated).year().hour().minute())
                    .font(.system(size: 13)).foregroundStyle(Theme.textSecondary)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 4) {
                Text("\(Fmt.volume(session.totalVolumeKg, unit: unit)) \(unit.symbol)")
                    .font(Theme.mono(14)).foregroundStyle(Theme.accent)
                Text(Fmt.shortDuration(session.duration))
                    .font(.system(size: 13)).foregroundStyle(Theme.textSecondary)
            }
            Image(systemName: "chevron.right").font(.system(size: 12, weight: .semibold)).foregroundStyle(Theme.textSecondary)
        }
        .vgCard()
    }
}
