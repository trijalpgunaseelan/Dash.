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

    var body: some View {
        NavigationView {
            VStack {
                headerView
                projectsListView
            }
            .background(navigationLink)
            .overlay(addButton)
            .onAppear(perform: loadProjects) // Load projects when the view appears
        }
    }

    private var headerView: some View {
        HStack {
            Text("Projects")
                .font(.custom("Chewy-Regular", size: 28))
                .bold()
                .padding(.top, 16)
                .padding(.leading, 16)
            Spacer()
        }
    }

    private var projectsListView: some View {
        Group {
            if projects.isEmpty {
                emptyProjectsView
            } else {
                projectsList
            }
        }
    }

    private var emptyProjectsView: some View {
        VStack {
            Spacer()
            Text("No Projects Yet")
                .font(.title2)
                .foregroundColor(.gray)
                .padding()
            Spacer()
        }
    }

    private var projectsList: some View {
        List {
            ForEach(projects) { project in
                Button {
                    selectedProject = project
                } label: {
                    projectRow(project)
                }
            }
            .onDelete(perform: deleteProject)
        }
        .listStyle(PlainListStyle())
    }

    private func projectRow(_ project: Project) -> some View {
        HStack {
            VStack(alignment: .leading) {
                Text(project.name)
                    .font(.custom("Chewy-Regular", size: 20))
                Text(project.customer)
                    .lineLimit(1)
                    .foregroundColor(.secondary)
            }
            Spacer()
            DetailRow(
                title: "",
                value: project.projectType
            )
            Spacer()
            DetailRow(
                title: "",
                value: formattedDate(project.endDate)
            )
            Spacer()
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

    private var navigationLink: some View {
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
                ))
            },
            isActive: Binding(
                get: { selectedProject != nil },
                set: { isActive in
                    if !isActive { selectedProject = nil }
                }
            )
        ) { EmptyView() }
    }

    private var addButton: some View {
        VStack {
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
            .sheet(isPresented: $showingAddProject) {
                AddProjectView(projects: $projects)
            }
        }
    }

    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }

    private func deleteProject(at offsets: IndexSet) {
        projects.remove(atOffsets: offsets)
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
