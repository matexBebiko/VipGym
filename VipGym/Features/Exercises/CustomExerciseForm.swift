import SwiftUI
import SwiftData

struct CustomExerciseForm: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    @State private var primary: MuscleGroup = .chest
    @State private var equipment: Equipment = .barbell
    @State private var secondary: Set<MuscleGroup> = []

    var body: some View {
        NavigationStack {
            Form {
                Section(L("custom.name")) {
                    TextField(L("custom.name.placeholder"), text: $name)
                }
                Section {
                    Picker(L("custom.primary"), selection: $primary) {
                        ForEach(MuscleGroup.allCases) { Text($0.title).tag($0) }
                    }
                    Picker(L("custom.equipment"), selection: $equipment) {
                        ForEach(Equipment.allCases) { Text($0.title).tag($0) }
                    }
                }
                Section(L("custom.secondary")) {
                    ForEach(MuscleGroup.allCases.filter { $0 != primary }) { m in
                        Button {
                            if secondary.contains(m) { secondary.remove(m) } else { secondary.insert(m) }
                        } label: {
                            HStack {
                                Text(m.title).foregroundStyle(Theme.textPrimary)
                                Spacer()
                                if secondary.contains(m) { Image(systemName: "checkmark").foregroundStyle(Theme.accent) }
                            }
                        }
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .background(Theme.bg.ignoresSafeArea())
            .navigationTitle(L("custom.title"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) { Button(L("common.cancel")) { dismiss() } }
                ToolbarItem(placement: .topBarTrailing) {
                    Button(L("common.save")) { save() }
                        .fontWeight(.semibold)
                        .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
        .tint(Theme.accent)
    }

    private func save() {
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        let e = Exercise(id: "custom_\(UUID().uuidString)", nameEN: trimmed, namePL: nil,
                         primary: primary, secondary: Array(secondary), equipment: equipment, isCustom: true)
        context.insert(e)
        try? context.save()
        dismiss()
    }
}
