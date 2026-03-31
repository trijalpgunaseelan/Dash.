//
//  NotificationsView.swift
//  Dash
//
//  Created by Dhakshika on 3/31/26.
//

import SwiftUI

struct NotificationsView: View {
    let notifications: [GitHubNotification]
    let onRefresh: () -> Void

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            List {
                if notifications.isEmpty {
                    Text("No notifications")
                        .foregroundColor(.secondary)
                } else {
                    ForEach(notifications) { notification in
                        VStack(alignment: .leading, spacing: 6) {
                            Text(notification.subject.title)
                                .font(.headline)
                                .lineLimit(2)

                            HStack(spacing: 8) {
                                Text(notification.subject.type)
                                    .font(.caption)
                                    .foregroundColor(.secondary)

                                Text(notification.unread ? "Unread" : "Read")
                                    .font(.caption)
                                    .fontWeight(.semibold)
                                    .foregroundColor(notification.unread ? .blue : .secondary)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
            .navigationTitle("Notifications")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Refresh") {
                        onRefresh()
                    }
                }
            }
        }
    }
}
