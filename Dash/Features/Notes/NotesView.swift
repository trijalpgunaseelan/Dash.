//
//  NotesView.swift
//  Dash
//
//  Created by Trijal Gunaseelan on 11/23/24.
//  Edited by Dhaskhika on 2/4/26
//

import SwiftUI

struct NotesView: View {

    @StateObject private var viewModel = NotesViewModel()
    @State private var selectedNote: Note? = nil
    @State private var searchText = ""

    @State private var pinnedNotes: Set<UUID> = []

    enum SortOption: String, CaseIterable, Identifiable {
        case createdDescending = "Newest"
        case createdAscending = "Oldest"
        case titleAscending = "Title A–Z"
        case titleDescending = "Title Z–A"

        var id: String { rawValue }
    }

    @State private var sortOption: SortOption = .createdDescending

    // MARK: FILTER

    var filteredNotes: [Note] {

        if searchText.isEmpty { return viewModel.notes }

        return viewModel.notes.filter {
            $0.title.lowercased().contains(searchText.lowercased()) ||
            $0.content.lowercased().contains(searchText.lowercased())
        }
    }

    // MARK: SORT

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

    // MARK: BODY

    var body: some View {

        NavigationView {

            ZStack {

                VStack(spacing: 0) {

                    header

                    searchBar

                    filterBar

                    heatmap

                    notesList
                }

                floatingButton

                navigationLink
            }

            .navigationTitle("Notes")
            .navigationBarTitleDisplayMode(.inline)

            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    AppMenuButton()
                }
            }
        }
    }

    // MARK: HEADER

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

    // MARK: SEARCH

    var searchBar: some View {

        HStack {

            Image(systemName: "magnifyingglass")

            TextField("Search notes...", text: $searchText)
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color(UIColor.systemGray6))
        )
        .padding(.horizontal,16)
        .padding(.top,8)
    }

    // MARK: FILTER BAR

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
                                .fill(sortOption == option ? Color.purple : Color(UIColor.systemGray5))
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
        .padding(.top,14)   // spacing fix
        .padding(.bottom,10)
    }

    // MARK: HEATMAP

    var heatmap: some View {

        VStack(alignment:.leading) {

            Text("Activity")
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.horizontal,16)

            LazyVGrid(
                columns: Array(repeating: GridItem(.flexible()), count: 7),
                spacing: 4
            ) {

                ForEach(0..<28) { _ in

                    RoundedRectangle(cornerRadius:3)
                        .fill(Color.purple.opacity(Double.random(in: 0.2...0.8)))
                        .frame(height:10)
                }
            }
            .padding(.horizontal,16)
        }
        .padding(.bottom,10)
    }

    // MARK: NOTES LIST

    var notesList: some View {

        List {

            ForEach(sortedNotes) { note in

                Button {

                    selectedNote = note

                } label: {

                    modernNoteCard(note)
                }
                .buttonStyle(PlainButtonStyle())
                .listRowInsets(EdgeInsets())
                .listRowSeparator(.hidden)
                .padding(.vertical,6)

                .swipeActions(edge: .leading) {

                    Button {

                        togglePin(note)

                    } label: {

                        Label("Pin", systemImage: "pin")
                    }
                    .tint(.orange)
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
                    .tint(.blue)
                }
            }
        }
        .listStyle(.plain)
    }

    // MARK: NOTE CARD

    private func modernNoteCard(_ note: Note) -> some View {

        HStack(spacing:0) {

            Rectangle()
                .fill(Color(hex: note.colorHex) ?? .purple)
                .frame(width:5)

            VStack(alignment:.leading,spacing:8) {

                HStack {

                    if pinnedNotes.contains(note.id) {
                        Image(systemName:"pin.fill")
                            .foregroundColor(.orange)
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
            RoundedRectangle(cornerRadius:12)
                .fill(Color(UIColor.systemGray6))
        )
        .padding(.horizontal,8)
    }

    // MARK: FLOATING BUTTON

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

    // MARK: NAVIGATION

    var navigationLink: some View {

        NavigationLink(
            destination: selectedNote.map { note in

                EditNoteView(
                    note: Binding(
                        get: {
                            viewModel.notes.first(where: { $0.id == note.id }) ?? note
                        },
                        set: { newValue in
                            if let index = viewModel.notes.firstIndex(where: { $0.id == note.id }) {
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
    }

    // MARK: ACTIONS

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
