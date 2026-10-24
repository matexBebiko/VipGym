import SwiftUI
import SwiftData
import PhotosUI

struct ExerciseDetailView: View {
    @Bindable var exercise: Exercise
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @AppStorage("unitSystem") private var unitRaw = UnitSystem.kg.rawValue
    @Query private var entries: [WorkoutEntry]
    @State private var pickerItem: PhotosPickerItem?
    @State private var confirmDelete = false

    init(exercise: Exercise) {
        self.exercise = exercise
        let id = exercise.id
        _entries = Query(filter: #Predicate<WorkoutEntry> { $0.exercise?.id == id })
    }

    private var unit: UnitSystem { UnitSystem(rawValue: unitRaw) ?? .kg }

    private var doneSets: [WorkoutSet] {
        entries.filter { $0.session?.endedAt != nil }.flatMap(\.sets).filter { $0.isCompleted && $0.kind != .warmup }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                tags
                stats
                photos
                restOverride
                if !exercise.instructions.isEmpty { instructions }
                if exercise.isCustom {
                    Button(L("detail.delete"), role: .destructive) { confirmDelete = true }
                        .foregroundStyle(Theme.danger).frame(maxWidth: .infinity)
                }
            }
            .padding(20)
        }
        .background(Theme.bg.ignoresSafeArea())
        .navigationTitle(exercise.displayName)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button { exercise.isFavorite.toggle() } label: {
                    Image(systemName: exercise.isFavorite ? "star.fill" : "star")
                }.tint(Theme.accent)
            }
        }
        .confirmationDialog(L("exercise.delete.confirm"), isPresented: $confirmDelete, titleVisibility: .visible) {
            Button(L("detail.delete"), role: .destructive) {
                exercise.photoFiles.forEach(PhotoStore.delete(named:))
                context.delete(exercise)
                try? context.save()
                dismiss()
            }
        }
        .onChange(of: pickerItem) { _, item in
            guard let item else { return }
            Task {
                if let data = try? await item.loadTransferable(type: Data.self), let name = PhotoStore.save(data) {
                    exercise.photoFiles.append(name)
                }
                pickerItem = nil
            }
        }
    }

    private var tags: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                VGChip(title: exercise.primaryMuscle.title, selected: true)
                VGChip(title: exercise.equipment.title, selected: false)
                VGChip(title: exercise.level.title, selected: false)
            }
            if !exercise.secondaryMuscles.isEmpty {
                Text("\(L("exercise.secondary")): " + exercise.secondaryMuscles.map(\.title).joined(separator: ", "))
                    .font(.system(size: 13)).foregroundStyle(Theme.textSecondary)
            }
        }
    }

    private var stats: some View {
        let best1RM = ProgressionEngine.bestOneRM(in: doneSets)
        let heaviest = doneSets.map(\.weightKg).max()
        return HStack(spacing: 12) {
            VGStatTile(label: L("exercise.best.1rm"),
                       value: best1RM.map { Fmt.weight($0, unit: unit) } ?? "–", unit: best1RM == nil ? nil : unit.symbol)
            VGStatTile(label: L("exercise.heaviest"),
                       value: heaviest.map { Fmt.weight($0, unit: unit) } ?? "–", unit: heaviest == nil ? nil : unit.symbol)
        }
    }

    private var photos: some View {
        VStack(alignment: .leading, spacing: 10) {
            VGSectionLabel(L("exercise.photos"))
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(exercise.photoFiles, id: \.self) { name in
                        if let img = PhotoStore.image(named: name) {
                            Image(uiImage: img).resizable().scaledToFill()
                                .frame(width: 120, height: 120)
                                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                                .contextMenu {
                                    Button(L("detail.delete"), systemImage: "trash", role: .destructive) {
                                        PhotoStore.delete(named: name)
                                        exercise.photoFiles.removeAll { $0 == name }
                                    }
                                }
                        }
                    }
                    PhotosPicker(selection: $pickerItem, matching: .images) {
                        VStack(spacing: 6) {
                            Image(systemName: "plus").font(.system(size: 20, weight: .semibold))
                            Text(L("exercise.photos.add")).font(.system(size: 12, weight: .medium))
                        }
                        .foregroundStyle(Theme.accent)
                        .frame(width: 120, height: 120)
                        .background(Theme.accentSoft, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                    }
                }
            }
            Text(L("exercise.photos.hint")).font(.system(size: 12)).foregroundStyle(Theme.textSecondary)
        }
    }

    private var restOverride: some View {
        let value = exercise.restSecondsOverride ?? WorkoutCoordinator.defaultRestSeconds
        return HStack {
            VStack(alignment: .leading, spacing: 4) {
                VGSectionLabel(L("exercise.rest"))
                Text(Fmt.clock(Double(value))).font(Theme.mono(22, .bold)).foregroundStyle(Theme.textPrimary)
            }
            Spacer()
            Stepper("", value: Binding(get: { value }, set: { exercise.restSecondsOverride = $0 }),
                    in: 15...900, step: 15).labelsHidden()
        }
        .vgCard()
    }

    private var instructions: some View {
        VStack(alignment: .leading, spacing: 12) {
            VGSectionLabel(L("exercise.instructions"))
            ForEach(Array(exercise.instructions.enumerated()), id: \.offset) { i, step in
                HStack(alignment: .top, spacing: 12) {
                    Text("\(i + 1)").font(Theme.mono(13, .bold)).foregroundStyle(Theme.accent).frame(width: 18)
                    Text(step).font(.system(size: 15)).foregroundStyle(Theme.textPrimary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            if Localizer.isPolish {
                Text(L("exercise.instructions.en")).font(.system(size: 12)).foregroundStyle(Theme.textSecondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .vgCard()
    }
}
