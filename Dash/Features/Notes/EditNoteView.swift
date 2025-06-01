    //
    //  EditNoteView.swift
    //  Dash
    //
    //  Created by Trijal Gunaseelan on 11/23/24.
    //

import SwiftUI

struct EditNoteView: View {
    @Binding var note: Note
    @ObservedObject var viewModel: NotesViewModel
    @Environment(\.presentationMode) var presentationMode
    @State private var isImagePickerPresented = false
    @State private var selectedImage: IdentifiableImage? = nil
    @State private var showDeleteConfirmation: Bool = false
    @State private var imageToDelete: IdentifiableImage?

    var body: some View {
        Form {
            Section(header: Text("Title")) {
                TextField("Idea", text: $note.title, onEditingChanged: { _ in
                    autoSave()
                })
            }

            Section(header: Text("Describe your idea")) {
                ZStack(alignment: .topLeading) {
                    if note.content.isEmpty {
                        Text("Write here...")
                            .foregroundColor(.gray)
                            .padding(.top, 8)
                            .padding(.leading, 5)
                    }

                    TextEditor(text: $note.content)
                        .frame(minHeight: 100)
                        .onChange(of: note.content) { _ in
                            autoSave()
                        }
                        .padding(.horizontal, -4)
                }
            }


            Section(header: Text("Images")) {
                ScrollView(.horizontal) {
                    HStack {
                        ForEach(note.images, id: \.id) { image in
                            Image(uiImage: image.image)
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(maxHeight: 200)
                                .cornerRadius(8)
                                .onTapGesture {
                                    selectedImage = image
                                }
                                .onLongPressGesture {
                                    imageToDelete = image
                                    showDeleteConfirmation = true
                                }
                        }
                    }
                }

                Button("Add Images") {
                    isImagePickerPresented = true
                }
                .sheet(isPresented: $isImagePickerPresented) {
                    ImagePicker(images: $note.images)
                }
            }
        }
        .fullScreenCover(item: $selectedImage) { image in
            ImageViewer(image: image.image)
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text(
                    note.title.isEmpty
                    ? "New Note"
                    : (note.title.count > 25 ? String(note.title.prefix(25)) + "…" : note.title)
                )
                .font(.headline)
                .lineLimit(1)
            }
        }
        .onDisappear {
            viewModel.deleteEmptyNotes()
        }
        .alert(isPresented: $showDeleteConfirmation) {
            Alert(
                title: Text("Delete Image"),
                message: Text("Are you sure you want to delete this image?"),
                primaryButton: .destructive(Text("Delete")) {
                    if let imageToDelete = imageToDelete {
                        deleteImage(image: imageToDelete)
                    }
                },
                secondaryButton: .cancel()
            )
        }
    }

    private func deleteImage(image: IdentifiableImage) {
        if let index = note.images.firstIndex(where: { $0.id == image.id }) {
            note.images.remove(at: index)
            imageToDelete = nil
            autoSave()
        }
    }

    private func autoSave() {
        viewModel.addOrUpdate(note: note)
    }
}
