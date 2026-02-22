//
//  EditorView.swift
//  AIPhotoEditor
//
//  Created by Preeti Chauhan on 2/20/26.
//
import SwiftUI
import PhotosUI

struct EditorView: View {
    let image: UIImage

    @State private var editedImage: UIImage?
    @State private var isProcessing = false
    @State private var showAlert = false
    @State private var alertTitle = ""
    @State private var alertMessage = ""
    @State private var selectedFilter = 0
    @State private var faceRects: [CGRect] = []
    @State private var showFaceBoxes = false
    @State private var personMask: CVPixelBuffer?
    @State private var personCGImage: CGImage?
    @State private var showBGReplacement = false

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
                        if showFaceBoxes {
                            GeometryReader { geo in
                                ForEach(Array(faceRects.enumerated()), id: \.offset) { _, rect in
                                    let scaleX = geo.size.width / displayImage.size.width
                                    let scaleY = geo.size.height / displayImage.size.height
                                    let scale = min(scaleX, scaleY)
                                    let offsetX = (geo.size.width - displayImage.size.width * scale) / 2
                                    let offsetY = (geo.size.height - displayImage.size.height * scale) / 2

                                    Rectangle()
                                        .stroke(Color.yellow, lineWidth: 2)
                                        .frame(width: rect.width * scale, height: rect.height * scale)
                                        .position(
                                            x: rect.midX * scale + offsetX,
                                            y: rect.midY * scale + offsetY
                                        )
                                }
                            }
                        }
                    }
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
                            showFaceBoxes = false
                            faceRects = []
                        }
                        ToolButton(icon: "wand.and.stars", title: "Enhance") {
                            enhancePhoto()
                        }
                        ToolButton(icon: "face.smiling", title: "Faces") {
                            detectFaces()
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
        .alert(alertTitle, isPresented: $showAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(alertMessage)
        }
        .sheet(isPresented: $showBGReplacement) {
            if let cgImage = personCGImage, let mask = personMask {
                BGReplacementView(cgImage: cgImage, mask: mask) { result in
                    editedImage = result
                    showBGReplacement = false
                } onCancel: {
                    showBGReplacement = false
                }
            }
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
        BackgroundRemover.computeMask(from: image) { cgImage, mask in
            isProcessing = false
            guard let cgImage, let mask else {
                alertTitle = "No Person Detected"
                alertMessage = "Please use a photo with a clearly visible person."
                showAlert = true
                return
            }
            personCGImage = cgImage
            personMask = mask
            showBGReplacement = true
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
    
    private func enhancePhoto() {
        isProcessing = true
        DispatchQueue.global(qos: .userInitiated).async {
            let result = AutoEnhancer.enhance(image: image)
            DispatchQueue.main.async {
                isProcessing = false
                if let result {
                    editedImage = result
                }
            }
        }
    }
    
    private func detectFaces() {
        isProcessing = true
        showFaceBoxes = false
        FaceDetector.detectFaces(in: displayImage) { rects in
            isProcessing = false
            if rects.isEmpty {
                alertTitle = "No Faces Detected"
                alertMessage = "Please use a photo with a clearly visible face."
                showAlert = true
            } else {
                faceRects = rects
                showFaceBoxes = true
            }
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

// MARK: - Background Replacement Sheet

struct BGReplacementView: View {
    let cgImage: CGImage
    let mask: CVPixelBuffer
    let onApply: (UIImage) -> Void
    let onCancel: () -> Void

    private enum BGSelection: Equatable {
        case transparent
        case preset(Int)
        case custom
        case photo
    }

    @State private var bgSelection: BGSelection = .transparent
    @State private var customColor = Color.white
    @State private var bgPhoto: UIImage?
    @State private var bgPhotoItem: PhotosPickerItem?
    @State private var previewImage: UIImage?

    private let presetColors: [UIColor] = [
        .white, .black, .systemGray, .systemBlue, .systemGreen,
        .systemYellow, .systemRed, .systemPink, .systemPurple,
        .systemOrange, .cyan, .systemMint
    ]

    private var backgroundType: BackgroundType {
        switch bgSelection {
        case .transparent:        return .transparent
        case .preset(let i):      return .color(presetColors[i])
        case .custom:             return .color(UIColor(customColor))
        case .photo:
            if let bgPhoto { return .photo(bgPhoto) }
            return .transparent
        }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {

                // Live preview
                ZStack {
                    CheckerboardView()
                    if let previewImage {
                        Image(uiImage: previewImage)
                            .resizable()
                            .scaledToFit()
                    } else {
                        ProgressView().tint(.gray)
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(height: 300)
                .clipped()

                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {

                        // Color grid
                        Text("Background Color")
                            .font(.headline)

                        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 6), spacing: 12) {

                            // Transparent tile
                            Button { select(.transparent) } label: {
                                ZStack {
                                    CheckerboardView()
                                        .frame(width: 44, height: 44)
                                        .clipShape(RoundedRectangle(cornerRadius: 8))
                                    if bgSelection == .transparent {
                                        RoundedRectangle(cornerRadius: 8)
                                            .stroke(.blue, lineWidth: 3)
                                            .frame(width: 44, height: 44)
                                    }
                                }
                            }

                            // Preset color tiles
                            ForEach(Array(presetColors.enumerated()), id: \.offset) { index, color in
                                Button { select(.preset(index)) } label: {
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(Color(uiColor: color))
                                        .frame(width: 44, height: 44)
                                        .overlay {
                                            if bgSelection == .preset(index) {
                                                RoundedRectangle(cornerRadius: 8)
                                                    .stroke(.blue, lineWidth: 3)
                                            }
                                        }
                                }
                            }
                        }

                        // Custom color picker
                        ColorPicker("Custom Color", selection: $customColor, supportsOpacity: false)
                            .onChange(of: customColor) { _, _ in select(.custom) }

                        Divider()

                        // Photo background
                        Text("Background Photo")
                            .font(.headline)

                        PhotosPicker(selection: $bgPhotoItem, matching: .images) {
                            Label("Choose from Library", systemImage: "photo.on.rectangle")
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.blue.opacity(0.1))
                                .foregroundStyle(.blue)
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                        }
                        .onChange(of: bgPhotoItem) { _, newItem in
                            guard let newItem else { return }
                            Task {
                                if let data = try? await newItem.loadTransferable(type: Data.self),
                                   let uiImage = UIImage(data: data) {
                                    bgPhoto = uiImage
                                    if bgSelection == .photo {
                                        updatePreview()  // selection didn't change, call directly
                                    } else {
                                        select(.photo)   // triggers updatePreview via select()
                                    }
                                }
                            }
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Replace Background")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel", action: onCancel)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Apply") {
                        if let previewImage { onApply(previewImage) }
                    }
                    .disabled(previewImage == nil)
                }
            }
            .onAppear { updatePreview() }
        }
    }

    private func select(_ selection: BGSelection) {
        bgSelection = selection
        updatePreview()
    }

    private func updatePreview() {
        let bg = backgroundType
        let cgImg = cgImage
        let msk = mask
        DispatchQueue.global(qos: .userInitiated).async {
            let result = BackgroundRemover.applyBackground(bg, mask: msk, to: cgImg)
            DispatchQueue.main.async { previewImage = result }
        }
    }
}

// MARK: - Checkerboard (transparency indicator)

struct CheckerboardView: View {
    var body: some View {
        Canvas { context, size in
            let tileSize: CGFloat = 12
            let cols = Int(ceil(size.width / tileSize))
            let rows = Int(ceil(size.height / tileSize))
            for row in 0..<rows {
                for col in 0..<cols {
                    let isLight = (row + col) % 2 == 0
                    context.fill(
                        Path(CGRect(
                            x: CGFloat(col) * tileSize,
                            y: CGFloat(row) * tileSize,
                            width: tileSize,
                            height: tileSize
                        )),
                        with: .color(isLight ? Color(white: 0.85) : Color(white: 0.65))
                    )
                }
            }
        }
    }
}
