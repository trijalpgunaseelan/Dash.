//
//  ProjectView.swift
//  Dash
//

import SwiftUI

struct ProjectView: View {

    @State private var projects: [Project] = []
    @State private var showingAddProject = false
    @State private var selectedProject: Project? = nil
    @State private var searchText = ""

    enum SortOption: String, CaseIterable, Identifiable {
        case startDateDescending = "Newest"
        case startDateAscending = "Oldest"
        case nameAscending = "A–Z"
        case nameDescending = "Z–A"
        case completedFirst = "Completed"
        case activeFirst = "Active"
        case dueSoon = "Due Soon"
        var id: String { rawValue }
    }

    @State private var sortOption: SortOption = .startDateDescending

    var filteredProjects: [Project] {
        if searchText.isEmpty { return projects }
        return projects.filter {
            $0.name.lowercased().contains(searchText.lowercased()) ||
            $0.customer.lowercased().contains(searchText.lowercased()) ||
            $0.developer.lowercased().contains(searchText.lowercased())
        }
    }

    var sortedProjects: [Project] {
        switch sortOption {
        case .startDateDescending:
            return filteredProjects.sorted { $0.startDate > $1.startDate }
        case .startDateAscending:
            return filteredProjects.sorted { $0.startDate < $1.startDate }
        case .nameAscending:
            return filteredProjects.sorted { $0.name.lowercased() < $1.name.lowercased() }
        case .nameDescending:
            return filteredProjects.sorted { $0.name.lowercased() > $1.name.lowercased() }
        case .completedFirst:
            return filteredProjects.sorted { ($0.isProjectCompleted ? 0 : 1) < ($1.isProjectCompleted ? 0 : 1) }
        case .activeFirst:
            return filteredProjects.sorted { ($0.isProjectCompleted ? 0 : 1) > ($1.isProjectCompleted ? 0 : 1) }
        case .dueSoon:
            return filteredProjects.sorted { $0.endDate < $1.endDate }
        }
    }

    // Quick stats
    var activeCount: Int { projects.filter { !$0.isProjectCompleted }.count }
    var completedCount: Int { projects.filter { $0.isProjectCompleted }.count }
    var overdueCount: Int {
        projects.filter {
            !$0.isProjectCompleted &&
            Calendar.current.startOfDay(for: $0.endDate) < Calendar.current.startOfDay(for: Date())
        }.count
    }

    var body: some View {

        NavigationView {

            ZStack {

                // Background
                LinearGradient(
                    colors: [
                        Color(red: 0.06, green: 0.06, blue: 0.09),
                        Color(red: 0.09, green: 0.08, blue: 0.13)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                VStack(spacing: 0) {
                    glassHeader
                    searchBar
                    statsRow
                    filterBar
                    projectList
                }

                floatingButton

                // Hidden NavigationLink
                NavigationLink(
                    destination: selectedProject.map { project in
                        ProjectDetailView(
                            project: Binding(
                                get: {
                                    if let index = projects.firstIndex(where: { $0.id == project.id }) {
                                        return projects[index]
                                    }
                                    return project
                                },
                                set: { newValue in
                                    if let index = projects.firstIndex(where: { $0.id == project.id }) {
                                        projects[index] = newValue
                                        saveProjectsToStorage()
                                    }
                                }
                            ),
                            projects: $projects
                        )
                    },
                    isActive: Binding(
                        get: { selectedProject != nil },
                        set: { if !$0 { selectedProject = nil } }
                    )
                ) { EmptyView() }
            }

            .navigationBarHidden(true)

            .sheet(isPresented: $showingAddProject) {
                AddProjectView(projects: $projects)
            }

            .onAppear { loadProjects() }
        }
    }

    // MARK: - Glass Header

    var glassHeader: some View {

        ZStack {
            Rectangle()
                .fill(.ultraThinMaterial)
                .overlay(Rectangle().fill(Color.purple.opacity(0.06)))
                .ignoresSafeArea(edges: .top)

            HStack {

                // Left: icon
                ZStack {
                    Circle()
                        .fill(Color.white.opacity(0.08))
                        .overlay(Circle().stroke(Color.white.opacity(0.1), lineWidth: 1))
                        .frame(width: 40, height: 40)
                    Image(systemName: "folder.badge.gearshape")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white.opacity(0.7))
                }

                Spacer()

                // Center: title
                VStack(spacing: 2) {
                    Text("Projects")
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                    Text("\(projects.count) total")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.purple.opacity(0.8))
                }

                Spacer()

                // Right: menu
                AppMenuButton()
                    .frame(width: 40, height: 40)
                    .background(
                        Circle()
                            .fill(Color.white.opacity(0.08))
                            .overlay(Circle().stroke(Color.white.opacity(0.1), lineWidth: 1))
                    )
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)
            .padding(.bottom, 14)
        }
        .frame(height: 80)
    }

    // MARK: - Search Bar

    var searchBar: some View {

        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(.white.opacity(0.4))

            TextField("Search projects...", text: $searchText)
                .font(.system(size: 15))
                .foregroundColor(.white)
                .tint(.purple)

            if !searchText.isEmpty {
                Button { searchText = "" } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.white.opacity(0.3))
                }
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 11)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color.white.opacity(0.07))
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(Color.white.opacity(0.08), lineWidth: 1)
                )
        )
        .padding(.horizontal, 16)
        .padding(.top, 12)
        .padding(.bottom, 4)
    }

    // MARK: - Stats Row

    var statsRow: some View {

        HStack(spacing: 10) {

            statCard(value: "\(activeCount)", label: "Active", color: .purple, icon: "bolt.fill")
            statCard(value: "\(completedCount)", label: "Done", color: .green, icon: "checkmark.seal.fill")
            statCard(value: "\(overdueCount)", label: "Overdue", color: .red, icon: "exclamationmark.triangle.fill")
        }
        .padding(.horizontal, 16)
        .padding(.top, 10)
        .padding(.bottom, 4)
    }

    func statCard(value: String, label: String, color: Color, icon: String) -> some View {

        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(color)

            VStack(alignment: .leading, spacing: 1) {
                Text(value)
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                Text(label)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(.white.opacity(0.4))
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .padding(.horizontal, 12)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(color.opacity(0.08))
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(color.opacity(0.15), lineWidth: 1)
                )
        )
    }

    // MARK: - Filter Bar

    var filterBar: some View {

        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(SortOption.allCases) { option in
                    Button {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            sortOption = option
                        }
                        let impact = UIImpactFeedbackGenerator(style: .light)
                        impact.impactOccurred()
                    } label: {
                        Text(option.rawValue)
                            .font(.system(size: 13, weight: sortOption == option ? .semibold : .regular))
                            .padding(.horizontal, 14)
                            .padding(.vertical, 7)
                            .background(
                                Capsule()
                                    .fill(sortOption == option ? Color.purple : Color.white.opacity(0.07))
                                    .overlay(
                                        Capsule()
                                            .stroke(
                                                sortOption == option ? Color.purple.opacity(0.5) : Color.white.opacity(0.06),
                                                lineWidth: 1
                                            )
                                    )
                            )
                            .foregroundColor(sortOption == option ? .white : .white.opacity(0.55))
                    }
                }
            }
            .padding(.horizontal, 16)
        }
        .padding(.top, 10)
        .padding(.bottom, 8)
    }

    // MARK: - Project List

    var projectList: some View {

        Group {
            if sortedProjects.isEmpty {
                emptyState
            } else {
                List {
                    ForEach(sortedProjects) { project in
                        projectCard(project)
                            .listRowInsets(EdgeInsets())
                            .listRowSeparator(.hidden)
                            .listRowBackground(Color.clear)
                            .padding(.vertical, 5)
                            .padding(.horizontal, 16)
                            .onTapGesture {
                                let impact = UIImpactFeedbackGenerator(style: .light)
                                impact.impactOccurred()
                                selectedProject = project
                            }
                            .swipeActions(edge: .trailing) {
                                Button(role: .destructive) {
                                    deleteProject(project)
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                    }

                    Color.clear
                        .frame(height: 90)
                        .listRowInsets(EdgeInsets())
                        .listRowSeparator(.hidden)
                        .listRowBackground(Color.clear)
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
            }
        }
    }

    // MARK: - Empty State

    var emptyState: some View {

        VStack(spacing: 16) {
            Spacer()

            ZStack {
                Circle()
                    .fill(Color.purple.opacity(0.08))
                    .frame(width: 90, height: 90)
                Image(systemName: "folder.badge.plus")
                    .font(.system(size: 36, weight: .light))
                    .foregroundColor(.purple.opacity(0.5))
            }

            Text("No Projects Yet")
                .font(.system(size: 20, weight: .semibold, design: .rounded))
                .foregroundColor(.white.opacity(0.6))

            Text("Tap + to create your first project")
                .font(.system(size: 14))
                .foregroundColor(.white.opacity(0.3))

            Spacer()
        }
    }

    // MARK: - Project Card

    private func projectCard(_ project: Project) -> some View {

        let daysLeft = Calendar.current.dateComponents(
            [.day],
            from: Calendar.current.startOfDay(for: Date()),
            to: Calendar.current.startOfDay(for: project.endDate)
        ).day ?? 0

        let deadlineColor: Color = project.isProjectCompleted ? .gray :
            (daysLeft < 0 ? .red : daysLeft <= 10 ? .orange : .green)

        return VStack(spacing: 0) {

            HStack(spacing: 0) {

                // Accent bar
                RoundedRectangle(cornerRadius: 3)
                    .fill(
                        LinearGradient(
                            colors: project.isProjectCompleted
                                ? [Color.gray.opacity(0.5), Color.gray.opacity(0.3)]
                                : [Color.purple, Color.purple.opacity(0.5)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(width: 4)
                    .padding(.vertical, 14)
                    .padding(.leading, 14)

                VStack(alignment: .leading, spacing: 10) {

                    // Title + type row
                    HStack(spacing: 8) {

                        Text(project.name.isEmpty ? "Untitled" : project.name)
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(project.isProjectCompleted ? .white.opacity(0.4) : .white)
                            .strikethrough(project.isProjectCompleted, color: .white.opacity(0.3))
                            .lineLimit(1)

                        Spacer()

                        if project.isProjectCompleted {
                            HStack(spacing: 4) {
                                Image(systemName: "checkmark.seal.fill")
                                    .font(.system(size: 9))
                                Text("Done")
                                    .font(.system(size: 10, weight: .semibold))
                            }
                            .foregroundColor(.green.opacity(0.8))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Capsule().fill(Color.green.opacity(0.1)))
                        } else if !project.projectType.isEmpty {
                            Text(project.projectType)
                                .font(.system(size: 10, weight: .medium))
                                .foregroundColor(.purple.opacity(0.8))
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Capsule().fill(Color.purple.opacity(0.1)))
                                .lineLimit(1)
                        }
                    }

                    // Customer + developer
                    HStack(spacing: 12) {

                        if !project.customer.isEmpty {
                            HStack(spacing: 4) {
                                Image(systemName: "person")
                                    .font(.system(size: 10))
                                Text(project.customer)
                                    .font(.system(size: 12))
                                    .lineLimit(1)
                            }
                            .foregroundColor(.white.opacity(0.4))
                        }

                        if !project.developer.isEmpty {
                            HStack(spacing: 4) {
                                Image(systemName: "hammer")
                                    .font(.system(size: 10))
                                Text(project.developer)
                                    .font(.system(size: 12))
                                    .lineLimit(1)
                            }
                            .foregroundColor(.white.opacity(0.35))
                        }

                        Spacer()
                    }

                    // Progress bar
                    VStack(alignment: .leading, spacing: 5) {

                        GeometryReader { geo in
                            ZStack(alignment: .leading) {

                                RoundedRectangle(cornerRadius: 4)
                                    .fill(Color.white.opacity(0.07))
                                    .frame(height: 6)

                                RoundedRectangle(cornerRadius: 4)
                                    .fill(
                                        LinearGradient(
                                            colors: project.isProjectCompleted
                                                ? [Color.green.opacity(0.7), Color.green.opacity(0.4)]
                                                : [Color.purple, Color.purple.opacity(0.6)],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                                    .frame(width: geo.size.width * CGFloat(project.progress), height: 6)
                            }
                        }
                        .frame(height: 6)
                    }

                    // Footer: deadline + amount + github
                    HStack(spacing: 10) {

                        // Deadline
                        HStack(spacing: 4) {
                            Image(systemName: "calendar")
                                .font(.system(size: 9))
                            Text(deadlineLabel(for: project))
                                .font(.system(size: 11, weight: .medium))
                        }
                        .foregroundColor(deadlineColor)

                        Text("·")
                            .foregroundColor(.white.opacity(0.2))

                        // Progress %
                        Text("\(Int(project.progress * 100))%")
                            .font(.system(size: 11, weight: .semibold, design: .monospaced))
                            .foregroundColor(.white.opacity(0.35))

                        Spacer()

                        // Amount
                        if project.totalAmount > 0 {
                            HStack(spacing: 3) {
                                Image(systemName: "banknote")
                                    .font(.system(size: 9))
                                Text(String(format: "%.0f", project.totalAmount))
                                    .font(.system(size: 11, weight: .semibold))
                            }
                            .foregroundColor(.green.opacity(0.7))
                            .padding(.horizontal, 7)
                            .padding(.vertical, 3)
                            .background(Capsule().fill(Color.green.opacity(0.08)))
                        }

                        // GitHub link
                        if !project.githubRepo.isEmpty {
                            Button {
                                if let url = URL(string: project.githubRepo) {
                                    UIApplication.shared.open(url)
                                }
                            } label: {
                                HStack(spacing: 3) {
                                    Image(systemName: "chevron.left.forwardslash.chevron.right")
                                        .font(.system(size: 9, weight: .semibold))
                                    Text("Repo")
                                        .font(.system(size: 10, weight: .semibold))
                                }
                                .foregroundColor(.purple.opacity(0.8))
                                .padding(.horizontal, 7)
                                .padding(.vertical, 3)
                                .background(Capsule().fill(Color.purple.opacity(0.1)))
                            }
                        }
                    }
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 14)
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(
                    LinearGradient(
                        colors: [
                            Color(red: 0.14, green: 0.13, blue: 0.18),
                            Color(red: 0.12, green: 0.11, blue: 0.16)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .shadow(color: Color.black.opacity(0.35), radius: 10, x: 0, y: 4)
                .overlay(
                    RoundedRectangle(cornerRadius: 18)
                        .stroke(Color.white.opacity(0.06), lineWidth: 1)
                )
        )
    }

    // MARK: - Floating Action Button

    var floatingButton: some View {

        VStack {
            Spacer()
            HStack {
                Spacer()

                Button {
                    let impact = UIImpactFeedbackGenerator(style: .medium)
                    impact.impactOccurred()
                    showingAddProject = true
                } label: {
                    ZStack {
                        Circle()
                            .fill(Color.purple.opacity(0.35))
                            .frame(width: 64, height: 64)
                            .blur(radius: 12)

                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [Color.purple, Color(red: 0.5, green: 0.2, blue: 0.9)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 56, height: 56)
                            .overlay(Circle().stroke(Color.white.opacity(0.25), lineWidth: 1))
                            .shadow(color: Color.purple.opacity(0.5), radius: 14, x: 0, y: 6)

                        Image(systemName: "plus")
                            .font(.system(size: 22, weight: .semibold))
                            .foregroundColor(.white)
                    }
                }
                .padding(.bottom, 28)
                .padding(.trailing, 20)
            }
        }
    }

    // MARK: - Helpers

    private func deadlineLabel(for project: Project) -> String {
        let today = Calendar.current.startOfDay(for: Date())
        let end = Calendar.current.startOfDay(for: project.endDate)
        let daysLeft = Calendar.current.dateComponents([.day], from: today, to: end).day ?? 0

        if project.isProjectCompleted { return "Completed" }
        switch daysLeft {
        case ..<0: return "Overdue \(-daysLeft)d"
        case 0: return "Due today"
        case 1: return "Tomorrow"
        default: return "\(daysLeft)d left"
        }
    }

    private func deleteProject(_ project: Project) {
        if let index = projects.firstIndex(where: { $0.id == project.id }) {
            projects.remove(at: index)
            saveProjectsToStorage()
        }
    }

    private func loadProjects() {
        if let data = UserDefaults.standard.data(forKey: "projects"),
           let saved = try? JSONDecoder().decode([Project].self, from: data) {
            projects = saved
        }
    }

    private func saveProjectsToStorage() {
        if let data = try? JSONEncoder().encode(projects) {
            UserDefaults.standard.set(data, forKey: "projects")
        }
    }
}
