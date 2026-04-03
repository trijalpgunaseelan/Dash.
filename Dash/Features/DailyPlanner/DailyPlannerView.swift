//
//  DailyPlannerView.swift
//  Dash
//
//  Created by Trijal Gunaseelan on 5/30/25.
//  Edited by Dhakshika


import SwiftUI

struct DailyPlannerView: View {

    @StateObject private var viewModel = DailyPlannerViewModel()

    @State private var selectedTask: Task? = nil
    @State private var showingAddTask = false

    @State private var filter: Filter = .all
    @State private var showCalendar = false

    enum Filter: String, CaseIterable, Identifiable {
        case all = "All"
        case today = "Today"
        case upcoming = "Upcoming"
        case completed = "Completed"

        var id: String { rawValue }
    }

    // MARK: Filtered Tasks

    var filteredTasks: [Task] {

        switch filter {

        case .all:
            return viewModel.tasks

        case .today:
            return viewModel.tasks.filter {
                Calendar.current.isDateInToday($0.dueDate)
            }

        case .upcoming:
            return viewModel.tasks.filter {
                $0.dueDate > Date()
            }

        case .completed:
            return viewModel.tasks.filter {
                $0.isCompleted
            }
        }
    }

    // MARK: Progress

    var progress: Double {

        guard !viewModel.tasks.isEmpty else { return 0 }

        let completed = viewModel.tasks.filter { $0.isCompleted }.count

        return Double(completed) / Double(viewModel.tasks.count)
    }

    // MARK: Productivity Insights

    var completedToday: Int {
        viewModel.tasks.filter {
            $0.isCompleted && Calendar.current.isDateInToday($0.dueDate)
        }.count
    }

    // MARK: UI

    var body: some View {

        NavigationView {

            ZStack {

                VStack(spacing: 0) {

                    // MARK: Progress Dashboard

                    VStack(alignment: .leading, spacing: 10) {

                        Text("Today's Progress")
                            .font(.subheadline)
                            .foregroundColor(.secondary)

                        ProgressView(value: progress)
                            .tint(.purple)

                        Text("\(viewModel.tasks.filter{$0.isCompleted}.count) of \(viewModel.tasks.count) tasks completed")
                            .font(.caption)
                            .foregroundColor(.secondary)

                        Text("🔥 \(completedToday) completed today")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 10)

                    // MARK: Filters

                    ScrollView(.horizontal, showsIndicators: false) {

                        HStack(spacing: 10) {

                            ForEach(Filter.allCases) { item in

                                Text(item.rawValue)
                                    .font(.subheadline)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(
                                        RoundedRectangle(cornerRadius: 20)
                                            .fill(filter == item ? Color.purple : Color(UIColor.systemGray5))
                                    )
                                    .foregroundColor(filter == item ? .white : .primary)
                                    .onTapGesture {

                                        withAnimation {
                                            filter = item
                                        }
                                    }
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                    }

                    // MARK: Toggle Calendar

                    VStack(alignment: .leading, spacing: 12) {

                        HStack {
                            Text("Calendar")
                                .font(.headline)

                            Spacer()

                            Button {
                                withAnimation {
                                    showCalendar.toggle()
                                }
                            } label: {
                                Image(systemName: showCalendar ? "calendar.badge.minus" : "calendar")
                                    .foregroundColor(.purple)
                            }
                        }
                        .padding(.horizontal, 16)

                        if showCalendar {

                            ScrollView(.horizontal, showsIndicators: false) {

                                HStack(spacing: 14) {

                                    ForEach(next7Days(), id: \.self) { date in

                                        VStack(spacing: 6) {

                                            Text(dayLabel(date))
                                                .font(.caption)
                                                .foregroundColor(.secondary)

                                            Text(dayNumber(date))
                                                .font(.headline)

                                            Circle()
                                                .fill(hasTask(date) ? Color.purple : Color.clear)
                                                .frame(width: 6, height: 6)
                                        }
                                        .frame(width: 50, height: 60)
                                        .background(
                                            RoundedRectangle(cornerRadius: 12)
                                                .fill(
                                                    Calendar.current.isDateInToday(date)
                                                    ? Color.purple.opacity(0.2)
                                                    : Color(UIColor.systemGray6)
                                                )
                                        )
                                    }
                                }
                                .padding(.horizontal, 16)
                            }
                        }
                    }
                    .padding(.top, 6)
                    // MARK: Task List

                    if filteredTasks.isEmpty {

                        Spacer()

                        VStack(spacing: 12) {

                            Text("📅")
                                .font(.system(size: 40))

                            Text("Your day is clear")
                                .font(.title3)
                                .fontWeight(.semibold)

                            Text("Tap + to add a task")
                                .foregroundColor(.secondary)
                        }

                        Spacer()

                    } else {

                        List {

                            ForEach(filteredTasks) { task in

                                taskCard(task)

                                    .listRowInsets(EdgeInsets())
                                    .padding(.vertical, 6)
                                    .padding(.horizontal, 8)
                                    .listRowSeparator(.hidden)

                                    // Swipe Complete

                                    .swipeActions(edge: .leading) {

                                        Button {

                                            var updated = task
                                            updated.isCompleted.toggle()

                                            withAnimation {
                                                viewModel.addOrUpdate(updated)
                                            }

                                        } label: {
                                            Label("Complete", systemImage: "checkmark")
                                        }
                                        .tint(.green)
                                    }

                                    // Swipe Delete

                                    .swipeActions(edge: .trailing) {

                                        Button(role: .destructive) {

                                            withAnimation {
                                                viewModel.delete(task)
                                            }

                                        } label: {
                                            Label("Delete", systemImage: "trash")
                                        }
                                    }

                                    .onTapGesture {
                                        selectedTask = task
                                    }
                            }

                            // Drag to reorder

                            .onMove { source, destination in
                                viewModel.tasks.move(fromOffsets: source, toOffset: destination)
                            }
                        }
                        .listStyle(PlainListStyle())
                    }
                }

                // MARK: Floating Add Button

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
                                .shadow(radius: 4)
                        }
                        .padding(.bottom, 20)
                        .padding(.trailing, 20)
                    }
                }
            }

            .navigationTitle("Daily Planner")
            .navigationBarTitleDisplayMode(.inline)

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

            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    AppMenuButton()
                }
            }
        }
    }

    // MARK: Task Card UI

    func taskCard(_ task: Task) -> some View {

        HStack(spacing: 12) {

            Button {

                var updated = task
                updated.isCompleted.toggle()

                withAnimation {
                    viewModel.addOrUpdate(updated)
                }

            } label: {

                Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(task.isCompleted ? .green : .gray)
                    .font(.system(size: 20))
            }

            VStack(alignment: .leading, spacing: 6) {

                HStack {

                    priorityBadge(task)

                    Text(task.title)
                        .font(.headline)
                        .lineLimit(1)
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
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color(UIColor.systemGray6))
        )
    }

    // MARK: Priority Badge

    func priorityBadge(_ task: Task) -> some View {

        let color: Color

        switch task.priority {

        case .low:
            color = .green

        case .medium:
            color = .orange

        case .high:
            color = .red
        }

        return Text(task.priority.rawValue.capitalized)
            .font(.caption2)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(color.opacity(0.2))
            .foregroundColor(color)
            .cornerRadius(6)
    }

    // MARK: Calendar Helpers

    func next7Days() -> [Date] {
        let calendar = Calendar.current
        let start = calendar.startOfDay(for: Date())
        return (0..<7).compactMap { offset in
            calendar.date(byAdding: .day, value: offset, to: start)
        }
    }

    func dayLabel(_ date: Date) -> String {
        date.formatted(.dateTime.weekday(.abbreviated))
    }

    func dayNumber(_ date: Date) -> String {
        date.formatted(.dateTime.day())
    }

    func hasTask(_ date: Date) -> Bool {
        viewModel.tasks.contains { task in
            Calendar.current.isDate(task.dueDate, inSameDayAs: date)
        }
    }
}
