//
//  TaskRowView.swift
//  Dash
//
//  Created by Trijal Gunaseelan on 5/30/25.
//

import SwiftUI

struct TaskRowView: View {
    var task: Task
    var toggleCompleted: () -> Void

    var body: some View {
        HStack {
            Button(action: toggleCompleted) {
                Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(task.isCompleted ? .green : .gray)
            }
            .buttonStyle(BorderlessButtonStyle())

            VStack(alignment: .leading) {
                Text(task.title)
                    .font(.system(size: 18, weight: .medium))
                    .strikethrough(task.isCompleted)
                    .foregroundColor(task.isCompleted ? .gray : .primary)

                Text(task.dueDate, style: .date)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}
