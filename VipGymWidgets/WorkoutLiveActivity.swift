import ActivityKit
import SwiftUI
import WidgetKit

private enum LiveColor {
    static let gold = Color(red: 0.831, green: 0.698, blue: 0.416)
    static let bg = Color(red: 0.039, green: 0.043, blue: 0.051)
    static let dim = Color(red: 0.55, green: 0.57, blue: 0.61)
}

private extension WorkoutActivityAttributes.ContentState {
    /// Zakres zawsze poprawny (start <= end), żeby Text(timerInterval:) nie wywalił się.
    var restRange: ClosedRange<Date>? {
        guard let s = restStartedAt, let e = restEndsAt, s < e else { return nil }
        return s...e
    }
}

struct WorkoutLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: WorkoutActivityAttributes.self) { context in
            LockScreenView(attributes: context.attributes, state: context.state)
                .activityBackgroundTint(LiveColor.bg)
                .activitySystemActionForegroundColor(LiveColor.gold)
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(context.attributes.labelWorkout.uppercased()).font(.system(size: 10, weight: .semibold)).foregroundStyle(LiveColor.dim)
                        Text(timerInterval: context.state.workoutStartedAt...Date.distantFuture, countsDown: false)
                            .font(.system(size: 20, weight: .bold, design: .monospaced)).frame(width: 80, alignment: .leading)
                    }
                }
                DynamicIslandExpandedRegion(.trailing) {
                    if let range = context.state.restRange {
                        VStack(alignment: .trailing, spacing: 2) {
                            Text(context.attributes.labelRest.uppercased()).font(.system(size: 10, weight: .semibold)).foregroundStyle(LiveColor.dim)
                            Text(timerInterval: range, countsDown: true)
                                .font(.system(size: 20, weight: .bold, design: .monospaced)).foregroundStyle(LiveColor.gold)
                                .multilineTextAlignment(.trailing).frame(width: 80, alignment: .trailing)
                        }
                    } else {
                        Text("\(context.state.setsCompleted) \(context.attributes.labelSets)")
                            .font(.system(size: 14, weight: .semibold, design: .monospaced)).foregroundStyle(LiveColor.gold)
                    }
                }
                DynamicIslandExpandedRegion(.bottom) {
                    if let range = context.state.restRange {
                        ProgressView(timerInterval: range, countsDown: true) { EmptyView() } currentValueLabel: { EmptyView() }
                            .tint(LiveColor.gold)
                    } else if !context.state.exerciseName.isEmpty {
                        Text(context.state.exerciseName).font(.system(size: 13)).foregroundStyle(LiveColor.dim).lineLimit(1)
                    }
                }
            } compactLeading: {
                Text("VIP").font(.system(size: 12, weight: .heavy)).foregroundStyle(LiveColor.gold)
            } compactTrailing: {
                if let range = context.state.restRange {
                    Text(timerInterval: range, countsDown: true)
                        .font(.system(size: 13, weight: .bold, design: .monospaced)).foregroundStyle(LiveColor.gold)
                        .frame(width: 44)
                } else {
                    Text(timerInterval: context.state.workoutStartedAt...Date.distantFuture, countsDown: false)
                        .font(.system(size: 13, weight: .bold, design: .monospaced)).frame(width: 44)
                }
            } minimal: {
                Text("V").font(.system(size: 13, weight: .heavy)).foregroundStyle(LiveColor.gold)
            }
        }
    }
}

private struct LockScreenView: View {
    let attributes: WorkoutActivityAttributes
    let state: WorkoutActivityAttributes.ContentState

    var body: some View {
        VStack(spacing: 14) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 0) {
                        Text("VIP").foregroundStyle(.white)
                        Text("GYM").foregroundStyle(LiveColor.gold)
                    }
                    .font(.system(size: 13, weight: .heavy)).tracking(2.4)
                    Text(attributes.labelWorkout.uppercased())
                        .font(.system(size: 10, weight: .semibold)).tracking(1.4).foregroundStyle(LiveColor.dim)
                    Text(timerInterval: state.workoutStartedAt...Date.distantFuture, countsDown: false)
                        .font(.system(size: 26, weight: .bold, design: .monospaced)).foregroundStyle(.white)
                        .frame(width: 130, alignment: .leading)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 4) {
                    Text(attributes.labelSets.uppercased())
                        .font(.system(size: 10, weight: .semibold)).tracking(1.4).foregroundStyle(LiveColor.dim)
                    Text("\(state.setsCompleted)")
                        .font(.system(size: 26, weight: .bold, design: .monospaced)).foregroundStyle(LiveColor.gold)
                }
            }

            if let range = state.restRange {
                VStack(spacing: 8) {
                    HStack(alignment: .firstTextBaseline) {
                        Text(attributes.labelRest.uppercased())
                            .font(.system(size: 11, weight: .semibold)).tracking(1.4).foregroundStyle(LiveColor.dim)
                        Spacer()
                        Text(timerInterval: range, countsDown: true)
                            .font(.system(size: 40, weight: .bold, design: .monospaced)).foregroundStyle(LiveColor.gold)
                            .multilineTextAlignment(.trailing).frame(width: 150, alignment: .trailing)
                    }
                    ProgressView(timerInterval: range, countsDown: true) { EmptyView() } currentValueLabel: { EmptyView() }
                        .tint(LiveColor.gold)
                }
            } else if !state.exerciseName.isEmpty {
                Text(state.exerciseName)
                    .font(.system(size: 14, weight: .medium)).foregroundStyle(LiveColor.dim)
                    .frame(maxWidth: .infinity, alignment: .leading).lineLimit(1)
            }
        }
        .padding(16)
    }
}
