import SwiftUI
import SwiftData

struct SetRowView: View {
    @Bindable var set: WorkoutSet
    let label: String
    let previous: String
    let onCompleted: () -> Void
    let onDelete: () -> Void

    @AppStorage("unitSystem") private var unitRaw = UnitSystem.kg.rawValue
    @State private var weightText = ""
    @State private var repsText = ""

    private var unit: UnitSystem { UnitSystem(rawValue: unitRaw) ?? .kg }

    var body: some View {
        HStack(spacing: 8) {
            kindMenu.frame(width: 30)

            Text(previous)
                .font(Theme.mono(12, .regular)).foregroundStyle(Theme.textSecondary)
                .lineLimit(1).minimumScaleFactor(0.6)
                .frame(width: 64, alignment: .leading)

            inputField($weightText, placeholder: "0", keyboard: .decimalPad)
            inputField($repsText, placeholder: "0", keyboard: .numberPad)
            rirMenu.frame(width: 46)
            checkButton
        }
        .padding(.vertical, 2)
        .padding(.horizontal, 4)
        .background(set.isCompleted ? Theme.accentSoft : .clear, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .onAppear(perform: loadTexts)
        .onChange(of: weightText) { _, new in
            let value = Double(new.replacingOccurrences(of: ",", with: ".")) ?? 0
            guard new != Fmt.weight(set.weightKg, unit: unit) || set.weightKg == 0 else { return }
            set.weightKg = max(0, unit.toKg(value))
        }
        .onChange(of: repsText) { _, new in set.reps = max(0, Int(new) ?? 0) }
    }

    private func loadTexts() {
        weightText = set.weightKg > 0 ? Fmt.weight(set.weightKg, unit: unit) : ""
        repsText = set.reps > 0 ? "\(set.reps)" : ""
    }

    private func inputField(_ text: Binding<String>, placeholder: String, keyboard: UIKeyboardType) -> some View {
        TextField("", text: text, prompt: Text(placeholder).foregroundStyle(Theme.textSecondary.opacity(0.5)))
            .keyboardType(keyboard)
            .multilineTextAlignment(.center)
            .font(Theme.mono(17, .semibold))
            .foregroundStyle(Theme.textPrimary)
            .frame(maxWidth: .infinity)
            .frame(height: 40)
            .background(Theme.surfaceHigh, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
    }

    private var kindMenu: some View {
        Menu {
            Picker(L("workout.set.type"), selection: $set.kind) {
                ForEach(SetKind.allCases) { Text($0.title).tag($0) }
            }
            Button(L("workout.set.delete"), systemImage: "trash", role: .destructive) { onDelete() }
        } label: {
            Text(label)
                .font(Theme.mono(14, .bold))
                .foregroundStyle(set.kind == .working ? Theme.textSecondary : Theme.accent)
                .frame(width: 30, height: 40)
        }
    }

    private var rirMenu: some View {
        Menu {
            Button("–") { set.rir = nil }
            ForEach(0...5, id: \.self) { v in Button("\(v)") { set.rir = v } }
        } label: {
            Text(set.rir.map(String.init) ?? "–")
                .font(Theme.mono(16, .semibold))
                .foregroundStyle(rirColor)
                .frame(width: 46, height: 40)
                .background(Theme.surfaceHigh, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
        }
    }

    private var rirColor: Color {
        guard let r = set.rir else { return Theme.textSecondary }
        return r <= 1 ? Theme.danger : (r <= 3 ? Theme.accent : Theme.textPrimary)
    }

    private var checkButton: some View {
        Button {
            if set.isCompleted {
                set.isCompleted = false
                set.completedAt = nil
            } else {
                guard set.reps > 0 else { Haptics.warning(); return }
                set.isCompleted = true
                set.completedAt = .now
                Haptics.success()
                onCompleted()
            }
        } label: {
            Image(systemName: "checkmark")
                .font(.system(size: 15, weight: .bold))
                .foregroundStyle(set.isCompleted ? Theme.onAccent : Theme.textSecondary)
                .frame(width: 40, height: 40)
                .background(set.isCompleted ? Theme.accent : Theme.surfaceHigh,
                            in: RoundedRectangle(cornerRadius: 10, style: .continuous))
        }
    }
}
