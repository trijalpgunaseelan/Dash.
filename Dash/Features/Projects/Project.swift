//
//  Project.swift
//  Dash
//
//  Created by Trijal Gunaseelan on 11/22/24.
//

import Foundation

struct Project: Identifiable, Codable {
    var id = UUID()
    var name: String
    var developer: String
    var customer: String
    var startDate: Date
    var endDate: Date
    var progress: Double
    var languagesUsed: String
    var projectType: String
    var githubRepo: String
}
