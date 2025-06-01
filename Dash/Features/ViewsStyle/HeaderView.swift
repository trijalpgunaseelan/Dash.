//
//  HeaderView.swift
//  Dash
//
//  Created by Trijal Gunaseelan on 12/1/24.
//

import SwiftUICore

struct HeaderView: View {
    let title: String

    var body: some View {
        HStack {
            Text(title)
                .font(.system(size: 28, weight: .bold))
                .bold()
                .padding(.top, 16)
                .padding(.leading, 16)
            Spacer()
        }
        .padding(.bottom, 8)
    }
}
