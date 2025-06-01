//
//  DailyPlannerViewModel.swift
//  Dash
//
//  Created by Trijal Gunaseelan on 5/30/25.
//

import Foundation

class DailyPlannerViewModel: ObservableObject {
    @Published var tasks: [Task] = [] {
        didSet { saveTasks() }
    }

    init() {
        loadTasks()
    }

    func addOrUpdate(_ task: Task) {
        if let index = tasks.firstIndex(where: { $0.id == task.id }) {
            tasks[index] = task
        } else {
            tasks.append(task)
        }
    }

    func delete(_ task: Task) {
        tasks.removeAll { $0.id == task.id }
    }

    private func saveTasks() {
        if let data = try? JSONEncoder().encode(tasks) {
            UserDefaults.standard.set(data, forKey: "tasks")
        }
    }

    private func loadTasks() {
        if let data = UserDefaults.standard.data(forKey: "tasks"),
           let saved = try? JSONDecoder().decode([Task].self, from: data) {
            tasks = saved
        }
    }
}
