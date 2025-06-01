//
//  AddTaskView.swift
//  Dash
//
//  Created by Trijal Gunaseelan on 5/30/25.
//

//
//  AddTaskView.swift
//  Dash
//
//  Created by Trijal Gunaseelan on 5/30/25.
//

import SwiftUI

struct AddTaskView: View {
    @Environment(\.presentationMode) var presentationMode
    @ObservedObject var viewModel: DailyPlannerViewModel

    @State private var task = Task(title: "")
    @State private var hasEdited = false

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Task Title").font(.headline)) {
                    TextField("Enter task name", text: $task.title)
                        .onChange(of: task.title) { _ in autoSave() }
                }

                Section(header: Text("Due Date").font(.headline)) {
                    DatePicker("Due", selection: $task.dueDate, displayedComponents: .date)
                        .onChange(of: task.dueDate) { _ in autoSave() }
                }

                Section {
                    Toggle("Completed", isOn: $task.isCompleted)
                        .onChange(of: task.isCompleted) { _ in autoSave() }
                }
            }
            .navigationTitle("New Task")
            .navigationBarTitleDisplayMode(.inline)
            .accentColor(.purple)
            .background(Color(UIColor.systemGroupedBackground).edgesIgnoringSafeArea(.all))
        }
    }

    private func autoSave() {
        if !task.title.trimmingCharacters(in: .whitespaces).isEmpty {
            viewModel.addOrUpdate(task)
        }
    }
}
