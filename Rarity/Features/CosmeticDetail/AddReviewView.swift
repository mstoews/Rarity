import PhotosUI
import SwiftUI

struct AddReviewView: View {
    let cosmeticID: String
    let api: APIClient
    let onSaved: () async -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var rating = 3
    @State private var text = ""
    @State private var selectedItem: PhotosPickerItem?
    @State private var imageData: Data?
    @State private var isSubmitting = false
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            Form {
                Section("Your Rating") {
                    HStack {
                        StarPickerView(rating: $rating)
                        Spacer()
                    }
                }
                Section("Your Review (optional)") {
                    TextEditor(text: $text)
                        .frame(minHeight: 100)
                }
                Section("Photo (optional)") {
                    PhotosPicker(selection: $selectedItem, matching: .images) {
                        if let data = imageData, let uiImg = UIImage(data: data) {
                            Image(uiImage: uiImg)
                                .resizable().scaledToFill()
                                .frame(maxWidth: .infinity).frame(height: 160)
                                .clipped().cornerRadius(10)
                        } else {
                            Label("Choose Photo", systemImage: "photo.badge.plus")
                        }
                    }
                    .onChange(of: selectedItem) { newItem in
                        Task {
                            imageData = try? await newItem?.loadTransferable(type: Data.self)
                        }
                    }
                }
                if let err = errorMessage {
                    Section { Text(err).foregroundStyle(Theme.destructive).font(.footnote) }
                }
            }
            .navigationTitle("Write a Review")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Submit") { Task { await submit() } }
                        .disabled(isSubmitting)
                }
            }
            .disabled(isSubmitting)
            .overlay {
                if isSubmitting { ProgressView().frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(.black.opacity(0.15)) }
            }
        }
    }

    private func submit() async {
        isSubmitting = true; errorMessage = nil; defer { isSubmitting = false }
        var uploadedURL: String?
        if let data = imageData {
            do {
                let fname = "review-\(UUID().uuidString).jpg"
                let presigned = try await api.presignedURL(filename: fname)
                try await api.uploadImage(to: URL(string: presigned.uploadURL)!, data: data)
                uploadedURL = presigned.imageURL
            } catch { errorMessage = "Photo upload failed." }
        }
        do {
            _ = try await api.addReview(cosmeticID: cosmeticID, rating: rating,
                                         text: text.isEmpty ? nil : text, photoURL: uploadedURL)
            await onSaved()
            dismiss()
        } catch { errorMessage = (error as? APIError)?.errorDescription ?? error.localizedDescription }
    }
}
