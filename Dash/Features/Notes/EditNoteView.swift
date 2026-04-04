//
//  EditNoteView.swift
//  Dash
//

import SwiftUI

struct EditNoteView: View {

    @Binding var note: Note
    @ObservedObject var viewModel: NotesViewModel

    @Environment(\.presentationMode) var presentationMode

    @State private var isImagePickerPresented = false
    @State private var selectedImage: IdentifiableImage? = nil
    @State private var tags: String = ""

    @State private var showingLinkInput = false
    @State private var linkText = ""

    @State private var showReminderPicker = false
    @State private var reminderDate = Date().addingTimeInterval(3600)
    @State private var isReminderSet = false

    @State private var showFormatMenu = false
    @State private var editorOffset: CGFloat = 0

    var wordCount: Int { note.content.split(separator: " ").count }
    var readingMinutes: Int { max(1, wordCount / 200) }

    var body: some View {

        ZStack {

            // Background
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
                    VStack(spacing: 0) {
                        titleSection
                        divider
                        contentSection
                        statsRow
                        divider
                        tagsSection
                        divider
                        imagesSection
                        if isReminderSet {
                            divider
                            reminderBadgeSection
                        }
                        Color.clear.frame(height: 100)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 8)
                }

                bottomToolbar
            }
        }

        .navigationBarHidden(true)

        .sheet(isPresented: $isImagePickerPresented) {
            ImagePicker(images: $note.images)
        }

        .sheet(isPresented: $showReminderPicker) {
            reminderSheet
        }

        .alert("Insert Link", isPresented: $showingLinkInput) {
            TextField("https://example.com", text: $linkText)
            Button("Add") {
                note.content += "\n🔗 \(linkText)\n"
                linkText = ""
                autoSave()
            }
            Button("Cancel", role: .cancel) {}
        }

        .fullScreenCover(item: $selectedImage) { image in
            ImageViewer(image: image.image)
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
                .overlay(
                    Rectangle()
                        .fill(Color.purple.opacity(0.06))
                )

            HStack {

                // Back button
                Button {
                    let impact = UIImpactFeedbackGenerator(style: .light)
                    impact.impactOccurred()
                    autoSave()
                    presentationMode.wrappedValue.dismiss()
                } label: {
                    HStack(spacing: 5) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 16, weight: .semibold))
                        Text("Notes")
                            .font(.system(size: 15, weight: .medium))
                    }
                    .foregroundColor(.purple)
                }

                Spacer()

                // Title
                VStack(spacing: 2) {
                    Text(note.title.isEmpty ? "New Note" : note.title)
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .lineLimit(1)

                    if isReminderSet {
                        HStack(spacing: 4) {
                            Image(systemName: "alarm.fill")
                                .font(.system(size: 9))
                            Text(reminderDate.formatted(date: .abbreviated, time: .shortened))
                                .font(.system(size: 10, weight: .medium))
                        }
                        .foregroundColor(.orange.opacity(0.8))
                    }
                }

                Spacer()

                // Save indicator / menu
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

    // MARK: - Title Section

    var titleSection: some View {

        VStack(alignment: .leading, spacing: 10) {

            // Date + Reminder row
            HStack(spacing: 12) {

                HStack(spacing: 5) {
                    Image(systemName: "calendar")
                        .font(.system(size: 10))
                    Text(note.createdAt.formatted(date: .abbreviated, time: .shortened))
                        .font(.system(size: 12))
                }
                .foregroundColor(.white.opacity(0.35))

                if isReminderSet {
                    HStack(spacing: 4) {
                        Image(systemName: "alarm.fill")
                            .font(.system(size: 10))
                        Text(reminderDate.formatted(date: .omitted, time: .shortened))
                            .font(.system(size: 12, weight: .medium))
                    }
                    .foregroundColor(.orange.opacity(0.8))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Capsule().fill(Color.orange.opacity(0.12)))
                }

                Spacer()
            }
            .padding(.top, 16)

            // Title field
            TextField("Idea...", text: $note.title, axis: .vertical)
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundColor(.white)
                .tint(.purple)
                .onChange(of: note.title) { _ in autoSave() }
        }
    }

    // MARK: - Content Section

    var contentSection: some View {

        VStack(alignment: .leading, spacing: 0) {

            ZStack(alignment: .topLeading) {

                if note.content.isEmpty {
                    Text("Write something...")
                        .font(.system(size: 16))
                        .foregroundColor(.white.opacity(0.2))
                        .padding(.top, 16)
                        .padding(.leading, 2)
                }

                TextEditor(text: $note.content)
                    .font(.system(size: 16))
                    .foregroundColor(.white.opacity(0.85))
                    .scrollContentBackground(.hidden)
                    .tint(.purple)
                    .frame(minHeight: 200)
                    .padding(.vertical, 10)
                    .onChange(of: note.content) { value in

                        // Bullet auto-continuation
                        if value.hasSuffix("\n• ") == false && value.last == "\n" {
                            let lines = value.split(separator: "\n")
                            if let last = lines.last, last.hasPrefix("• ") {
                                note.content += "• "
                            }
                        }
                        autoSave()
                    }
            }
        }
        .padding(.top, 12)
    }

    // MARK: - Stats Row

    var statsRow: some View {

        HStack(spacing: 14) {

            statChip(icon: "character.cursor.ibeam", label: "\(note.content.count) chars")
            statChip(icon: "text.word.spacing", label: "\(wordCount) words")
            statChip(icon: "book", label: "~\(readingMinutes) min")

            Spacer()
        }
        .padding(.vertical, 14)
    }

    func statChip(icon: String, label: String) -> some View {
        HStack(spacing: 5) {
            Image(systemName: icon)
                .font(.system(size: 10))
            Text(label)
                .font(.system(size: 12, weight: .medium))
        }
        .foregroundColor(.white.opacity(0.35))
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(
            Capsule()
                .fill(Color.white.opacity(0.05))
                .overlay(Capsule().stroke(Color.white.opacity(0.06), lineWidth: 1))
        )
    }

    // MARK: - Tags Section

    var tagsSection: some View {

        VStack(alignment: .leading, spacing: 10) {

            HStack(spacing: 6) {
                Image(systemName: "tag")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.purple.opacity(0.8))
                Text("Tags")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white.opacity(0.7))
            }
            .padding(.top, 16)

            HStack(spacing: 6) {
                Image(systemName: "number")
                    .font(.system(size: 13))
                    .foregroundColor(.white.opacity(0.25))

                TextField("#ideas  #work  #study", text: $tags)
                    .font(.system(size: 14))
                    .foregroundColor(.white.opacity(0.7))
                    .tint(.purple)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 11)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white.opacity(0.05))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.white.opacity(0.07), lineWidth: 1)
                    )
            )
            .padding(.bottom, 16)
        }
    }

    // MARK: - Images Section

    var imagesSection: some View {

        VStack(alignment: .leading, spacing: 12) {

            HStack(spacing: 6) {
                Image(systemName: "photo.on.rectangle.angled")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.purple.opacity(0.8))
                Text("Attachments")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white.opacity(0.7))

                Spacer()

                if !note.images.isEmpty {
                    Text("\(note.images.count) image\(note.images.count == 1 ? "" : "s")")
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.3))
                }
            }
            .padding(.top, 16)

            ScrollView(.horizontal, showsIndicators: false) {

                HStack(spacing: 12) {

                    // Add button
                    Button {
                        isImagePickerPresented = true
                        let impact = UIImpactFeedbackGenerator(style: .light)
                        impact.impactOccurred()
                    } label: {
                        VStack(spacing: 6) {
                            Image(systemName: "plus")
                                .font(.system(size: 20, weight: .light))
                                .foregroundColor(.purple.opacity(0.7))
                            Text("Add")
                                .font(.system(size: 11))
                                .foregroundColor(.white.opacity(0.35))
                        }
                        .frame(width: 100, height: 90)
                        .background(
                            RoundedRectangle(cornerRadius: 14)
                                .fill(Color.purple.opacity(0.06))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 14)
                                        .strokeBorder(
                                            style: StrokeStyle(lineWidth: 1.5, dash: [6]),
                                            antialiased: true
                                        )
                                        .foregroundColor(Color.purple.opacity(0.25))
                                )
                        )
                    }

                    // Image previews
                    ForEach(note.images) { img in

                        ZStack(alignment: .topTrailing) {

                            Image(uiImage: img.image)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 100, height: 90)
                                .clipped()
                                .cornerRadius(14)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 14)
                                        .stroke(Color.white.opacity(0.08), lineWidth: 1)
                                )
                                .onTapGesture {
                                    selectedImage = img
                                }

                            Button {
                                withAnimation(.spring(response: 0.3)) {
                                    note.images.removeAll { $0.id == img.id }
                                }
                                autoSave()
                                let impact = UIImpactFeedbackGenerator(style: .medium)
                                impact.impactOccurred()
                            } label: {
                                ZStack {
                                    Circle()
                                        .fill(Color.black.opacity(0.65))
                                        .frame(width: 22, height: 22)
                                    Image(systemName: "xmark")
                                        .font(.system(size: 9, weight: .bold))
                                        .foregroundColor(.white)
                                }
                            }
                            .padding(5)
                        }
                    }
                }
                .padding(.vertical, 4)
            }
            .padding(.bottom, 16)
        }
    }

    // MARK: - Reminder Badge Section

    var reminderBadgeSection: some View {

        HStack(spacing: 10) {

            Image(systemName: "alarm.fill")
                .font(.system(size: 13))
                .foregroundColor(.orange)

            VStack(alignment: .leading, spacing: 2) {
                Text("Reminder set")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.white.opacity(0.8))
                Text(reminderDate.formatted(date: .abbreviated, time: .shortened))
                    .font(.system(size: 12))
                    .foregroundColor(.orange.opacity(0.8))
            }

            Spacer()

            Button {
                isReminderSet = false
                autoSave()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(.white.opacity(0.4))
                    .padding(6)
                    .background(Circle().fill(Color.white.opacity(0.06)))
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color.orange.opacity(0.08))
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(Color.orange.opacity(0.15), lineWidth: 1)
                )
        )
        .padding(.top, 16)
        .padding(.bottom, 16)
    }

    // MARK: - Bottom Toolbar

    var bottomToolbar: some View {

        ZStack {

            Rectangle()
                .fill(.ultraThinMaterial)
                .overlay(
                    Rectangle().fill(Color.purple.opacity(0.04))
                )
                .ignoresSafeArea(edges: .bottom)

            HStack(spacing: 0) {

                toolbarButton(icon: "list.bullet") {
                    note.content += "\n• "
                }

                toolbarButton(icon: "checklist") {
                    note.content += "\n☑ "
                }

                toolbarButton(icon: "link") {
                    showingLinkInput = true
                }

                toolbarButton(icon: "photo.badge.plus") {
                    isImagePickerPresented = true
                }

                toolbarButton(icon: "alarm") {
                    showReminderPicker = true
                }

                Spacer()

                // Character count mini
                Text("\(note.content.count)")
                    .font(.system(size: 11, weight: .medium, design: .monospaced))
                    .foregroundColor(.white.opacity(0.2))
                    .padding(.trailing, 20)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 10)
            .padding(.bottom, 4)
        }
        .frame(height: 60)
    }

    func toolbarButton(icon: String, action: @escaping () -> Void) -> some View {
        Button {
            let impact = UIImpactFeedbackGenerator(style: .light)
            impact.impactOccurred()
            action()
        } label: {
            Image(systemName: icon)
                .font(.system(size: 17, weight: .medium))
                .foregroundColor(.white.opacity(0.6))
                .frame(width: 44, height: 44)
                .contentShape(Rectangle())
        }
    }

    // MARK: - Reminder Sheet

    var reminderSheet: some View {

        ZStack {

            Color(red: 0.08, green: 0.08, blue: 0.11).ignoresSafeArea()

            VStack(spacing: 24) {

                // Handle
                Capsule()
                    .fill(Color.white.opacity(0.2))
                    .frame(width: 40, height: 4)
                    .padding(.top, 12)

                HStack {
                    Image(systemName: "alarm.fill")
                        .foregroundColor(.orange)
                        .font(.system(size: 18))
                    Text("Set Reminder")
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                }

                DatePicker(
                    "",
                    selection: $reminderDate,
                    in: Date()...,
                    displayedComponents: [.date, .hourAndMinute]
                )
                .datePickerStyle(.graphical)
                .tint(.purple)
                .colorScheme(.dark)
                .padding(.horizontal, 10)

                // Set Reminder button
                Button {
                    isReminderSet = true
                    autoSave()
                    showReminderPicker = false

                    let impact = UINotificationFeedbackGenerator()
                    impact.notificationOccurred(.success)
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "alarm.fill")
                            .font(.system(size: 15))
                        Text("Set Reminder")
                            .font(.system(size: 16, weight: .semibold))
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(
                                LinearGradient(
                                    colors: [.orange, .orange.opacity(0.7)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .shadow(color: .orange.opacity(0.3), radius: 10, x: 0, y: 4)
                    )
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 30)
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.hidden)
    }

    // MARK: - Divider

    var divider: some View {
        Rectangle()
            .fill(Color.white.opacity(0.06))
            .frame(height: 1)
    }

    // MARK: - Auto Save

    func autoSave() {
        viewModel.addOrUpdate(note: note)
    }
}
