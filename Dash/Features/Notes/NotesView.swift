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

    var body: some View {
        NavigationView {
            VStack {
                HStack {
                    Text("Notes")
                        .font(.custom("Chewy-Regular", size: 28))
                        .bold()
                        .padding(.top, 16)
                        .padding(.leading, 16)
                    Spacer()
                }

                if viewModel.notes.isEmpty {
                    Spacer()
                    Text("No Notes Yet")
                        .font(.title2)
                        .foregroundColor(.gray)
                        .padding()
                    Spacer()
                } else {
                    List {
                        ForEach(viewModel.notes) { note in
                            Button {
                                selectedNote = note
                            } label: {
                                VStack(alignment: .leading) {
                                    Text(note.title)
                                        .font(.custom("Chewy-Regular", size: 20))
                                    Text(note.content)
                                        .lineLimit(1)
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                        .onDelete(perform: deleteNote)
                    }
                    .listStyle(PlainListStyle())
                }
            }
            .background(
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
            )
            .overlay(
                VStack {
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
                }
            )
        }
    }

    private func deleteNote(at offsets: IndexSet) {
        viewModel.notes.remove(atOffsets: offsets)
        viewModel.deleteEmptyNotes()
    }
}
