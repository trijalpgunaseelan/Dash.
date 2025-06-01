//
//  ViewOffsetKey.swift
//  Dash
//
//  Created by Trijal Gunaseelan on 12/1/24.
//

import SwiftUI

struct ViewOffsetKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}
