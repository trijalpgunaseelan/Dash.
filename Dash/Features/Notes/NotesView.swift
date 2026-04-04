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
    @State private var refreshID = UUID()
    @State private var showNotifications = false
    @State private var hasUnreadNotifications = true

    enum SortOption: String, CaseIterable, Identifiable {
        case createdDescending = "Newest"
        case createdAscending = "Oldest"
        case titleAscending = "A–Z"
        case titleDescending = "Z–A"
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

                // Background gradient
                LinearGradient(
                    colors: [
                        Color(red: 0.06, green: 0.06, blue: 0.09),
                        Color(red: 0.09, green: 0.08, blue: 0.13)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                VStack(spacing: 0) {
                    glassHeader
                    searchBar
                    filterBar
                    notesList
                }

                floatingButton
            }

            .navigationBarHidden(true)

            .onAppear {
                refreshID = UUID()
            }

            .background(
                NavigationLink(
                    destination: selectedNote.map { selected in
                        EditNoteView(
                            note: Binding(
                                get: {
                                    viewModel.notes.first(where: { $0.id == selected.id }) ?? selected
                                },
                                set: { newValue in
                                    if let index = viewModel.notes.firstIndex(where: { $0.id == newValue.id }) {
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
        }
    }

    // MARK: - Glass Header

    var glassHeader: some View {

        ZStack {

            // Glass blur background
            Rectangle()
                .fill(.ultraThinMaterial)
                .overlay(
                    Rectangle()
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.purple.opacity(0.08),
                                    Color.clear
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                )
                .ignoresSafeArea(edges: .top)

            HStack {

                // Notification Bell
                Button {
                    hasUnreadNotifications = false
                    showNotifications.toggle()
                    let impact = UIImpactFeedbackGenerator(style: .light)
                    impact.impactOccurred()
                } label: {
                    ZStack(alignment: .topTrailing) {
                        Image(systemName: "bell")
                            .font(.system(size: 20, weight: .medium))
                            .foregroundColor(.white.opacity(0.85))
                            .frame(width: 40, height: 40)
                            .background(
                                Circle()
                                    .fill(Color.white.opacity(0.08))
                                    .overlay(
                                        Circle()
                                            .stroke(Color.white.opacity(0.1), lineWidth: 1)
                                    )
                            )

                        if hasUnreadNotifications {
                            Circle()
                                .fill(Color.purple)
                                .frame(width: 9, height: 9)
                                .overlay(Circle().stroke(Color.black, lineWidth: 1.5))
                                .offset(x: 2, y: -2)
                        }
                    }
                }

                Spacer()

                // Centered Title
                VStack(spacing: 2) {
                    Text("Notes")
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                    Text("\(viewModel.notes.count) notes")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.purple.opacity(0.8))
                }

                Spacer()

                // Menu Button
                AppMenuButton()
                    .frame(width: 40, height: 40)
                    .background(
                        Circle()
                            .fill(Color.white.opacity(0.08))
                            .overlay(Circle().stroke(Color.white.opacity(0.1), lineWidth: 1))
                    )
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)
            .padding(.bottom, 14)
        }
        .frame(height: 80)
    }

    // MARK: - Search Bar

    var searchBar: some View {

        HStack(spacing: 10) {

            Image(systemName: "magnifyingglass")
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(.white.opacity(0.4))

            TextField("Search notes...", text: $searchText)
                .font(.system(size: 15))
                .foregroundColor(.white)
                .tint(.purple)

            if !searchText.isEmpty {
                Button {
                    searchText = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.white.opacity(0.3))
                }
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 11)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color.white.opacity(0.07))
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(Color.white.opacity(0.08), lineWidth: 1)
                )
        )
        .padding(.horizontal, 16)
        .padding(.top, 12)
        .padding(.bottom, 4)
    }

    // MARK: - Filter Bar

    var filterBar: some View {

        ScrollView(.horizontal, showsIndicators: false) {

            HStack(spacing: 8) {

                ForEach(SortOption.allCases) { option in

                    Button {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            sortOption = option
                        }
                        let impact = UIImpactFeedbackGenerator(style: .light)
                        impact.impactOccurred()
                    } label: {
                        Text(option.rawValue)
                            .font(.system(size: 13, weight: sortOption == option ? .semibold : .regular))
                            .padding(.horizontal, 14)
                            .padding(.vertical, 7)
                            .background(
                                Capsule()
                                    .fill(sortOption == option
                                          ? Color.purple
                                          : Color.white.opacity(0.07))
                                    .overlay(
                                        Capsule()
                                            .stroke(sortOption == option
                                                    ? Color.purple.opacity(0.5)
                                                    : Color.white.opacity(0.06),
                                                    lineWidth: 1)
                                    )
                            )
                            .foregroundColor(sortOption == option ? .white : .white.opacity(0.55))
                    }
                }
            }
            .padding(.horizontal, 16)
        }
        .padding(.top, 10)
        .padding(.bottom, 8)
    }

    // MARK: - Notes List

    var notesList: some View {

        List {

            ForEach(sortedNotes) { note in

                modernNoteCard(note)
                    .listRowInsets(EdgeInsets())
                    .listRowSeparator(.hidden)
                    .listRowBackground(Color.clear)
                    .padding(.vertical, 5)
                    .padding(.horizontal, 16)

                    .swipeActions(edge: .leading) {
                        Button {
                            togglePin(note)
                            let impact = UIImpactFeedbackGenerator(style: .medium)
                            impact.impactOccurred()
                        } label: {
                            Label("Pin", systemImage: pinnedNotes.contains(note.id) ? "pin.slash" : "pin")
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
                        .tint(.indigo)
                    }

                    .onTapGesture {
                        let impact = UIImpactFeedbackGenerator(style: .light)
                        impact.impactOccurred()
                        refreshID = UUID()
                        selectedNote = note
                    }
            }

            // Bottom padding for FAB
            Color.clear
                .frame(height: 90)
                .listRowInsets(EdgeInsets())
                .listRowSeparator(.hidden)
                .listRowBackground(Color.clear)
        }
        .id(refreshID)
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
    }

    // MARK: - Note Card

    private func modernNoteCard(_ note: Note) -> some View {

        HStack(spacing: 0) {

            // Accent bar
            RoundedRectangle(cornerRadius: 3)
                .fill(
                    LinearGradient(
                        colors: [Color.purple, Color.purple.opacity(0.5)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(width: 4)
                .padding(.vertical, 12)
                .padding(.leading, 14)

            VStack(alignment: .leading, spacing: 8) {

                // Title row
                HStack(spacing: 6) {

                    if pinnedNotes.contains(note.id) {
                        Image(systemName: "pin.fill")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundColor(.purple)
                    }

                    Text(note.title.isEmpty ? "Untitled Note" : note.title)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.white)
                        .lineLimit(1)

                    Spacer()

                    // Image thumbnail preview
                    if let firstImage = note.images.first {
                        Image(uiImage: firstImage.image)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 36, height: 36)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.white.opacity(0.1), lineWidth: 1)
                            )
                    }
                }

                // Content preview
                if !note.content.isEmpty {
                    Text(note.content)
                        .font(.system(size: 13))
                        .lineLimit(2)
                        .foregroundColor(.white.opacity(0.45))
                }

                // Footer row
                HStack(spacing: 8) {

                    // Date
                    HStack(spacing: 4) {
                        Image(systemName: "calendar")
                            .font(.system(size: 9))
                        Text(note.createdAt.formatted(date: .abbreviated, time: .omitted))
                            .font(.system(size: 11, weight: .medium))
                    }
                    .foregroundColor(.green.opacity(0.8))

                    // Word count
                    let wordCount = note.content.split(separator: " ").count
                    if wordCount > 0 {
                        Text("·")
                            .foregroundColor(.white.opacity(0.2))
                        HStack(spacing: 3) {
                            Image(systemName: "text.word.spacing")
                                .font(.system(size: 9))
                            Text("\(wordCount)w")
                                .font(.system(size: 11))
                        }
                        .foregroundColor(.white.opacity(0.3))
                    }

                    Spacer()

                    // Image count badge
                    if note.images.count > 1 {
                        HStack(spacing: 3) {
                            Image(systemName: "photo.stack")
                                .font(.system(size: 9))
                            Text("\(note.images.count)")
                                .font(.system(size: 10, weight: .medium))
                        }
                        .foregroundColor(.purple.opacity(0.8))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 3)
                        .background(
                            Capsule().fill(Color.purple.opacity(0.12))
                        )
                    }

                    // Reminder badge
                    if let reminder = note.reminder {
                        HStack(spacing: 3) {
                            Image(systemName: "alarm")
                                .font(.system(size: 9))
                            Text(reminder.formatted(date: .omitted, time: .shortened))
                                .font(.system(size: 10, weight: .medium))
                        }
                        .foregroundColor(.orange.opacity(0.9))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 3)
                        .background(Capsule().fill(Color.orange.opacity(0.12)))
                    }
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 14)
        }
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(
                    LinearGradient(
                        colors: [
                            Color(red: 0.14, green: 0.13, blue: 0.18),
                            Color(red: 0.12, green: 0.11, blue: 0.16)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .shadow(color: Color.black.opacity(0.35), radius: 10, x: 0, y: 4)
                .overlay(
                    RoundedRectangle(cornerRadius: 18)
                        .stroke(Color.white.opacity(0.06), lineWidth: 1)
                )
        )
    }

    // MARK: - Floating Action Button

    var floatingButton: some View {

        VStack {
            Spacer()
            HStack {
                Spacer()

                Button {
                    let impact = UIImpactFeedbackGenerator(style: .medium)
                    impact.impactOccurred()

                    let newNote = Note(title: "", content: "")
                    viewModel.notes.append(newNote)
                    selectedNote = newNote
                } label: {

                    ZStack {
                        // Glow effect
                        Circle()
                            .fill(Color.purple.opacity(0.35))
                            .frame(width: 64, height: 64)
                            .blur(radius: 12)

                        // Glass button
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [
                                        Color.purple,
                                        Color(red: 0.5, green: 0.2, blue: 0.9)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 56, height: 56)
                            .overlay(
                                Circle()
                                    .stroke(Color.white.opacity(0.25), lineWidth: 1)
                            )
                            .shadow(color: Color.purple.opacity(0.5), radius: 14, x: 0, y: 6)

                        Image(systemName: "plus")
                            .font(.system(size: 22, weight: .semibold))
                            .foregroundColor(.white)
                    }
                }
                .padding(.bottom, 28)
                .padding(.trailing, 20)
            }
        }
    }

    // MARK: - Actions

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
        let activity = UIActivityViewController(activityItems: [text], applicationActivities: nil)
        UIApplication.shared.windows.first?.rootViewController?.present(activity, animated: true)
    }
}
