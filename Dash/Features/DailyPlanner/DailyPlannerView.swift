//
//  DailyPlannerView.swift
//  Dash
//
//  Created by Trijal Gunaseelan on 5/30/25.
//

import SwiftUI

struct DailyPlannerView: View {
    @StateObject private var viewModel = DailyPlannerViewModel()
    @State private var selectedTask: Task? = nil
    @State private var showingAddTask = false
    @State private var sortOption: SortOption = .startDateDescending

    enum SortOption: String, CaseIterable, Identifiable {
        case startDateDescending = "Newest"
        case startDateAscending = "Oldest"
        case nameAscending = "Name A–Z"
        case nameDescending = "Name Z–A"
        case completedFirst = "Completed"

        var id: String { self.rawValue }
    }

    var sortedTasks: [Task] {
        switch sortOption {
        case .startDateDescending:
            return viewModel.tasks.sorted { $0.createdAt > $1.createdAt }
        case .startDateAscending:
            return viewModel.tasks.sorted { $0.createdAt < $1.createdAt }
        case .nameAscending:
            return viewModel.tasks.sorted { $0.title.lowercased() < $1.title.lowercased() }
        case .nameDescending:
            return viewModel.tasks.sorted { $0.title.lowercased() > $1.title.lowercased() }
        case .completedFirst:
            return viewModel.tasks.sorted { ($0.isCompleted ? 0 : 1) < ($1.isCompleted ? 0 : 1) }
        }
    }

    var body: some View {
        NavigationView {
            ZStack {
                VStack(spacing: 0) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Daily Planner")
                            .font(.system(size: 26, weight: .bold))

                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(SortOption.allCases) { option in
                                    Text(option.rawValue)
                                        .font(.subheadline)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 6)
                                        .background(
                                            RoundedRectangle(cornerRadius: 20)
                                                .fill(sortOption == option ? Color.purple : Color(UIColor.systemGray5))
                                        )
                                        .foregroundColor(sortOption == option ? .white : .primary)
                                        .onTapGesture {
                                            sortOption = option
                                        }
                                }
                            }
                            .padding(.horizontal, 4)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 10)
                    .padding(.bottom, 5)

                    if sortedTasks.isEmpty {
                        Spacer()
                        Text("No tasks yet.")
                            .font(.title3)
                            .foregroundColor(.gray)
                        Spacer()
                    } else {
                        List {
                            ForEach(sortedTasks) { task in
                                VStack {
                                    Button {
                                        selectedTask = task
                                    } label: {
                                        HStack(spacing: 12) {
                                            Button(action: {
                                                var updated = task
                                                updated.isCompleted.toggle()
                                                viewModel.addOrUpdate(updated)
                                            }) {
                                                Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                                                    .foregroundColor(task.isCompleted ? .green : .gray)
                                            }
                                            .buttonStyle(PlainButtonStyle())

                                            VStack(alignment: .leading, spacing: 4) {
                                                Text(task.title)
                                                    .font(.headline)
                                                    .lineLimit(1)
                                                    .strikethrough(task.isCompleted)
                                                    .foregroundColor(task.isCompleted ? .gray : .primary)

                                                Text(task.dueDate, style: .date)
                                                    .font(.caption)
                                                    .foregroundColor(.secondary)
                                                    .lineLimit(1)
                                            }

                                            Spacer()
                                        }
                                        .padding()
                                        .background(
                                            RoundedRectangle(cornerRadius: 12)
                                                .fill(Color(UIColor.systemGray6))
                                        )
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                    .onTapGesture(count: 2) {
                                        var updated = task
                                        updated.isCompleted.toggle()
                                        viewModel.addOrUpdate(updated)
                                    }
                                }
                                .listRowInsets(EdgeInsets())
                                .padding(.vertical, 4)
                                .padding(.horizontal, 8)
                                .listRowSeparator(.hidden)
                            }
                            .onDelete { offsets in
                                for index in offsets {
                                    let task = sortedTasks[index]
                                    viewModel.delete(task)
                                }
                            }
                        }
                        .listStyle(PlainListStyle())
                    }
                }

                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Button {
                            showingAddTask = true
                        } label: {
                            Image(systemName: "plus")
                                .font(.system(size: 24))
                                .foregroundColor(.white)
                                .padding()
                                .background(Circle().fill(Color.purple))
                                .shadow(radius: 3)
                        }
                        .padding(.bottom, 20)
                        .padding(.trailing, 20)
                    }
                }
            }
            .sheet(isPresented: $showingAddTask) {
                AddTaskView(viewModel: viewModel)
            }
            .background(
                NavigationLink(
                    destination: selectedTask.map {
                        EditTaskView(task: $0, viewModel: viewModel)
                    },
                    isActive: Binding(
                        get: { selectedTask != nil },
                        set: { if !$0 { selectedTask = nil } }
                    )
                ) { EmptyView() }
            )
        }
    }
}
