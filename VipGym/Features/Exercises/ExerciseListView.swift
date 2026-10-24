import SwiftUI
import SwiftData

struct ExercisesView: View {
    var body: some View {
        NavigationStack {
            ExerciseListView()
                .navigationDestination(for: Exercise.self) { ExerciseDetailView(exercise: $0) }
        }
    }
}

/// Lista ćwiczeń: tryb przeglądania (onPick == nil) albo wybierania do treningu.
struct ExerciseListView: View {
    var onPick: ((Exercise) -> Void)? = nil

    @Environment(\.dismiss) private var dismiss
    @Query(sort: \Exercise.nameEN) private var all: [Exercise]
    @State private var search = ""
    @State private var muscle: MuscleGroup? = nil
    @State private var showForm = false

    private var filtered: [Exercise] {
        let q = search.trimmingCharacters(in: .whitespaces)
        return all.filter { e in
            (muscle == nil || e.primaryMuscle == muscle)
            && (q.isEmpty || e.nameEN.localizedStandardContains(q) || (e.namePL?.localizedStandardContains(q) ?? false))
        }
        .sorted { a, b in
            if a.isFavorite != b.isFavorite { return a.isFavorite }
            return a.displayName.localizedStandardCompare(b.displayName) == .orderedAscending
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    Button { muscle = nil } label: { VGChip(title: L("filter.all"), selected: muscle == nil) }
                    ForEach(MuscleGroup.allCases) { m in
                        Button { muscle = (muscle == m ? nil : m) } label: { VGChip(title: m.title, selected: muscle == m) }
                    }
                }
                .padding(.horizontal, 16).padding(.vertical, 10)
            }

            List {
                ForEach(filtered) { e in
                    Group {
                        if let onPick {
                            Button { onPick(e); dismiss() } label: { row(e) }
                        } else {
                            NavigationLink(value: e) { row(e) }
                        }
                    }
                    .listRowBackground(Theme.surface)
                    .listRowSeparatorTint(Theme.stroke)
                }
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
            .overlay {
                if filtered.isEmpty {
                    Text(L("exercises.empty")).foregroundStyle(Theme.textSecondary)
                }
            }
        }
        .background(Theme.bg.ignoresSafeArea())
        .navigationTitle(L(onPick == nil ? "tab.exercises" : "picker.title"))
        .navigationBarTitleDisplayMode(.inline)
        .searchable(text: $search, prompt: L("exercises.search"))
        .toolbar {
            if onPick != nil {
                ToolbarItem(placement: .topBarLeading) { Button(L("common.cancel")) { dismiss() } }
            }
            ToolbarItem(placement: .topBarTrailing) {
                Button { showForm = true } label: { Image(systemName: "plus") }.tint(Theme.accent)
            }
        }
        .sheet(isPresented: $showForm) { CustomExerciseForm() }
    }

    private func row(_ e: Exercise) -> some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 3) {
                Text(e.displayName).font(.system(size: 16, weight: .medium)).foregroundStyle(Theme.textPrimary)
                Text("\(e.primaryMuscle.title) · \(e.equipment.title)")
                    .font(.system(size: 13)).foregroundStyle(Theme.textSecondary)
            }
            Spacer()
            if e.isFavorite { Image(systemName: "star.fill").font(.system(size: 12)).foregroundStyle(Theme.accent) }
            if e.isCustom {
                Text(L("exercise.custom").uppercased(with: Localizer.locale))
                    .font(.system(size: 9, weight: .bold)).tracking(1).foregroundStyle(Theme.accent)
                    .padding(.horizontal, 6).padding(.vertical, 3)
                    .background(Theme.accentSoft, in: Capsule())
            }
        }
        .contentShape(Rectangle())
    }
}
