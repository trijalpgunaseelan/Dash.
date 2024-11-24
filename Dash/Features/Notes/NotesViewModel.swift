//
//  NotesViewModel.swift
//  Dash
//
//  Created by Trijal Gunaseelan on 11/23/24.
//

import SwiftUI
import Combine

class NotesViewModel: ObservableObject {
    @Published var notes: [Note] = [] {
        didSet {
            saveNotesToDevice()
        }
    }

    init() {
        loadNotesFromDevice()
    }

    func addOrUpdate(note: Note) {
        if let index = notes.firstIndex(where: { $0.id == note.id }) {
            notes[index] = note
        } else {
            notes.append(note)
        }
    }

    func deleteEmptyNotes() {
        notes.removeAll(where: { $0.title.isEmpty && $0.content.isEmpty && $0.imageDatas == nil })
    }

    private func saveNotesToDevice() {
        if let data = try? JSONEncoder().encode(notes) {
            UserDefaults.standard.set(data, forKey: "notes")
        }
    }

    private func loadNotesFromDevice() {
        if let data = UserDefaults.standard.data(forKey: "notes"),
           let savedNotes = try? JSONDecoder().decode([Note].self, from: data) {
            self.notes = savedNotes
        }
    }
}
