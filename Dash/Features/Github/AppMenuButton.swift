//
//  AppMenuButton.swift
//  Dash
//
//  Created by Dhakshika K S on 02/04/26.
//

import SwiftUI

struct AppMenuButton: View {

    var showLogout: Bool = false
    var logoutAction: (() -> Void)? = nil

    var body: some View {

        Menu {

            if showLogout {
                Button {
                    logoutAction?()
                } label: {
                    Label("Logout", systemImage: "rectangle.portrait.and.arrow.right")
                }
            }

            Button {
                exit(0)
            } label: {
                Label("Close App", systemImage: "xmark.circle")
            }

        } label: {

            Image(systemName: "line.3.horizontal")
                .font(.system(size: 18, weight: .medium))
        }
    }
}
