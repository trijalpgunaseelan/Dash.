//
//  MenuView.swift
//  Dash
//
//  Created by Trijal Gunaseelan on 11/20/24.
//

import SwiftUI

struct MenuView: View {
    @Binding var isMenuOpen: Bool

    var body: some View {
        VStack(spacing: 0) {
            MenuButton(icon: "xmark.circle.fill", title: "Close App") {
                closeApp()
            }
        }
        .frame(width: 200)
        .background(Color.black)
        .cornerRadius(12)
        .shadow(radius: 5)
        .padding()
    }

    private func closeApp() {
        exit(0)
    }
}

struct MenuButton: View {
    let icon: String
    let title: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(.red)
                Text(title)
                    .foregroundColor(.red)
                    .font(.headline)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.black)
            .cornerRadius(8)
        }
    }
}
