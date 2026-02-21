//
//  ContentView.swift
//  AIPhotoEditor
//
//  Created by Preeti Chauhan on 2/20/26.
//

import SwiftUI
import PhotosUI

struct ContentView: View {
    @State private var selectedItem: PhotosPickerItem?
    @State private var selectedImage: UIImage?
    @State private var showEditor = false

    var body: some View {
        NavigationStack {
            ZStack {
                // Background gradient
                LinearGradient(
                    colors: [Color.black, Color(red: 0.1, green: 0.1, blue: 0.2)],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()

                VStack(spacing: 40) {
                    // App Logo & Title
                    VStack(spacing: 12) {
                        Image(systemName: "wand.and.stars")
                            .font(.system(size: 70))
                            .foregroundStyle(.purple)

                        Text("AI Photo Editor")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundStyle(.white)

                        Text("Enhance your photos with AI")
                            .font(.subheadline)
                            .foregroundStyle(.gray)
                    }

                    // Import Button
                    PhotosPicker(selection: $selectedItem, matching: .images) {
                        Label("Import Photo", systemImage: "photo.on.rectangle.angled")
                            .font(.headline)
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(.purple)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                            .padding(.horizontal, 40)
                    }
                }
            }
            .navigationBarHidden(true)
            .onChange(of: selectedItem) { _, newItem in
                Task {
                    if let data = try? await newItem?.loadTransferable(type: Data.self),
                       let image = UIImage(data: data) {
                        selectedImage = image
                        showEditor = true
                    }
                }
            }
            .navigationDestination(isPresented: $showEditor) {
                if let image = selectedImage {
                    EditorView(image: image)
                }
            }
        }
    }
}

#Preview {
    ContentView()
}
