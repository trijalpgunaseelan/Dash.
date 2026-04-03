//
//  EditNoteView.swift
//  Dash
//
//  Created by Trijal Gunaseelan on 11/23/24.
//  Edited by Dhakshka
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
    @State private var isFavorite = false

    // NOTE COLOR
    @State private var noteColor: Color = .purple

    var body: some View {

        ScrollView {

            VStack(spacing: 30) {

                titleSection

                contentSection

                statsSection

                tagsSection

                favoriteSection

                colorSection

                imagesSection
            }
            .padding()
        }

        .navigationBarTitleDisplayMode(.inline)

        .toolbar {

            ToolbarItem(placement: .principal) {

                Text(
                    note.title.isEmpty
                    ? "New Note"
                    : (note.title.count > 25
                       ? String(note.title.prefix(25)) + "…"
                       : note.title)
                )
                .font(.headline)
            }
        }

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

            loadFavorite()

            loadTags()

            if let color = Color(hex: note.colorHex) {
                noteColor = color
            }
        }

        .onDisappear {

            saveTags()

            note.colorHex = noteColor.toHex() ?? "#8E44AD"

            autoSave()

            viewModel.deleteEmptyNotes()
        }
    }

    // MARK: TITLE

    var titleSection: some View {

        VStack(alignment: .leading, spacing: 8) {

            Text("Title")
                .font(.headline)

            TextField("Idea", text: $note.title)
                .padding()
                .background(cardBackground)
                .onChange(of: note.title) { _ in autoSave() }
        }
    }

    // MARK: CONTENT

    var contentSection: some View {

        VStack(alignment: .leading, spacing: 8) {

            Text("Describe your idea")
                .font(.headline)

            ZStack(alignment: .topLeading) {

                if note.content.isEmpty {

                    Text("Write here...")
                        .foregroundColor(.gray)
                        .padding(.top, 10)
                        .padding(.leading, 8)
                }

                TextEditor(text: $note.content)
                    .frame(minHeight: 120)
                    .padding(6)
                    .onChange(of: note.content) { _ in autoSave() }
            }
            .background(cardBackground)
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
                .font(.headline)

            TextField("#ideas #work #study", text: $tags)
                .padding()
                .background(cardBackground)

            // TAG PREVIEW

            if !tags.isEmpty {

                ScrollView(.horizontal, showsIndicators: false) {

                    HStack {

                        ForEach(tags.split(separator: " "), id:\.self) { tag in

                            Text(tag)
                                .font(.caption)
                                .padding(.horizontal,10)
                                .padding(.vertical,5)
                                .background(Color.purple.opacity(0.2))
                                .cornerRadius(8)
                        }
                    }
                }
            }
        }
    }

    // MARK: FAVORITE

    var favoriteSection: some View {

        HStack {

            Text("Favorite Note")
                .font(.headline)

            Spacer()

            Button {

                isFavorite.toggle()

                saveFavorite()

            } label: {

                Image(systemName: isFavorite ? "star.fill" : "star")
                    .foregroundColor(.yellow)
                    .font(.title2)
            }
        }
    }

    // MARK: COLOR

    var colorSection: some View {

        VStack(alignment: .leading, spacing: 10) {

            Text("Note Color")
                .font(.headline)

            HStack {

                ColorPicker("Choose Color", selection: $noteColor)

                Spacer()

                Circle()
                    .fill(noteColor)
                    .frame(width: 26,height:26)
            }
            .padding()
            .background(cardBackground)
        }
    }

    // MARK: IMAGES

    var imagesSection: some View {

        VStack(alignment: .leading, spacing: 10) {

            HStack {

                Text("Images")
                    .font(.headline)

                Spacer()

                Text("\(note.images.count)")
                    .foregroundColor(.secondary)
            }

            ScrollView(.horizontal, showsIndicators: false) {

                HStack(spacing: 14) {

                    ForEach(note.images, id: \.id) { image in

                        Image(uiImage: image.image)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 140, height: 100)
                            .clipped()
                            .cornerRadius(12)
                            .onTapGesture {
                                selectedImage = image
                            }
                            .onLongPressGesture {
                                imageToDelete = image
                                showDeleteConfirmation = true
                            }
                    }

                    Button {

                        isImagePickerPresented = true

                    } label: {

                        VStack {

                            Image(systemName: "plus")
                                .font(.title)

                            Text("Add")
                                .font(.caption)
                        }
                        .frame(width: 120, height: 100)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(style: StrokeStyle(lineWidth: 2, dash: [6]))
                                .foregroundColor(.purple)
                        )
                    }
                }
            }
        }
    }

    // MARK: CARD

    var cardBackground: some View {

        RoundedRectangle(cornerRadius: 14)
            .fill(Color(UIColor.systemGray6))
    }

    // MARK: DELETE IMAGE

    func deleteImage(image: IdentifiableImage) {

        if let index = note.images.firstIndex(where: { $0.id == image.id }) {

            note.images.remove(at: index)

            autoSave()
        }
    }

    // MARK: SAVE NOTE

    func autoSave() {

        viewModel.addOrUpdate(note: note)
    }

    // MARK: FAVORITE STORAGE

    func saveFavorite() {

        UserDefaults.standard.set(isFavorite, forKey: "favorite_\(note.id)")
    }

    func loadFavorite() {

        isFavorite = UserDefaults.standard.bool(forKey: "favorite_\(note.id)")
    }

    // MARK: TAG STORAGE

    func saveTags() {

        UserDefaults.standard.set(tags, forKey: "tags_\(note.id)")
    }

    func loadTags() {

        tags = UserDefaults.standard.string(forKey: "tags_\(note.id)") ?? ""
    }
}
