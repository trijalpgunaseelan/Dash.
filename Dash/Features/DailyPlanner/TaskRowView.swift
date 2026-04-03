//
//  TaskRowView.swift
//  Dash
//
//  Created by Trijal Gunaseelan on 5/30/25.
//  Edited by Dhakshika
//


import SwiftUI

struct TaskRowView: View {

    var task: Task
    var toggleCompleted: () -> Void

    var body: some View {

        HStack(alignment: .top, spacing: 14) {

            // MARK: Completion Button

            Button(action: toggleCompleted) {

                Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(task.isCompleted ? AppColors.accent : .gray)
                    .font(.system(size: 22))
            }
            .buttonStyle(BorderlessButtonStyle())
            .padding(.top, 2)

            // MARK: Task Content

            VStack(alignment: .leading, spacing: 6) {

                HStack(alignment: .center) {

                    Text(task.title)
                        .font(.system(size: 17, weight: .semibold))
                        .strikethrough(task.isCompleted)
                        .foregroundColor(task.isCompleted ? .gray : .white)
                        .lineLimit(1)

                    Spacer()

                    Text(task.priority.rawValue.capitalized)
                        .font(.caption2)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(AppColors.accent.opacity(0.15))
                        .foregroundColor(AppColors.accent)
                        .cornerRadius(6)
                }

                // MARK: Notes Preview

                if !task.notes.isEmpty {

                    Text(task.notes)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                        .padding(.top, 1)
                }

                // MARK: Due Date

                Text(task.dueDate, style: .date)
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .padding(.top, 2)
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(AppColors.card)
                .shadow(color: .black.opacity(0.25), radius: 6, x: 0, y: 3)
        )
        .padding(.horizontal, 16)
        .padding(.vertical, 6)
    }
}
