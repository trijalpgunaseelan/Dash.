//
//  DetailRow.swift
//  Dash
//
//  Created by Trijal Gunaseelan on 11/25/24.
//

import SwiftUI

struct DetailRow: View {
    var title: String
    var value: String

    var body: some View {
        HStack {
            Text(title)
                .font(.subheadline)
                .bold()
            Spacer()
            Text(value)
                .font(.subheadline)
                .foregroundColor(.gray)
        }
        .padding(.vertical, 4)
    }
}
