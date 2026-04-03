//
//  GithubView.swift
//  Dash
//
//  Created by Trijal Gunaseelan on 5/30/25.
//  Edited by Dahkshika

import SwiftUI

struct GitHubView: View {

    @StateObject private var authManager = GitHubAuthManager()

    @State private var sortOption: SortOption = .newest
    @State private var hasRestoredSession = false
    @State private var position: CGSize = .zero
    @GestureState private var dragTranslation: CGSize = .zero
    @State private var showNotifications = false

    enum SortOption: String, CaseIterable, Identifiable {
        case newest = "Newest"
        case oldest = "Oldest"
        case nameAscending = "Name A-Z"
        case nameDescending = "Name Z-A"
        case publicFirst = "Public"
        case privateFirst = "Private"

        var id: String { self.rawValue }
    }

    private var sortedRepositories: [Repository] {

        let repositories = authManager.repositories

        switch sortOption {
        case .newest:
            return repositories.sorted { ($0.createdAt ?? .distantPast) > ($1.createdAt ?? .distantPast) }

        case .oldest:
            return repositories.sorted { ($0.createdAt ?? .distantPast) < ($1.createdAt ?? .distantPast) }

        case .nameAscending:
            return repositories.sorted { $0.name.lowercased() < $1.name.lowercased() }

        case .nameDescending:
            return repositories.sorted { $0.name.lowercased() > $1.name.lowercased() }

        case .publicFirst:
            return repositories.sorted { ($0.isPrivate ?? false) == false && ($1.isPrivate ?? false) == true }

        case .privateFirst:
            return repositories.sorted { ($0.isPrivate ?? false) == true && ($1.isPrivate ?? false) == false }
        }
    }

    private var unreadCount: Int {
        authManager.notifications.filter { $0.unread }.count
    }

    var body: some View {

        NavigationView {

            ZStack {

                VStack(spacing: 0) {

                    if authManager.isAuthenticated {
                        authenticatedContent
                    } else {
                        Spacer()
                        LoginView(authManager: authManager)
                        Spacer()
                    }
                }

                VStack {
                    HStack {
                        Spacer()
                        floatingGitHubButton
                    }
                    Spacer()
                }
                .padding(.top, 70)
                .padding(.trailing, 16)
            }

            .navigationTitle("GitHub")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { toolbarContent }

            .sheet(isPresented: $showNotifications) {
                NotificationsView(
                    notifications: authManager.notifications,
                    onRefresh: {
                        _Concurrency.Task {
                            try? await authManager.fetchNotifications()
                        }
                    }
                )
            }

            .task {
                guard !hasRestoredSession else { return }
                hasRestoredSession = true
                await authManager.restoreSession()
            }

            .task(id: authManager.isAuthenticated) {
                guard hasRestoredSession, authManager.isAuthenticated else { return }
                await authManager.loadAuthenticatedDataIfNeeded()
            }
        }
    }

    private var floatingGitHubButton: some View {

        Image("githubIcon")
            .resizable()
            .frame(width: 30, height: 30)
            .padding()
            .background(Circle().fill(Color.black).shadow(radius: 3))
            .offset(
                x: position.width + dragTranslation.width,
                y: position.height + dragTranslation.height
            )
            .gesture(
                DragGesture()
                    .updating($dragTranslation) { value, state, _ in
                        state = value.translation
                    }
                    .onEnded { value in
                        position.width += value.translation.width
                        position.height += value.translation.height
                    }
            )
            .onTapGesture {
                if let url = URL(string: "github://") {
                    UIApplication.shared.open(url)
                }
            }
    }

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {

        ToolbarItem(placement: .navigationBarLeading) {

            Button {
                showNotifications = true
            } label: {

                ZStack(alignment: .topTrailing) {

                    Image(systemName: "bell")
                        .font(.system(size: 18, weight: .medium))

                    if unreadCount > 0 {
                        Circle()
                            .fill(Color.red)
                            .frame(width: 8, height: 8)
                    }
                }
            }
            .disabled(!authManager.isAuthenticated)
        }

        ToolbarItem(placement: .navigationBarTrailing) {

            AppMenuButton(
                showLogout: true,
                logoutAction: {
                    _Concurrency.Task {
                        await authManager.logoutFromGitHub()
                    }
                }
            )
        }
    }

    private var authenticatedContent: some View {

        VStack(spacing: 0) {

            if authManager.isLoading && sortedRepositories.isEmpty {

                ProgressView("Loading repositories...")
                    .padding()

                Spacer()

            } else if let error = authManager.errorMessage {

                Spacer()

                Text("Error: \(error)")
                    .foregroundColor(.red)
                    .multilineTextAlignment(.center)
                    .padding()

                Spacer()

            } else if sortedRepositories.isEmpty {

                Spacer()

                Text("No repositories found.")
                    .foregroundColor(.gray)

                Spacer()

            } else {

                List {

                    ForEach(sortedRepositories) { repo in

                        VStack(alignment: .leading, spacing: 12) {

                            Text(repo.name)
                                .font(.headline)

                            if let desc = repo.description {

                                Text(desc)
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                    .lineLimit(2)
                            }

                            Spacer().frame(height: 4)

                            HStack {

                                HStack(spacing: 16) {

                                    Label("\(repo.stargazersCount ?? 0)", systemImage: "star")

                                    Label("\(repo.forksCount ?? 0)", systemImage: "tuningfork")

                                    Text(repo.isPrivate == true ? "Private" : "Public")
                                        .foregroundColor(repo.isPrivate == true ? .red : .green)
                                }
                                .font(.caption)

                                Spacer()

                                Button {

                                    if let url = URL(string: repo.htmlURL) {
                                        UIApplication.shared.open(url)
                                    }

                                } label: {

                                    Label("Open in GitHub", systemImage: "arrow.up.right.square")
                                        .font(.caption)
                                        .foregroundColor(.purple)
                                }
                            }
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 14)
                                .fill(Color(UIColor.systemGray6))
                        )
                        .listRowInsets(EdgeInsets())
                        .padding(.vertical, 6)
                        .listRowSeparator(.hidden)
                    }
                }
                .listStyle(PlainListStyle())

                .refreshable {
                    try? await authManager.fetchRepositories()
                }
            }
        }
    }
}
