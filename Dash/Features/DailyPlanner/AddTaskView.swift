//
//  AddTaskView.swift
//  Dash
//
//  Created by Trijal Gunaseelan on 5/30/25.
// Edited by Dhakshika


import SwiftUI

struct AddTaskView: View {

    @Environment(\.presentationMode) var presentationMode
    @ObservedObject var viewModel: DailyPlannerViewModel

    @State private var task = Task(title: "")
    @State private var hasEdited = false

    var body: some View {

        NavigationView {

            Form {

                // MARK: Task Title

                Section(header: Text("Task Title").font(.headline)) {

                    TextField("Enter task name", text: $task.title)
                        .onChange(of: task.title) { _ in
                            autoSave()
                        }
                }

                // MARK: Notes

                Section(header: Text("Notes").font(.headline)) {

                    TextField("Add optional details", text: $task.notes)
                        .onChange(of: task.notes) { _ in
                            autoSave()
                        }
                }

                // MARK: Due Date

                Section(header: Text("Due Date & Time").font(.headline)) {

                    DatePicker(
                        "Due",
                        selection: $task.dueDate,
                        displayedComponents: [.date, .hourAndMinute]
                    )
                    .onChange(of: task.dueDate) { _ in
                        autoSave()
                    }
                }

                // MARK: Priority

                Section(header: Text("Priority").font(.headline)) {

                    Picker("Priority", selection: $task.priority) {

                        Text("Low").tag(TaskPriority.low)
                        Text("Medium").tag(TaskPriority.medium)
                        Text("High").tag(TaskPriority.high)
                    }
                    .pickerStyle(.segmented)
                    .onChange(of: task.priority) { _ in
                        autoSave()
                    }
                }

                // MARK: Completed

                Section {

                    Toggle("Completed", isOn: $task.isCompleted)
                        .onChange(of: task.isCompleted) { _ in
                            autoSave()
                        }
                }
            }
            .navigationTitle("New Task")
            .navigationBarTitleDisplayMode(.inline)
            .accentColor(.purple)
        }
    }

    private func autoSave() {

        if !task.title
            .trimmingCharacters(in: .whitespaces)
            .isEmpty {

            viewModel.addOrUpdate(task)
        }
    }
}
