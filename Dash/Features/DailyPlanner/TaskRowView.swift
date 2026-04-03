//
//  TaskRowView.swift
//  Dash
//
//  Created by Trijal Gunaseelan on 5/30/25.
//  Edited by Dhakshika


import SwiftUI

struct TaskRowView: View {

    var task: Task
    var toggleCompleted: () -> Void

    private var priorityColor: Color {

        switch task.priority {
        case .low: return .green
        case .medium: return .orange
        case .high: return .red
        }
    }

    var body: some View {

        HStack(alignment: .top, spacing: 12) {

            Button(action: toggleCompleted) {

                Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(task.isCompleted ? .green : .gray)
                    .font(.system(size: 20))
            }
            .buttonStyle(BorderlessButtonStyle())

            VStack(alignment: .leading, spacing: 6) {

                HStack {

                    Circle()
                        .fill(priorityColor)
                        .frame(width: 8, height: 8)

                    Text(task.title)
                        .font(.system(size: 18, weight: .medium))
                        .strikethrough(task.isCompleted)
                        .foregroundColor(task.isCompleted ? .gray : .primary)
                }

                if !task.notes.isEmpty {

                    Text(task.notes)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }

                Text(task.dueDate, style: .date)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }

            Spacer()
        }
        .padding(.vertical, 6)
    }
}
