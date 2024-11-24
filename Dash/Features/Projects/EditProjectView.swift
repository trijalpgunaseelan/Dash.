//
//  EditProjectView.swift
//  Dash
//
//  Created by Trijal Gunaseelan on 11/22/24.
//

import SwiftUI
import Foundation

struct EditProjectView: View {
    @Binding var project: Project
    @Binding var lastEditedDate: Date?
    @Environment(\.presentationMode) var presentationMode
    @State private var name = ""
    @State private var developer = ""
    @State private var customer = ""
    @State private var startDate = Date()
    @State private var endDate = Date()
    @State private var selectedLanguages = [String]()
    @State private var projectType = ""
    @State private var githubRepo = ""
    let projectTypes = ["Android App", "iOS App", "Cross Platform App", "Website", "Android App and Website", "iOS App and Website", "Cross Platform App and Website", "IOT", "Others"]
    let languages = ["Java", "Kotlin", "C++", "Dart", "Rust", "Swift", "Objective-C", "SwiftUI", "React Native", "Flutter", "Xamarin", "Elixir", "PureScript", "HTML", "CSS", "Tailwind CSS", "JavaScript", "PHP", "Ruby", "Python", "TypeScript", "Go", "F#", "Clojure", "MySQL", "PostgreSQL", "Node.js", "ASP.NET", "Express.js", "Laravel", "Django", "Flask", "Spring", "Ruby on Rails"]

    var body: some View {
        NavigationView {
            Form {
                TextField("Project Name", text: $name)
                    .onChange(of: name) { _ in
                        autoSave()
                    }
                TextField("Developer", text: $developer)
                    .onChange(of: developer) { _ in
                        autoSave()
                    }
                TextField("Customer", text: $customer)
                    .onChange(of: customer) { _ in
                        autoSave()
                    }
                DatePicker("Start Date", selection: $startDate, displayedComponents: .date)
                    .onChange(of: startDate) { _ in
                        autoSave()
                    }
                DatePicker("Expected End Date", selection: $endDate, displayedComponents: .date)
                    .onChange(of: endDate) { _ in
                        autoSave()
                    }
                MultiSelectPicker(selections: $selectedLanguages, options: languages, title: "Languages Used")
                    .onChange(of: selectedLanguages) { _ in
                        autoSave()
                    }
                Picker("Project Type", selection: $projectType) {
                    ForEach(projectTypes, id: \.self) {
                        Text($0)
                    }
                }
                .onChange(of: projectType) { _ in
                    autoSave()
                }
                TextField("GitHub Repository", text: $githubRepo)
                    .onChange(of: githubRepo) { _ in
                        autoSave()
                    }
                VStack {
                    Text("Project Progress")
                    Slider(value: $project.progress, in: 0...1, step: 0.01)
                        .accentColor(.purple)
                        .padding()
                        .onChange(of: project.progress) { _ in
                            autoSave()
                        }
                }
                if let lastEdited = lastEditedDate {
                    Text("Last Edited: \(formattedDate(lastEdited))")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            }
            .navigationBarTitle(Text("Edit Project").font(.custom("Chewy-Regular", size: 18)), displayMode: .inline)
            .onAppear {
                name = project.name
                developer = project.developer
                customer = project.customer
                startDate = project.startDate
                endDate = project.endDate
                selectedLanguages = project.languagesUsed.components(separatedBy: ", ").filter { !$0.isEmpty }
                projectType = project.projectType
                githubRepo = project.githubRepo
            }
        }
    }

    private func autoSave() {
        project.name = name
        project.developer = developer
        project.customer = customer
        project.startDate = startDate
        project.endDate = endDate
        project.languagesUsed = selectedLanguages.joined(separator: ", ").trimmingCharacters(in: CharacterSet(charactersIn: ", "))
        project.projectType = projectType
        project.githubRepo = githubRepo
        lastEditedDate = Date()
        saveProjectToStorage()
    }

    private func saveProjectToStorage() {
        if var projects = loadProjectsFromStorage() {
            if let index = projects.firstIndex(where: { $0.id == project.id }) {
                projects[index] = project
            } else {
                projects.append(project)
            }
            if let data = try? JSONEncoder().encode(projects) {
                UserDefaults.standard.set(data, forKey: "projects")
            }
        }
    }

    private func loadProjectsFromStorage() -> [Project]? {
        if let data = UserDefaults.standard.data(forKey: "projects"),
           let projects = try? JSONDecoder().decode([Project].self, from: data) {
            return projects
        }
        return nil
    }

    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
}
