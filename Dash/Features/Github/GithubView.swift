//
//  GithubView.swift
//  Dash
//
//  Created by Trijal Gunaseelan on 11/20/24.
//

import SwiftUI

struct GitHubView: View {
    @StateObject private var authManager = GitHubAuthManager()

    @State private var sortOption: SortOption = .newest
    @State private var hasRestoredSession = false
    @State private var position: CGSize = .zero
    @GestureState private var dragTranslation: CGSize = .zero

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
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button("Logout from GitHub") {
                            Swift.Task {
                                await authManager.logoutFromGitHub()
                            }
                        }
                    } label: {
                        Image(systemName: "ellipsis")
                    }
                    .disabled(!authManager.isAuthenticated)
                }
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
                openGitHubApp()
            }
    }

    private var authenticatedContent: some View {
        VStack(spacing: 0) {
            headerSection

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
                        VStack(alignment: .leading, spacing: 4) {
                            Text(repo.name)
                                .font(.headline)
                                .lineLimit(1)

                            if let desc = repo.description {
                                Text(desc)
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                                    .lineLimit(2)
                            }

                            if let date = repo.createdAt {
                                Text("Created: \(formattedDate(date))")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }

                            Text(repo.isPrivate == true ? "Private" : "Public")
                                .font(.caption2)
                                .foregroundColor(repo.isPrivate == true ? .red : .green)

                            Button {
                                if let url = URL(string: repo.htmlURL) {
                                    UIApplication.shared.open(url)
                                }
                            } label: {
                                HStack {
                                    Spacer()
                                    Label("Open in GitHub", systemImage: "arrow.up.right.square")
                                        .font(.caption)
                                        .foregroundColor(.purple)
                                }
                            }
                        }
                        .padding()
                        .background(RoundedRectangle(cornerRadius: 12).fill(Color(UIColor.systemGray6)))
                        .listRowInsets(EdgeInsets())
                        .padding(.vertical, 4)
                        .listRowSeparator(.hidden)
                    }
                }
                .listStyle(PlainListStyle())
            }
        }
    }

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("GitHub Repos")
                .font(.system(size: 26, weight: .bold))

            if let user = authManager.user {
                HStack(spacing: 10) {
                    AsyncImage(url: URL(string: user.avatarURL ?? "")) { image in
                        image.resizable().scaledToFill()
                    } placeholder: {
                        Circle()
                            .fill(Color(UIColor.systemGray5))
                    }
                    .frame(width: 36, height: 36)
                    .clipShape(Circle())

                    VStack(alignment: .leading, spacing: 2) {
                        Text(user.name ?? user.login)
                            .font(.subheadline.weight(.semibold))
                        Text("@\(user.login)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }

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
    }

    private func openGitHubApp() {
        if let url = URL(string: "github://") {
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
        }
    }

    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
}

