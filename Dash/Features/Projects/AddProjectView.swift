//
//  AddProjectView.swift
//  Dash
//
//  Created by Trijal Gunaseelan on 11/22/24.
//

import SwiftUI
import Foundation

struct AddProjectView: View {
    @Environment(\.presentationMode) var presentationMode
    @Binding var projects: [Project]
    @State private var project = Project(name: "", developer: "", customer: "", startDate: Date(), endDate: Date(), progress: 0, languagesUsed: "", projectType: "", githubRepo: "", paymentMethod: "", totalAmount: 0)
    @State private var showAlert = false
    @State private var dragAmount = CGSize.zero
    let projectTypes = ["Android App", "iOS App", "Cross Platform App", "Website", "Android App and Website", "iOS App and Website", "Cross Platform App and Website", "IOT", "Others"]
    @State private var selectedLanguages = [String]()
    let languages = ["Java", "Kotlin", "C++", "Dart", "Rust", "Swift", "Objective-C", "SwiftUI", "React Native", "Flutter", "Xamarin", "Elixir", "PureScript", "HTML", "CSS", "Tailwind CSS", "JavaScript", "PHP", "Ruby", "Python", "TypeScript", "Go", "F#", "Clojure", "MySQL", "PostgreSQL", "Node.js", "ASP.NET", "Express.js", "Laravel", "Django", "Flask", "Spring", "Ruby on Rails"]
    let paymentMethods = ["Credit Card", "Debit Card", "PayPal", "Bank Transfer", "UPI", "Other"]

    var body: some View {
        NavigationView {
            Form {
                TextField("Project Name", text: $project.name)
                    .onChange(of: project.name) { _ in
                        autoSave()
                    }
                TextField("Developer", text: $project.developer)
                    .onChange(of: project.developer) { _ in
                        autoSave()
                    }
                TextField("Customer", text: $project.customer)
                    .onChange(of: project.customer) { _ in
                        autoSave()
                    }
                DatePicker("Start Date", selection: $project.startDate, displayedComponents: .date)
                    .onChange(of: project.startDate) { _ in
                        autoSave()
                    }
                DatePicker("Expected End Date", selection: $project.endDate, displayedComponents: .date)
                    .onChange(of: project.endDate) { _ in
                        autoSave()
                    }
                MultiSelectPicker(selections: $selectedLanguages, options: languages, title: "Languages Used")
                Picker("Project Type", selection: $project.projectType) {
                    ForEach(projectTypes, id: \.self) {
                        Text($0)
                    }
                }
                .onChange(of: project.projectType) { _ in
                    autoSave()
                }
                Picker("Payment Method", selection: $project.paymentMethod) {
                    ForEach(paymentMethods, id: \.self) {
                        Text($0)
                    }
                }
                .onChange(of: project.paymentMethod) { _ in
                    autoSave()
                }
                TextField("Total Amount", value: $project.totalAmount, formatter: customNumberFormatter())
                    .keyboardType(.decimalPad)
                    .onChange(of: project.totalAmount) { _ in
                        autoSave()
                    }
            }
            .navigationBarTitle("New Project", displayMode: .inline)
            .alert(isPresented: $showAlert) {
                Alert(title: Text("Incomplete Fields"), message: Text("Please fill in all fields."), dismissButton: .default(Text("OK")))
            }
            .gesture(
                DragGesture()
                    .onChanged { dragAmount = $0.translation }
                    .onEnded { _ in
                        if dragAmount.height > 50 {
                            presentationMode.wrappedValue.dismiss()
                        } else if dragAmount.height < -50 {
                            if project.name.isEmpty || project.developer.isEmpty || project.customer.isEmpty || selectedLanguages.isEmpty || project.projectType.isEmpty || project.paymentMethod.isEmpty || project.totalAmount <= 0 {
                                showAlert = true
                            } else {
                                project.languagesUsed = selectedLanguages.joined(separator: ", ")
                                autoSave()
                                presentationMode.wrappedValue.dismiss()
                            }
                        }
                        dragAmount = .zero
                    }
            )
        }
    }

    private func autoSave() {
        if project.name.isEmpty || project.developer.isEmpty || project.customer.isEmpty || selectedLanguages.isEmpty || project.projectType.isEmpty || project.paymentMethod.isEmpty || project.totalAmount <= 0 {
            return
        }
        
        project.languagesUsed = selectedLanguages.joined(separator: ", ")
        
        if let index = projects.firstIndex(where: { $0.id == project.id }) {
            projects[index] = project
        } else {
            projects.append(project)
        }

        if let data = try? JSONEncoder().encode(projects) {
            UserDefaults.standard.set(data, forKey: "projects")
        }
    }
    
    private func customNumberFormatter() -> NumberFormatter {
        let formatter = NumberFormatter()
        formatter.numberStyle = .none
        return formatter
    }
}

extension View {
    func placeholder<Content: View>(when shouldShow: Bool, alignment: Alignment = .leading, @ViewBuilder placeholder: () -> Content) -> some View {
        ZStack(alignment: alignment) {
            placeholder().opacity(shouldShow ? 1 : 0)
            self
        }
    }
}
