//
//  NotesView.swift
//  Dash
//

import SwiftUI

struct NotesView: View {

    @StateObject private var viewModel = NotesViewModel()

    @State private var selectedNote: Note? = nil
    @State private var searchText = ""

    @State private var pinnedNotes: Set<UUID> = []

    // same refresh system as DailyPlanner
    @State private var refreshID = UUID()

    enum SortOption: String, CaseIterable, Identifiable {
        case createdDescending = "Newest"
        case createdAscending = "Oldest"
        case titleAscending = "Title A–Z"
        case titleDescending = "Title Z–A"

        var id: String { rawValue }
    }

    @State private var sortOption: SortOption = .createdDescending

    var filteredNotes: [Note] {

        if searchText.isEmpty { return viewModel.notes }

        return viewModel.notes.filter {
            $0.title.lowercased().contains(searchText.lowercased()) ||
            $0.content.lowercased().contains(searchText.lowercased())
        }
    }

    var sortedNotes: [Note] {

        let notes = filteredNotes

        let sorted: [Note]

        switch sortOption {

        case .createdDescending:
            sorted = notes.sorted { $0.createdAt > $1.createdAt }

        case .createdAscending:
            sorted = notes.sorted { $0.createdAt < $1.createdAt }

        case .titleAscending:
            sorted = notes.sorted { $0.title.lowercased() < $1.title.lowercased() }

        case .titleDescending:
            sorted = notes.sorted { $0.title.lowercased() > $1.title.lowercased() }
        }

        return sorted.sorted { pinnedNotes.contains($0.id) && !pinnedNotes.contains($1.id) }
    }

    var body: some View {

        NavigationView {

            ZStack {

                Color.black.ignoresSafeArea()

                VStack(spacing: 0) {

                    header

                    searchBar

                    filterBar

                    notesList
                }

                floatingButton
            }

            .navigationTitle("Notes")
            .navigationBarTitleDisplayMode(.inline)

            .onAppear {
                refreshID = UUID()
            }

            .background(
                NavigationLink(
                    destination: selectedNote.map { selected in
                        EditNoteView(
                            note: Binding(
                                get: {
                                    viewModel.notes.first(where: { existing in
                                        existing.id == selected.id
                                    }) ?? selected
                                },
                                set: { newValue in
                                    if let index = viewModel.notes.firstIndex(where: { existing in
                                        existing.id == newValue.id
                                    }) {
                                        viewModel.notes[index] = newValue
                                    }
                                }
                            ),
                            viewModel: viewModel
                        )
                    },
                    isActive: Binding(
                        get: { selectedNote != nil },
                        set: { if !$0 { selectedNote = nil } }
                    )
                ) { EmptyView() }
            )

            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    AppMenuButton()
                }
            }
        }
    }

    var header: some View {

        HStack {

            VStack(alignment: .leading) {

                Text("Your Notes")
                    .font(.title3)
                    .fontWeight(.bold)

                Text("\(viewModel.notes.count) notes saved")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            Image(systemName: "square.text.square")
                .font(.title2)
                .foregroundColor(.purple)
        }
        .padding(.horizontal,16)
        .padding(.top,10)
    }

    var searchBar: some View {

        HStack {

            Image(systemName: "magnifyingglass")

            TextField("Search notes...", text: $searchText)
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color(white: 0.12))
        )
        .padding(.horizontal,16)
        .padding(.top,8)
    }

    var filterBar: some View {

        ScrollView(.horizontal, showsIndicators: false) {

            HStack(spacing: 10) {

                ForEach(SortOption.allCases) { option in

                    Text(option.rawValue)
                        .font(.subheadline)
                        .padding(.horizontal,14)
                        .padding(.vertical,7)
                        .background(
                            RoundedRectangle(cornerRadius:20)
                                .fill(sortOption == option ? Color.purple : Color(white:0.18))
                        )
                        .foregroundColor(sortOption == option ? .white : .primary)
                        .onTapGesture {
                            withAnimation {
                                sortOption = option
                            }
                        }
                }
            }
            .padding(.horizontal,16)
        }
        .padding(.top,14)
        .padding(.bottom,10)
    }

    var notesList: some View {

        List {

            ForEach(sortedNotes) { note in

                modernNoteCard(note)
                    .listRowInsets(EdgeInsets())
                    .listRowSeparator(.hidden)
                    .listRowBackground(Color.black)
                    .padding(.vertical,6)

                    .swipeActions(edge: .leading) {

                        Button {

                            togglePin(note)

                        } label: {

                            Label("Pin", systemImage: "pin")
                        }
                        .tint(.purple)
                    }

                    .swipeActions(edge: .trailing) {

                        Button(role: .destructive) {

                            deleteNote(note)

                        } label: {

                            Label("Delete", systemImage: "trash")
                        }

                        Button {

                            share(note)

                        } label: {

                            Label("Share", systemImage: "square.and.arrow.up")
                        }
                        .tint(.purple)
                    }

                    .onTapGesture {

                        // EXACT same refresh logic as planner
                        refreshID = UUID()

                        selectedNote = note
                    }
            }
        }
        .id(refreshID)
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
    }

    private func modernNoteCard(_ note: Note) -> some View {

        HStack(spacing:0) {

            Rectangle()
                .fill(Color.purple)
                .frame(width:5)

            VStack(alignment:.leading,spacing:8) {

                HStack {

                    if pinnedNotes.contains(note.id) {
                        Image(systemName:"pin.fill")
                            .foregroundColor(.purple)
                    }

                    Text(note.title.isEmpty ? "Untitled Note" : note.title)
                        .font(.headline)

                    Spacer()

                    if !note.images.isEmpty {

                        Image(systemName:"photo")
                            .foregroundColor(.purple)
                    }
                }

                if !note.content.isEmpty {

                    Text(note.content)
                        .font(.subheadline)
                        .lineLimit(2)
                        .foregroundColor(.secondary)
                }

                HStack {

                    Text(note.createdAt.formatted(date:.abbreviated,time:.omitted))
                        .font(.caption2)
                        .foregroundColor(.green)

                    Spacer()

                    if !note.images.isEmpty {

                        Text("\(note.images.count) images")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding()
        }
        .background(
            RoundedRectangle(cornerRadius:18)
                .fill(Color(red: 0.12, green: 0.12, blue: 0.14))
                .shadow(color: .black.opacity(0.4), radius: 6, x: 0, y: 3)
        )
        .padding(.horizontal,8)
    }

    var floatingButton: some View {

        VStack {

            Spacer()

            HStack {

                Spacer()

                Button {

                    selectedNote = Note(title:"",content:"")

                } label: {

                    Image(systemName:"plus")
                        .font(.system(size:24))
                        .foregroundColor(.white)
                        .padding()
                        .background(Circle().fill(Color.purple))
                        .shadow(radius:4)
                }
                .padding(.bottom,20)
                .padding(.trailing,20)
            }
        }
    }

    func togglePin(_ note: Note) {

        if pinnedNotes.contains(note.id) {
            pinnedNotes.remove(note.id)
        } else {
            pinnedNotes.insert(note.id)
        }
    }

    func deleteNote(_ note: Note) {

        if let index = viewModel.notes.firstIndex(where: { $0.id == note.id }) {
            viewModel.notes.remove(at: index)
        }
    }

    func share(_ note: Note) {

        let text = "\(note.title)\n\n\(note.content)"

        let activity = UIActivityViewController(
            activityItems: [text],
            applicationActivities: nil
        )

        UIApplication.shared.windows.first?.rootViewController?
            .present(activity, animated: true)
    }
}
