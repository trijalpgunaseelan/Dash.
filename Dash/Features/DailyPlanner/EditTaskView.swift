//
//  EditTaskView.swift
//  Dash
//
//  Created by Trijal Gunaseelan on 5/30/25.
//

import SwiftUI

struct EditTaskView: View {
    @Environment(\.presentationMode) var presentationMode
    @State private var taskCopy: Task
    var viewModel: DailyPlannerViewModel

    init(task: Task, viewModel: DailyPlannerViewModel) {
        self._taskCopy = State(initialValue: task)
        self.viewModel = viewModel
    }

    var body: some View {
        Form {
            Section(header: Text("Title")) {
                TextField("Enter task title", text: $taskCopy.title)
                    .onChange(of: taskCopy.title) { _ in
                        autoSave()
                    }
            }

            Section(header: Text("Due Date")) {
                DatePicker("Due", selection: $taskCopy.dueDate, displayedComponents: .date)
                    .onChange(of: taskCopy.dueDate) { _ in
                        autoSave()
                    }
            }

            Section {
                Toggle("Completed", isOn: $taskCopy.isCompleted)
                    .onChange(of: taskCopy.isCompleted) { _ in
                        autoSave()
                    }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text(
                    taskCopy.title.isEmpty
                    ? "New Task"
                    : (taskCopy.title.count > 25 ? String(taskCopy.title.prefix(25)) + "…" : taskCopy.title)
                )
                .font(.headline)
                .lineLimit(1)
            }
        }
        .onDisappear {
            autoSave()
        }
    }

    private func autoSave() {
        viewModel.addOrUpdate(taskCopy)
    }
}
