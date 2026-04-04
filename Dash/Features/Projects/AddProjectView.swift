//
//  AddProjectView.swift
//  Dash
//

import SwiftUI
import Foundation

struct AddProjectView: View {

    @Environment(\.presentationMode) var presentationMode
    @Binding var projects: [Project]

    @State private var project = Project(
        name: "", developer: "", customer: "",
        startDate: Date(), endDate: Date(),
        progress: 0, languagesUsed: "",
        projectType: "", githubRepo: "",
        paymentMethod: "", totalAmount: 0
    )

    @State private var selectedLanguages = [String]()
    @State private var showAlert = false
    @State private var totalAmountText = ""
    @State private var currentSection = 0

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

    var isValid: Bool {
        !project.name.isEmpty && !project.developer.isEmpty &&
        !project.customer.isEmpty && !selectedLanguages.isEmpty &&
        !project.projectType.isEmpty && !project.paymentMethod.isEmpty &&
        project.totalAmount > 0
    }

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

                sheetHeader

                ScrollView {
                    VStack(spacing: 14) {

                        sectionHeader("Project Info", icon: "folder.fill")
                        darkField("Project Name", text: $project.name, icon: "pencil")
                        darkField("Developer", text: $project.developer, icon: "hammer")
                        darkField("Customer", text: $project.customer, icon: "person")
                        darkField("GitHub Repository", text: $project.githubRepo, icon: "chevron.left.forwardslash.chevron.right")

                        divider

                        sectionHeader("Timeline", icon: "calendar")
                        dateField("Start Date", selection: $project.startDate)
                        dateField("Expected End Date", selection: $project.endDate)

                        divider

                        sectionHeader("Tech Stack", icon: "cpu")
                        pickerField("Project Type", selection: $project.projectType, options: projectTypes, icon: "iphone")
                        languageField

                        divider

                        sectionHeader("Payment", icon: "banknote")
                        pickerField("Payment Method", selection: $project.paymentMethod, options: paymentMethods, icon: "creditcard")
                        amountField

                        divider

                        sectionHeader("Progress", icon: "chart.bar.fill")
                        progressField

                        Color.clear.frame(height: 20)
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 8)
                }

                bottomBar
            }
        }

        .alert("Incomplete Fields", isPresented: $showAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Please fill in all required fields.")
        }
    }

    // MARK: - Sheet Header

    var sheetHeader: some View {

        ZStack {
            Rectangle()
                .fill(.ultraThinMaterial)
                .overlay(Rectangle().fill(Color.purple.opacity(0.06)))

            VStack(spacing: 0) {
                Capsule()
                    .fill(Color.white.opacity(0.2))
                    .frame(width: 40, height: 4)
                    .padding(.top, 10)
                    .padding(.bottom, 12)

                HStack {
                    Button {
                        presentationMode.wrappedValue.dismiss()
                    } label: {
                        Text("Cancel")
                            .font(.system(size: 15))
                            .foregroundColor(.white.opacity(0.5))
                    }

                    Spacer()

                    Text("New Project")
                        .font(.system(size: 17, weight: .bold, design: .rounded))
                        .foregroundColor(.white)

                    Spacer()

                    // Invisible balance
                    Text("Cancel")
                        .font(.system(size: 15))
                        .foregroundColor(.clear)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 14)
            }
        }
        .frame(height: 74)
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

    func darkField(_ placeholder: String, text: Binding<String>, icon: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.purple.opacity(0.6))
                .frame(width: 20)

            TextField(placeholder, text: text)
                .font(.system(size: 15))
                .foregroundColor(.white)
                .tint(.purple)
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

            // Selected chips
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

            TextField("Total Amount", text: $totalAmountText)
                .font(.system(size: 15))
                .foregroundColor(.white)
                .tint(.purple)
                .keyboardType(.decimalPad)
                .onChange(of: totalAmountText) { val in
                    if let v = Double(val) { project.totalAmount = v }
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
                Text("Initial Progress")
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

    // MARK: - Bottom Bar

    var bottomBar: some View {
        ZStack {
            Rectangle()
                .fill(.ultraThinMaterial)
                .overlay(Rectangle().fill(Color.purple.opacity(0.04)))
                .ignoresSafeArea(edges: .bottom)

            Button {
                if isValid {
                    project.languagesUsed = selectedLanguages.joined(separator: ", ")
                    if let index = projects.firstIndex(where: { $0.id == project.id }) {
                        projects[index] = project
                    } else {
                        projects.append(project)
                    }
                    if let data = try? JSONEncoder().encode(projects) {
                        UserDefaults.standard.set(data, forKey: "projects")
                    }
                    let impact = UINotificationFeedbackGenerator()
                    impact.notificationOccurred(.success)
                    presentationMode.wrappedValue.dismiss()
                } else {
                    showAlert = true
                    let impact = UINotificationFeedbackGenerator()
                    impact.notificationOccurred(.error)
                }
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 16))
                    Text("Create Project")
                        .font(.system(size: 16, weight: .semibold))
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(
                            isValid
                            ? LinearGradient(
                                colors: [Color.purple, Color(red: 0.5, green: 0.2, blue: 0.9)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                            : LinearGradient(
                                colors: [Color.white.opacity(0.08), Color.white.opacity(0.06)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .shadow(color: isValid ? Color.purple.opacity(0.35) : .clear, radius: 10, x: 0, y: 4)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(isValid ? Color.purple.opacity(0.3) : Color.white.opacity(0.06), lineWidth: 1)
                )
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 10)
        }
        .frame(height: 74)
    }
}
