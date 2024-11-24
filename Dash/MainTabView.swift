//
//  MainTabView.swift
//  Dash
//
//  Created by Trijal Gunaseelan on 11/20/24.
//

import SwiftUI

struct MainTabView: View {
    @State private var isMenuOpen = false

    init() {
        UITabBar.appearance().backgroundColor = UIColor.black
        UITabBar.appearance().unselectedItemTintColor = UIColor.gray
    }

    var body: some View {
        ZStack {
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
                
                NewsView()
                    .tabItem {
                        VStack {
                            Image("newsIcon")
                                .renderingMode(.template)
                                .foregroundColor(.purple)
                            Text("News")
                        }
                    }
            
                NotesView()
                    .tabItem {
                        VStack {
                            Image("notesIcon")
                                .renderingMode(.template)
                                .foregroundColor(.purple)
                            Text("Notes")
                        }
                    }

                ProjectView()
                    .tabItem {
                        VStack {
                            Image("projectIcon")
                                .renderingMode(.template)
                                .foregroundColor(.purple)
                            Text("Projects")
                        }
                    }
            }
            .accentColor(.purple)
            .onAppear {
                UITabBar.appearance().tintColor = UIColor.purple
            }

            if isMenuOpen {
                Color.black.opacity(0.4)
                    .ignoresSafeArea()
                    .onTapGesture {
                        withAnimation {
                            isMenuOpen = false
                        }
                    }

                MenuView(isMenuOpen: $isMenuOpen)
                    .transition(.move(edge: .trailing))
            }

            VStack {
                HStack {
                    Spacer()
                    Button(action: {
                        withAnimation {
                            isMenuOpen.toggle()
                        }
                    }) {
                        Image(systemName: "line.horizontal.3")
                            .font(.system(size: 20))
                            .foregroundColor(isMenuOpen ? .purple : .gray)
                            .padding(12)
                            .background(isMenuOpen ? Color.purple : Color.clear)
                            .clipShape(Circle())
                            .shadow(color: isMenuOpen ? .purple : .clear, radius: 5)
                    }
                    .padding(.trailing, 16)
                }
                Spacer()
            }
            .padding(.top, 50)
        }
        .edgesIgnoringSafeArea(.top)
    }
}
