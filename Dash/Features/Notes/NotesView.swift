//
//  NotesView.swift
//  Dash
//
//  Created by Trijal Gunaseelan on 11/23/24.
//

import SwiftUI

struct NotesView: View {
    @StateObject private var viewModel = NotesViewModel()
    @State private var selectedNote: Note? = nil

    enum SortOption: String, CaseIterable, Identifiable {
        case createdDescending = "Newest"
        case createdAscending = "Oldest"
        case titleAscending = "Title A–Z"
        case titleDescending = "Title Z–A"
        case contentAscending = "Content A–Z"
        case contentDescending = "Content Z–A"
        case recentFirst = "Recent First"

        var id: String { self.rawValue }
    }

    @State private var sortOption: SortOption = .createdDescending

    var sortedNotes: [Note] {
        let notes = viewModel.notes
        switch sortOption {
        case .createdDescending, .recentFirst:
            return notes.sorted(by: { $0.createdAt > $1.createdAt })
        case .createdAscending:
            return notes.sorted(by: { $0.createdAt < $1.createdAt })
        case .titleAscending:
            return notes.sorted(by: { $0.title.lowercased() < $1.title.lowercased() })
        case .titleDescending:
            return notes.sorted(by: { $0.title.lowercased() > $1.title.lowercased() })
        case .contentAscending:
            return notes.sorted(by: { $0.content.lowercased() < $1.content.lowercased() })
        case .contentDescending:
            return notes.sorted(by: { $0.content.lowercased() > $1.content.lowercased() })
        }
    }

    var body: some View {
        NavigationView {
            ZStack {
                VStack(spacing: 0) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Notes")
                            .font(.system(size: 26, weight: .bold))

                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(SortOption.allCases) { option in
                                    Text(option.rawValue)
                                        .font(.subheadline)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 6)
                                        .background(
                                            RoundedRectangle(cornerRadius: 20)
                                                .fill(sortOption == option ? Color.purple : Color(UIColor.systemGray5))
                                        )
                                        .foregroundColor(sortOption == option ? .white : .primary)
                                        .onTapGesture {
                                            sortOption = option
                                        }
                                }
                            }
                            .padding(.horizontal, 4)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 10)
                    .padding(.bottom, 4)

                    if sortedNotes.isEmpty {
                        Spacer()
                        Text("No Notes Yet")
                            .font(.title2)
                            .foregroundColor(.gray)
                        Spacer()
                    } else {
                        List {
                            ForEach(sortedNotes) { note in
                                VStack {
                                    Button {
                                        selectedNote = note
                                    } label: {
                                        noteRow(note)
                                            .padding()
                                            .background(
                                                RoundedRectangle(cornerRadius: 12)
                                                    .fill(Color(UIColor.systemGray6))
                                            )
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                }
                                .padding(.vertical, 4)
                                .padding(.horizontal, 8)
                                .listRowInsets(EdgeInsets())
                                .listRowSeparator(.hidden)
                            }
                            .onDelete(perform: deleteNote)
                        }
                        .listStyle(PlainListStyle())
                    }
                }

                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Button(action: {
                            selectedNote = Note(title: "", content: "", createdAt: Date())
                        }) {
                            Image(systemName: "plus")
                                .font(.system(size: 24))
                                .foregroundColor(.white)
                                .padding()
                                .background(Circle().fill(Color.purple))
                                .shadow(radius: 3)
                        }
                        .padding(.bottom, 20)
                        .padding(.trailing, 20)
                    }
                }

                NavigationLink(
                    destination: selectedNote.map { note in
                        EditNoteView(note: Binding(
                            get: {
                                if let index = viewModel.notes.firstIndex(where: { $0.id == note.id }) {
                                    return $viewModel.notes[index].wrappedValue
                                }
                                return note
                            },
                            set: { newValue in
                                if let index = viewModel.notes.firstIndex(where: { $0.id == note.id }) {
                                    viewModel.notes[index] = newValue
                                }
                            }
                        ), viewModel: viewModel)
                    },
                    isActive: Binding(
                        get: { selectedNote != nil },
                        set: { isActive in
                            if !isActive { selectedNote = nil }
                        }
                    )
                ) { EmptyView() }
            }
        }
    }

    private func noteRow(_ note: Note) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(note.title)
                .font(.headline)
                .lineLimit(1)

            Text(note.content)
                .font(.subheadline)
                .lineLimit(2)
                .foregroundColor(.secondary)

            Text(formattedDate(note.createdAt))
                .font(.caption2)
                .foregroundColor(dateColor(for: note.createdAt))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }

    private func dateColor(for date: Date) -> Color {
        let now = Calendar.current.startOfDay(for: Date())
        let created = Calendar.current.startOfDay(for: date)
        let daysOld = Calendar.current.dateComponents([.day], from: created, to: now).day ?? 0
        return daysOld <= 7 ? .green : .red
    }

    private func deleteNote(at offsets: IndexSet) {
        for index in offsets {
            let noteToDelete = sortedNotes[index]
            if let actualIndex = viewModel.notes.firstIndex(where: { $0.id == noteToDelete.id }) {
                viewModel.notes.remove(at: actualIndex)
            }
        }
        viewModel.deleteEmptyNotes()
    }
}
