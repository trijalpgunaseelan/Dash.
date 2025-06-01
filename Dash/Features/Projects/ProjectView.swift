//
//  ProjectView.swift
//  Dash
//
//  Created by Trijal Gunaseelan on 11/19/24.
//

import SwiftUI

struct ProjectView: View {
    @State private var projects: [Project] = []
    @State private var showingAddProject = false
    @State private var selectedProject: Project? = nil

    enum SortOption: String, CaseIterable, Identifiable {
        case startDateDescending = "Newest"
        case startDateAscending = "Oldest"
        case nameAscending = "Name A–Z"
        case nameDescending = "Name Z–A"
        case completedFirst = "Completed"
        case activeFirst = "Active"
        case dueSoon = "Due Soon"

        var id: String { self.rawValue }
    }

    @State private var sortOption: SortOption = .startDateDescending

    var sortedProjects: [Project] {
        switch sortOption {
        case .startDateDescending:
            return projects.sorted { $0.startDate > $1.startDate }
        case .startDateAscending:
            return projects.sorted { $0.startDate < $1.startDate }
        case .nameAscending:
            return projects.sorted { $0.name.lowercased() < $1.name.lowercased() }
        case .nameDescending:
            return projects.sorted { $0.name.lowercased() > $1.name.lowercased() }
        case .completedFirst:
            return projects.sorted { ($0.isProjectCompleted ? 0 : 1) < ($1.isProjectCompleted ? 0 : 1) }
        case .activeFirst:
            return projects.sorted { ($0.isProjectCompleted ? 0 : 1) > ($1.isProjectCompleted ? 0 : 1) }
        case .dueSoon:
            return projects.sorted { $0.endDate < $1.endDate }
        }
    }

    var body: some View {
        NavigationView {
            ZStack {
                VStack(spacing: 0) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Projects")
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
                    .padding(.bottom, 4)

                    if sortedProjects.isEmpty {
                        Spacer()
                        Text("No Projects Yet")
                            .font(.title2)
                            .foregroundColor(.gray)
                        Spacer()
                    } else {
                        List {
                            ForEach(sortedProjects) { project in
                                VStack {
                                    Button {
                                        selectedProject = project
                                    } label: {
                                        projectRow(project)
                                            .padding()
                                            .background(
                                                RoundedRectangle(cornerRadius: 12)
                                                    .fill(Color(UIColor.systemGray6))
                                            )
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                }
                                .padding(.vertical, 4)
                                .padding(.horizontal, 8)
                                .listRowInsets(EdgeInsets())
                                .listRowSeparator(.hidden)
                            }
                            .onDelete(perform: deleteProject)
                        }
                        .listStyle(PlainListStyle())
                    }
                }

                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Button(action: {
                            showingAddProject = true
                        }) {
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

                NavigationLink(
                    destination: selectedProject.map { project in
                        ProjectDetailView(project: Binding(
                            get: {
                                if let index = projects.firstIndex(where: { $0.id == project.id }) {
                                    return $projects[index].wrappedValue
                                }
                                return project
                            },
                            set: { newValue in
                                if let index = projects.firstIndex(where: { $0.id == project.id }) {
                                    projects[index] = newValue
                                    saveProjectsToStorage()
                                }
                            }
                        ), projects: $projects)
                    },
                    isActive: Binding(
                        get: { selectedProject != nil },
                        set: { isActive in
                            if !isActive { selectedProject = nil }
                        }
                    )
                ) { EmptyView() }
            }
            .sheet(isPresented: $showingAddProject) {
                AddProjectView(projects: $projects)
            }
            .onAppear(perform: loadProjects)
        }
    }

    private func projectRow(_ project: Project) -> some View {
        let textColor: Color = project.isProjectCompleted ? .gray : .primary

        return HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(String(project.name.prefix(25)))
                    .font(.headline)
                    .lineLimit(1)
                    .strikethrough(project.isProjectCompleted)
                    .foregroundColor(textColor)

                Text(project.customer)
                    .font(.subheadline)
                    .lineLimit(2)
                    .foregroundColor(project.isProjectCompleted ? .gray : .secondary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                DetailRow(title: "", value: project.projectType)
                    .foregroundColor(textColor)

                VStack(alignment: .trailing, spacing: 0) {
                    Text(formattedDate(project.endDate))
                        .font(.subheadline)
                        .foregroundColor(deadlineColor(for: project))

                    Text(deadlineLabel(for: project))
                        .font(.caption2)
                        .foregroundColor(deadlineColor(for: project))
                }
            }

            if !project.githubRepo.isEmpty {
                Button(action: {
                    if let url = URL(string: project.githubRepo) {
                        UIApplication.shared.open(url)
                    }
                }) {
                    Image(systemName: "arrow.up.right.square.fill")
                        .font(.title2)
                        .foregroundColor(.purple)
                }
            }
        }
    }

    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }

    private func deadlineColor(for project: Project) -> Color {
        let today = Calendar.current.startOfDay(for: Date())
        let end = Calendar.current.startOfDay(for: project.endDate)
        let daysLeft = Calendar.current.dateComponents([.day], from: today, to: end).day ?? 0
        return daysLeft <= 10 ? .red : .green
    }

    private func deadlineLabel(for project: Project) -> String {
        let today = Calendar.current.startOfDay(for: Date())
        let end = Calendar.current.startOfDay(for: project.endDate)
        let daysLeft = Calendar.current.dateComponents([.day], from: today, to: end).day ?? 0

        switch daysLeft {
        case ..<0:
            return "Overdue by \(-daysLeft) day\(abs(daysLeft) == 1 ? "" : "s")"
        case 0:
            return "Due today"
        case 1:
            return "Due tomorrow"
        default:
            return "Due in \(daysLeft) days"
        }
    }

    private func deleteProject(at offsets: IndexSet) {
        for index in offsets {
            let projectToDelete = sortedProjects[index]
            if let actualIndex = projects.firstIndex(where: { $0.id == projectToDelete.id }) {
                projects.remove(at: actualIndex)
            }
        }
        saveProjectsToStorage()
    }

    private func loadProjects() {
        if let data = UserDefaults.standard.data(forKey: "projects"),
           let savedProjects = try? JSONDecoder().decode([Project].self, from: data) {
            projects = savedProjects
        }
    }

    private func saveProjectsToStorage() {
        if let data = try? JSONEncoder().encode(projects) {
            UserDefaults.standard.set(data, forKey: "projects")
        }
    }
}
