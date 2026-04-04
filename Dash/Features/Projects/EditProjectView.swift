//
//  EditProjectView.swift
//  Dash
//

import SwiftUI
import Foundation

struct EditProjectView: View {

    @Binding var project: Project
    @Binding var lastEditedDate: Date?

    @Environment(\.presentationMode) var presentationMode

    @State private var name = ""
    @State private var developer = ""
    @State private var customer = ""
    @State private var startDate = Date()
    @State private var endDate = Date()
    @State private var selectedLanguages = [String]()
    @State private var projectType = ""
    @State private var githubRepo = ""
    @State private var totalAmount: String = ""
    @State private var paymentMethod: String = ""

    let projectTypes = [
        "Android App", "iOS App", "Cross Platform App", "Website",
        "Android App and Website", "iOS App and Website",
        "Cross Platform App and Website", "IOT", "Others"
    ]

    let languages = [
        "Java", "Kotlin", "C++", "Dart", "Rust", "Swift", "Objective-C", "SwiftUI",
        "React Native", "Flutter", "Xamarin", "Elixir", "PureScript", "HTML", "CSS",
        "Tailwind CSS", "JavaScript", "PHP", "Ruby", "Python", "TypeScript", "Go",
        "F#", "Clojure", "MySQL", "PostgreSQL", "Node.js", "ASP.NET", "Express.js",
        "Laravel", "Django", "Flask", "Spring", "Ruby on Rails"
    ]

    let paymentMethods = [
        "Credit Card", "Debit Card", "PayPal", "Bank Transfer", "UPI", "Other"
    ]

    var body: some View {

        ZStack {

            LinearGradient(
                colors: [
                    Color(red: 0.06, green: 0.06, blue: 0.09),
                    Color(red: 0.09, green: 0.08, blue: 0.13)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {

                editorHeader

                ScrollView {
                    VStack(spacing: 14) {

                        sectionHeader("Project Info", icon: "folder.fill")
                        darkField("Project Name", text: $name, icon: "pencil") { autoSave() }
                        darkField("Developer", text: $developer, icon: "hammer") { autoSave() }
                        darkField("Customer", text: $customer, icon: "person") { autoSave() }
                        darkField("GitHub Repository", text: $githubRepo, icon: "chevron.left.forwardslash.chevron.right") { autoSave() }

                        divider

                        sectionHeader("Timeline", icon: "calendar")
                        dateField("Start Date", selection: $startDate)
                        dateField("Expected End Date", selection: $endDate)

                        divider

                        sectionHeader("Tech Stack", icon: "cpu")
                        pickerField("Project Type", selection: $projectType, options: projectTypes, icon: "iphone")
                        languageField

                        divider

                        sectionHeader("Payment", icon: "banknote")
                        pickerField("Payment Method", selection: $paymentMethod, options: paymentMethods, icon: "creditcard")
                        amountField

                        divider

                        sectionHeader("Progress", icon: "chart.bar.fill")
                        progressField

                        // Last edited
                        if let lastEdited = lastEditedDate {
                            HStack {
                                Image(systemName: "clock")
                                    .font(.system(size: 10))
                                Text("Last edited \(formattedDate(lastEdited))")
                                    .font(.system(size: 11))
                            }
                            .foregroundColor(.white.opacity(0.25))
                            .padding(.top, 4)
                        }

                        Color.clear.frame(height: 20)
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 8)
                }
            }
        }

        .navigationBarHidden(true)

        .onAppear {
            name = project.name
            developer = project.developer
            customer = project.customer
            startDate = project.startDate
            endDate = project.endDate
            selectedLanguages = project.languagesUsed
                .components(separatedBy: ", ")
                .filter { !$0.isEmpty }
            projectType = project.projectType
            githubRepo = project.githubRepo
            totalAmount = project.totalAmount == 0 ? "" : "\(Int(project.totalAmount))"
            paymentMethod = project.paymentMethod
        }

        .onDisappear {
            autoSave()
        }
    }

    // MARK: - Editor Header

    var editorHeader: some View {

        ZStack {
            Rectangle()
                .fill(.ultraThinMaterial)
                .overlay(Rectangle().fill(Color.purple.opacity(0.06)))
                .ignoresSafeArea(edges: .top)

            HStack {

                Button {
                    autoSave()
                    presentationMode.wrappedValue.dismiss()
                } label: {
                    HStack(spacing: 5) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 16, weight: .semibold))
                        Text("Projects")
                            .font(.system(size: 15, weight: .medium))
                    }
                    .foregroundColor(.purple)
                }

                Spacer()

                VStack(spacing: 2) {
                    Text(name.isEmpty ? "Edit Project" : name)
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .lineLimit(1)

                    if let lastEdited = lastEditedDate {
                        Text("Saved \(formattedDate(lastEdited))")
                            .font(.system(size: 10))
                            .foregroundColor(.purple.opacity(0.6))
                    }
                }

                Spacer()

                Button {
                    autoSave()
                    let impact = UINotificationFeedbackGenerator()
                    impact.notificationOccurred(.success)
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 13))
                        Text("Saved")
                            .font(.system(size: 13, weight: .medium))
                    }
                    .foregroundColor(.purple.opacity(0.7))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(
                        Capsule()
                            .fill(Color.purple.opacity(0.1))
                            .overlay(Capsule().stroke(Color.purple.opacity(0.2), lineWidth: 1))
                    )
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
        }
        .frame(height: 60)
    }

    // MARK: - Section Header

    func sectionHeader(_ title: String, icon: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(.purple.opacity(0.8))
            Text(title.uppercased())
                .font(.system(size: 11, weight: .semibold, design: .monospaced))
                .foregroundColor(.white.opacity(0.35))
            Spacer()
        }
        .padding(.top, 6)
        .padding(.bottom, 2)
    }

    // MARK: - Dark Text Field

    func darkField(_ placeholder: String, text: Binding<String>, icon: String, onChange: @escaping () -> Void) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.purple.opacity(0.6))
                .frame(width: 20)

            TextField(placeholder, text: text)
                .font(.system(size: 15))
                .foregroundColor(.white)
                .tint(.purple)
                .onChange(of: text.wrappedValue) { _ in onChange() }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color.white.opacity(0.06))
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(Color.white.opacity(0.07), lineWidth: 1)
                )
        )
    }

    // MARK: - Date Field

    func dateField(_ label: String, selection: Binding<Date>) -> some View {
        HStack(spacing: 12) {
            Image(systemName: "calendar")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.purple.opacity(0.6))
                .frame(width: 20)

            DatePicker(label, selection: selection, displayedComponents: .date)
                .font(.system(size: 15))
                .foregroundColor(.white)
                .tint(.purple)
                .colorScheme(.dark)
                .onChange(of: selection.wrappedValue) { _ in autoSave() }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color.white.opacity(0.06))
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(Color.white.opacity(0.07), lineWidth: 1)
                )
        )
    }

    // MARK: - Picker Field

    func pickerField(_ label: String, selection: Binding<String>, options: [String], icon: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.purple.opacity(0.6))
                .frame(width: 20)

            Picker(label, selection: selection) {
                Text("Select...").tag("")
                ForEach(options, id: \.self) { Text($0).tag($0) }
            }
            .tint(.purple)
            .colorScheme(.dark)
            .onChange(of: selection.wrappedValue) { _ in autoSave() }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color.white.opacity(0.06))
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(Color.white.opacity(0.07), lineWidth: 1)
                )
        )
    }

    // MARK: - Language Multi-Picker

    var languageField: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 12) {
                Image(systemName: "terminal")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.purple.opacity(0.6))
                    .frame(width: 20)

                MultiSelectPicker(
                    selections: $selectedLanguages,
                    options: languages,
                    title: "Languages Used"
                )
                .colorScheme(.dark)
                .tint(.purple)
                .onChange(of: selectedLanguages) { _ in autoSave() }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color.white.opacity(0.06))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(Color.white.opacity(0.07), lineWidth: 1)
                    )
            )

            if !selectedLanguages.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 6) {
                        ForEach(selectedLanguages, id: \.self) { lang in
                            HStack(spacing: 4) {
                                Text(lang)
                                    .font(.system(size: 11, weight: .medium))
                                    .foregroundColor(.purple)
                                Button {
                                    selectedLanguages.removeAll { $0 == lang }
                                    autoSave()
                                } label: {
                                    Image(systemName: "xmark")
                                        .font(.system(size: 8, weight: .bold))
                                        .foregroundColor(.purple.opacity(0.6))
                                }
                            }
                            .padding(.horizontal, 9)
                            .padding(.vertical, 5)
                            .background(Capsule().fill(Color.purple.opacity(0.1)))
                            .overlay(Capsule().stroke(Color.purple.opacity(0.2), lineWidth: 1))
                        }
                    }
                    .padding(.horizontal, 4)
                }
            }
        }
    }

    // MARK: - Amount Field

    var amountField: some View {
        HStack(spacing: 12) {
            Image(systemName: "dollarsign.circle")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.purple.opacity(0.6))
                .frame(width: 20)

            TextField("Total Amount", text: $totalAmount)
                .font(.system(size: 15))
                .foregroundColor(.white)
                .tint(.purple)
                .keyboardType(.decimalPad)
                .onChange(of: totalAmount) { val in
                    if let v = Double(val) {
                        project.totalAmount = v
                    }
                    autoSave()
                }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color.white.opacity(0.06))
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(Color.white.opacity(0.07), lineWidth: 1)
                )
        )
    }

    // MARK: - Progress Field

    var progressField: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Completion")
                    .font(.system(size: 14))
                    .foregroundColor(.white.opacity(0.5))
                Spacer()
                Text("\(Int(project.progress * 100))%")
                    .font(.system(size: 15, weight: .bold, design: .monospaced))
                    .foregroundColor(.purple)
            }

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color.white.opacity(0.07))
                        .frame(height: 8)

                    RoundedRectangle(cornerRadius: 6)
                        .fill(
                            LinearGradient(
                                colors: [Color.purple, Color.purple.opacity(0.6)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geo.size.width * CGFloat(project.progress), height: 8)
                }
            }
            .frame(height: 8)

            Slider(value: $project.progress, in: 0...1, step: 0.01)
                .tint(.purple)
                .colorScheme(.dark)
                .onChange(of: project.progress) { _ in autoSave() }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color.white.opacity(0.06))
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(Color.white.opacity(0.07), lineWidth: 1)
                )
        )
    }

    // MARK: - Divider

    var divider: some View {
        Rectangle()
            .fill(Color.white.opacity(0.05))
            .frame(height: 1)
            .padding(.vertical, 4)
    }

    // MARK: - Auto Save

    private func autoSave() {
        project.name = name
        project.developer = developer
        project.customer = customer
        project.startDate = startDate
        project.endDate = endDate
        project.languagesUsed = selectedLanguages.joined(separator: ", ")
        project.projectType = projectType
        project.githubRepo = githubRepo
        project.paymentMethod = paymentMethod
        lastEditedDate = Date()
        saveProjectToStorage()
    }

    private func saveProjectToStorage() {
        if var projects = loadProjectsFromStorage() {
            if let index = projects.firstIndex(where: { $0.id == project.id }) {
                projects[index] = project
            }
            if let data = try? JSONEncoder().encode(projects) {
                UserDefaults.standard.set(data, forKey: "projects")
            }
        }
    }

    private func loadProjectsFromStorage() -> [Project]? {
        if let data = UserDefaults.standard.data(forKey: "projects"),
           let projects = try? JSONDecoder().decode([Project].self, from: data) {
            return projects
        }
        return nil
    }

    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
}
