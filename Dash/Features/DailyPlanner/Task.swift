//
//  Task.swift
//  Dash
//
//  Created by Trijal Gunaseelan on 5/30/25.
//

import Foundation

struct Task: Identifiable, Codable, Equatable {
    let id: UUID
    var title: String
    var dueDate: Date
    var isCompleted: Bool
    var createdAt: Date = Date()

    init(id: UUID = UUID(), title: String, dueDate: Date = Date(), isCompleted: Bool = false) {
        self.id = id
        self.title = title
        self.dueDate = dueDate
        self.isCompleted = isCompleted
    }
}
