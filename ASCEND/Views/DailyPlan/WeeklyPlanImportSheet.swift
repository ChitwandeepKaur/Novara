import SwiftUI
import UniformTypeIdentifiers
import PDFKit

struct WeeklyPlanImportSheet: View {
    @ObservedObject var store: AppDataStore
    @Environment(\.dismiss) private var dismiss
    @State var weekOf: Date
    @State private var text = ""
    @State private var sourceName = "Pasted weekly plan"
    @State private var items: [WeeklyPlanItem] = []
    @State private var warnings: [String] = []
    @State private var choosingFile = false
    @State private var error: String?
    @State private var addedCount: Int?

    private var monday: Date { WeeklyPlanEngine.monday(containing: weekOf) }
    var body: some View {
        NavigationStack {
            Form {
                Section("Choose the week") {
                    DatePicker("Week containing", selection: $weekOf, displayedComponents: .date)
                    Text("Monday \(monday.formatted(date: .abbreviated, time: .omitted)) to Sunday \(Calendar.current.date(byAdding: .day, value: 6, to: monday)!.formatted(date: .abbreviated, time: .omitted))")
                        .font(.caption)
                }
                if items.isEmpty {
                    Section("Upload or paste your weekly plan") {
                        Button { choosingFile = true } label: {
                            Label("Choose a text, Markdown, or PDF file", systemImage: "doc.badge.arrow.up")
                        }
                        TextEditor(text: $text).frame(minHeight: 180).accessibilityLabel("Weekly plan text")
                        Text("Use weekday headings and task titles ending in durations. Each main heading becomes one task. Nested exercises are skipped; optional durations stay in the heading notes. PDF files must contain selectable text.")
                            .font(.caption)
                        Text("Monday\nPython: Collections and mutability (60 min)\nAdvanced Python CLI: Project setup (90 min)\nTuesday\nYour next topic (60 min)")
                            .font(.system(.caption, design: .monospaced)).textSelection(.enabled)
                        Button("Extract tasks") { extract() }
                            .disabled(text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    }
                    existingWeek
                } else {
                    Section {
                        Text("Review \(items.filter { $0.included }.count) tasks before adding them")
                        Text("DSA Practice, PHC QA, Sahota Services, and Portfolio Work are always included for all seven days. DSA and CLI headings update those activities' topics instead of creating duplicates.").font(.caption)
                        Text("Dates follow the week selected above. Reimporting the same task on the same day skips duplicates. Optional durations remain attached to the main heading. A heading explicitly marked optional is excluded from automatic scheduling. Outside commitments are added after your core work and do not use its focus budget.")
                            .font(.caption)
                    }
                    ForEach($items) { $item in
                        Section {
                            Toggle("Include task", isOn: $item.included)
                            TextField("Task heading", text: $item.title, axis: .vertical)
                            Picker("Day", selection: $item.weekday) {
                                ForEach(0..<7, id: \.self) { index in Text(WeeklyPlanEngine.weekdays[index]).tag(index) }
                            }
                            Stepper("\(item.minutes) minutes", value: $item.minutes, in: 5...720, step: 5)
                            Toggle("Optional", isOn: $item.optional)
                            Toggle("Outside core focus budget", isOn: $item.external)
                            if !item.notes.isEmpty { Text(item.notes).font(.caption) }
                        }
                    }
                    Section {
                        Button("Back to source text") { items = [] }
                        Button("Add tasks to this week") { save() }
                            .disabled(!items.contains { $0.included })
                    }
                }
                if !warnings.isEmpty {
                    Section("Import notes") {
                        ForEach(Array(warnings.enumerated()), id: \.offset) { _, warning in Text(warning).font(.caption) }
                    }
                }
            }
            .navigationTitle("Weekly plan")
            .onAppear { prepareWeek() }
            .onChange(of: weekOf) { _, _ in prepareWeek() }
            .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Close") { dismiss() } } }
            .fileImporter(isPresented: $choosingFile,
                          allowedContentTypes: [.plainText, UTType(filenameExtension: "md") ?? .plainText, .pdf],
                          allowsMultipleSelection: false) { result in
                do {
                    guard let url = try result.get().first else { return }
                    let accessing = url.startAccessingSecurityScopedResource()
                    defer { if accessing { url.stopAccessingSecurityScopedResource() } }
                    let size = try url.resourceValues(forKeys: [.fileSizeKey]).fileSize ?? 0
                    guard size <= 10_000_000 else { throw QuestEngineError("Choose a plan smaller than 10 MB.") }
                    let content: String
                    if url.pathExtension.lowercased() == "pdf" {
                        content = PDFDocument(url: url)?.string ?? ""
                    } else {
                        content = try String(contentsOf: url, encoding: .utf8)
                    }
                    guard !content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
                        throw QuestEngineError("No readable text was found. For a scanned PDF, paste the task headings instead.")
                    }
                    guard content.count <= 150_000 else { throw QuestEngineError("This plan is too long. Import one week's headings at a time.") }
                    sourceName = AscendText.clean(url.lastPathComponent)
                    text = AscendText.clean(content)
                    extract()
                } catch { self.error = error.localizedDescription }
            }
            .alert("Unable to import plan", isPresented: Binding(get: { error != nil }, set: { if !$0 { error = nil } })) {
                Button("OK") { error = nil }
            } message: { Text(error ?? "") }
            .alert("Weekly plan added", isPresented: Binding(get: { addedCount != nil }, set: { if !$0 { addedCount = nil } })) {
                Button("Done") { dismiss() }
            } message: {
                Text("Added \(addedCount ?? 0) tasks. Existing tasks on the same date were skipped. Choose a date in Daily Plan to see its checklist, or generate a schedule for that date.")
            }
        }
    }

    private var existingWeek: some View {
        Section("Tasks already added for this week") {
            ForEach(0..<7, id: \.self) { index in
                let date = Calendar.current.date(byAdding: .day, value: index, to: monday)!
                let tasks = store.state.dailyQuests.filter { $0.status != .archived && $0.plannedDate.map { Calendar.current.isDate($0, inSameDayAs: date) } == true }
                DisclosureGroup("\(WeeklyPlanEngine.weekdays[index]): \(tasks.count) tasks") {
                    let core = tasks.filter { $0.isOptional != true && $0.isExternalCommitment != true }.reduce(0) { $0 + $1.estimatedDurationMinutes }
                    let external = tasks.filter { $0.isOptional != true && $0.isExternalCommitment == true }.reduce(0) { $0 + $1.estimatedDurationMinutes }
                    Text("\(core) core minutes • \(external) outside-core minutes").font(.caption)
                    ForEach(tasks) { task in
                        Text("\(task.name) (\(task.estimatedDurationMinutes) min)\(task.isOptional == true ? " • Optional" : "")")
                            .font(.subheadline)
                    }
                }
            }
        }
    }

    private func prepareWeek() {
        var updated = store.state
        WeeklyPlanEngine.ensureNonNegotiables(forWeek: weekOf, in: &updated)
        store.state = updated
    }

    private func extract() {
        guard text.count <= 150_000 else { error = "Import one week's headings at a time (up to 150,000 characters)."; return }
        let parsed = WeeklyPlanEngine.parse(text)
        items = parsed.items
        warnings = parsed.warnings
    }

    private func save() {
        do {
            var updated = store.state
            let count = try WeeklyPlanEngine.importItems(items, weekOf: weekOf, source: sourceName, in: &updated)
            store.state = updated
            store.saveImmediately()
            addedCount = count
        } catch { self.error = error.localizedDescription }
    }
}
