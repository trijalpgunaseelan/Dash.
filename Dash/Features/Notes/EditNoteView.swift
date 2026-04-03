
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
    @State private var showDeleteConfirmation = false
    @State private var imageToDelete: IdentifiableImage?
    @State private var tags: String = ""

    var body: some View {

        ZStack {

            Color.black
                .ignoresSafeArea()

            ScrollView {

                VStack(spacing: 24) {

                    Text(note.title.isEmpty ? "New Note" : note.title)
                        .font(.headline)
                        .frame(maxWidth: .infinity, alignment: .center)

                    dateSection
                    titleSection
                    contentSection
                    statsSection
                    tagsSection
                    imagesSection
                }
                .padding(24)
                .background(mainCard)
                .padding(.horizontal,16)
                .padding(.top,20)
            }
        }

        .navigationBarTitleDisplayMode(.inline)

        .sheet(isPresented: $isImagePickerPresented) {
            ImagePicker(images: $note.images)
        }

        .fullScreenCover(item: $selectedImage) { image in
            ImageViewer(image: image.image)
        }

        .alert(isPresented: $showDeleteConfirmation) {

            Alert(
                title: Text("Delete Image"),
                message: Text("Are you sure you want to delete this image?"),
                primaryButton: .destructive(Text("Delete")) {

                    if let imageToDelete {
                        deleteImage(image: imageToDelete)
                    }
                },
                secondaryButton: .cancel()
            )
        }

        .onAppear {
            loadTags()
        }

        .onDisappear {

            saveTags()
            autoSave()
            viewModel.deleteEmptyNotes()
        }
    }

    // MARK: DATE

    var dateSection: some View {

        HStack {

            Text(note.createdAt.formatted(date: .abbreviated, time: .shortened))
                .font(.caption)
                .foregroundColor(.secondary)

            Spacer()
        }
    }

    // MARK: TITLE

    var titleSection: some View {

        VStack(alignment: .leading, spacing: 8) {

            Text("Title")
                .foregroundColor(.secondary)

            TextField("Idea", text: $note.title)
                .padding(.horizontal,18)
                .padding(.vertical,14)
                .background(inputBackground)
                .cornerRadius(22)
                .onChange(of: note.title) { _ in autoSave() }
        }
    }

    // MARK: CONTENT

    var contentSection: some View {

        VStack(alignment: .leading, spacing: 8) {

            Text("Describe your idea")
                .foregroundColor(.secondary)

            ZStack(alignment: .topLeading) {

                RoundedRectangle(cornerRadius: 22)
                    .fill(Color(red:0.28,green:0.28,blue:0.30))

                if note.content.isEmpty {

                    Text("Write here...")
                        .foregroundColor(.gray)
                        .padding(.top,14)
                        .padding(.leading,14)
                }

                TextEditor(text: $note.content)
                    .scrollContentBackground(.hidden)
                    .padding(10)
                    .frame(minHeight:120)
                    .background(Color.clear)
                    .onChange(of: note.content) { _ in autoSave() }
            }
        }
    }

    // MARK: STATS

    var statsSection: some View {

        HStack {

            Text("\(note.content.count) characters")
                .font(.caption)
                .foregroundColor(.secondary)

            Spacer()

            Text("\(note.content.split(separator: " ").count) words")
                .font(.caption)
                .foregroundColor(.secondary)

            Spacer()

            Text("~\(max(1, note.content.count / 200)) min read")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }

    // MARK: TAGS

    var tagsSection: some View {

        VStack(alignment: .leading, spacing: 10) {

            Text("Tags")
                .foregroundColor(.secondary)

            TextField("#ideas #work #study", text: $tags)
                .padding(.horizontal,18)
                .padding(.vertical,14)
                .background(inputBackground)
                .cornerRadius(22)
        }
    }

    // MARK: IMAGES

    var imagesSection: some View {

        VStack(alignment: .leading, spacing: 10) {

            HStack {

                Text("Images")
                    .foregroundColor(.secondary)

                Spacer()

                Text("\(note.images.count)")
                    .foregroundColor(.secondary)
            }

            HStack {

                Button {

                    isImagePickerPresented = true

                } label: {

                    VStack {

                        Image(systemName:"plus")
                            .font(.title)

                        Text("Add")
                            .font(.caption)
                    }
                    .frame(width:120,height:100)
                    .background(
                        RoundedRectangle(cornerRadius:12)
                            .stroke(style:StrokeStyle(lineWidth:2,dash:[6]))
                            .foregroundColor(.purple)
                    )
                }

                Spacer()
            }
        }
    }

    // MARK: MAIN CARD

    var mainCard: some View {

        RoundedRectangle(cornerRadius: 28)
            .fill(
                LinearGradient(
                    colors: [
                        Color(red:0.18,green:0.18,blue:0.20),
                        Color(red:0.12,green:0.12,blue:0.14)
                    ],
                    startPoint:.topLeading,
                    endPoint:.bottomTrailing
                )
            )
            .shadow(color:.black.opacity(0.6),radius:12,x:0,y:6)
    }

    // MARK: INPUT BACKGROUND

    var inputBackground: some View {

        RoundedRectangle(cornerRadius:22)
            .fill(Color(red:0.28,green:0.28,blue:0.30))
    }

    // MARK: FUNCTIONS

    func deleteImage(image: IdentifiableImage) {

        if let index = note.images.firstIndex(where:{ $0.id == image.id }) {
            note.images.remove(at:index)
            autoSave()
        }
    }

    func autoSave() {
        viewModel.addOrUpdate(note: note)
    }

    func saveTags() {
        UserDefaults.standard.set(tags, forKey: "tags_\(note.id)")
    }

    func loadTags() {
        tags = UserDefaults.standard.string(forKey: "tags_\(note.id)") ?? ""
    }
}


