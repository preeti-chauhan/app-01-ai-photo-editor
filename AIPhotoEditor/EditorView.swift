//
//  EditorView.swift
//  AIPhotoEditor
//
//  Created by Preeti Chauhan on 2/20/26.
//
import SwiftUI

struct EditorView: View {
    let image: UIImage

    @State private var editedImage: UIImage?
    @State private var isProcessing = false
    @State private var showAlert = false
    @State private var selectedFilter = 0

    var displayImage: UIImage {
        editedImage ?? image
    }

    var body: some View {
        VStack(spacing: 0) {
            // Photo Display
            Image(uiImage: displayImage)
                .resizable()
                .scaledToFit()
                .frame(maxWidth: .infinity)
                .frame(height: 380)
                .background(Color.gray.opacity(0.2))
                .overlay {
                    if isProcessing {
                        ZStack {
                            Color.black.opacity(0.5)
                            VStack(spacing: 12) {
                                ProgressView()
                                    .tint(.white)
                                    .scaleEffect(1.5)
                                Text("Processing...")
                                    .foregroundStyle(.white)
                                    .font(.headline)
                            }
                        }
                    }
                }

            // Filters Strip
            VStack(alignment: .leading, spacing: 8) {
                Text("Filters")
                    .foregroundStyle(.white)
                    .font(.headline)
                    .padding(.horizontal)
                    .padding(.top, 12)

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(Array(FilterManager.filters.enumerated()), id: \.offset) { index, filter in
                            FilterThumbnail(
                                image: image,
                                filter: filter,
                                isSelected: selectedFilter == index
                            ) {
                                selectedFilter = index
                                applyFilter(filter)
                            }
                        }
                    }
                    .padding(.horizontal)
                }
            }
            .background(Color(white: 0.1))

            // Tools Bar
            VStack(alignment: .leading, spacing: 8) {
                Text("Tools")
                    .foregroundStyle(.white)
                    .font(.headline)
                    .padding(.horizontal)
                    .padding(.top, 12)

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 20) {
                        ToolButton(icon: "person.and.background.dotted", title: "Remove BG") {
                            removeBackground()
                        }
                        ToolButton(icon: "arrow.uturn.backward", title: "Reset") {
                            editedImage = nil
                            selectedFilter = 0
                        }
                    }
                    .padding()
                }
            }
            .background(Color(white: 0.15))

            Spacer()
        }
        .background(Color.black)
        .navigationTitle("Edit Photo")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    sharePhoto()
                } label: {
                    Image(systemName: "square.and.arrow.up")
                        .foregroundStyle(.white)
                }
            }
        }
        .alert("No Person Detected", isPresented: $showAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Please use a photo with a clearly visible person.")
        }
    }

    private func applyFilter(_ filter: PhotoFilter) {
        DispatchQueue.global(qos: .userInitiated).async {
            let result = FilterManager.apply(filter: filter, to: image)
            DispatchQueue.main.async {
                editedImage = result
            }
        }
    }

    private func removeBackground() {
        isProcessing = true
        BackgroundRemover.removeBackground(from: image) { result in
            isProcessing = false
            if let result {
                editedImage = result
            } else {
                showAlert = true
            }
        }
    }

    private func sharePhoto() {
        let photoToShare = editedImage ?? image
        let activityController = UIActivityViewController(
            activityItems: [photoToShare],
            applicationActivities: nil
        )

        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first,
           let rootVC = window.rootViewController {
            rootVC.present(activityController, animated: true)
        }
    }
}

struct FilterThumbnail: View {
    let image: UIImage
    let filter: PhotoFilter
    let isSelected: Bool
    let action: () -> Void

    @State private var thumbnail: UIImage?

    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Group {
                    if let thumbnail {
                        Image(uiImage: thumbnail)
                            .resizable()
                            .scaledToFill()
                    } else {
                        Color.gray
                    }
                }
                .frame(width: 70, height: 70)
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .overlay {
                    if isSelected {
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(.purple, lineWidth: 3)
                    }
                }

                Text(filter.name)
                    .font(.caption)
                    .foregroundStyle(isSelected ? .purple : .white)
            }
        }
        .onAppear {
            generateThumbnail()
        }
    }

    private func generateThumbnail() {
        DispatchQueue.global(qos: .background).async {
            let thumbnailSize = CGSize(width: 100, height: 100)
            let renderer = UIGraphicsImageRenderer(size: thumbnailSize)
            let smallImage = renderer.image { _ in
                image.draw(in: CGRect(origin: .zero, size: thumbnailSize))
            }

            let result = FilterManager.apply(filter: filter, to: smallImage)
            DispatchQueue.main.async {
                thumbnail = result
            }
        }
    }
}

struct ToolButton: View {
    let icon: String
    let title: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 24))
                Text(title)
                    .font(.caption)
            }
            .foregroundStyle(.white)
            .frame(width: 70)
        }
    }
}
