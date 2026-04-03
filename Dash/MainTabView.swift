//
//  MainTabView.swift
//  Dash
//
//  Created by Trijal Gunaseelan on 11/19/24.
//  Edited by Dhakshika on 2/4/26
import SwiftUI

struct MainTabView: View {

    init() {
        UITabBar.appearance().backgroundColor = UIColor.black
        UITabBar.appearance().unselectedItemTintColor = UIColor.gray
    }

    var body: some View {

        TabView {

            GitHubView()
                .tabItem {
                    VStack {
                        Image("githubIcon")
                            .renderingMode(.template)
                            .foregroundColor(.purple)
                        Text("GitHub")
                    }
                }

            DailyPlannerView()
                .tabItem {
                    VStack {
                        Image(systemName: "calendar")
                        Text("Planner")
                    }
                }

            NotesView()
                .tabItem {
                    VStack {
                        Image("notesIcon")
                            .renderingMode(.template)
                        Text("Notes")
                    }
                }

            ProjectView()
                .tabItem {
                    VStack {
                        Image("projectIcon")
                            .renderingMode(.template)
                        Text("Projects")
                    }
                }
        }
        .accentColor(.purple)
        .onAppear {
            UITabBar.appearance().tintColor = UIColor.purple
        }
    }
}
