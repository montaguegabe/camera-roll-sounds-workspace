//
//  HomeView.swift
//  CameraRollSounds
//
//  Main home view with photo picker and audio playback
//

import OpenbaseShared
import PhotosUI
import SwiftUI

struct HomeView: View {
    @EnvironmentObject var authContext: AuthContext
    @EnvironmentObject var navigationManager: AuthNavigationManager

    @State private var selectedPhoto: PhotosPickerItem?
    @State private var selectedImage: UIImage?
    @State private var isProcessing = false
    @State private var lastResponse: JobStatusResponse?
    @State private var errorMessage: String?
    @State private var showSettings = false

    @StateObject private var audioPlayer = AudioPlayer()

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Photo selection section
                photoSection

                // Results section
                if isProcessing {
                    processingView
                } else if let response = lastResponse {
                    resultsView(response: response)
                }

                // Error display
                if let error = errorMessage {
                    errorView(message: error)
                }

                Spacer(minLength: 40)
            }
            .padding()
        }
        .navigationTitle("Camera Roll Sounds")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showSettings = true
                } label: {
                    Image(systemName: "gearshape")
                }
            }
        }
        .sheet(isPresented: $showSettings) {
            SettingsView()
        }
        .onChange(of: selectedPhoto) { _, newValue in
            Task {
                await loadAndProcessImage(from: newValue)
            }
        }
    }

    // MARK: - View Components

    private var photoSection: some View {
        VStack(spacing: 16) {
            if let image = selectedImage {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(maxHeight: 300)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .shadow(radius: 4)
            } else {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.gray.opacity(0.2))
                    .frame(height: 200)
                    .overlay {
                        VStack(spacing: 12) {
                            Image(systemName: "photo.on.rectangle")
                                .font(.system(size: 48))
                                .foregroundStyle(.secondary)
                            Text("Select a photo to generate sounds")
                                .foregroundStyle(.secondary)
                        }
                    }
            }

            PhotosPicker(
                selection: $selectedPhoto,
                matching: .images,
                photoLibrary: .shared()
            ) {
                Label(
                    selectedImage == nil ? "Select Photo" : "Choose Different Photo",
                    systemImage: "photo.badge.plus"
                )
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.accentColor)
                .foregroundStyle(.white)
                .clipShape(RoundedRectangle(cornerRadius: 10))
            }
            .disabled(isProcessing)
        }
    }

    private var processingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.5)

            Text("Generating ambient sounds...")
                .font(.headline)
                .foregroundStyle(.secondary)

            Text("This may take a moment")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .padding(.vertical, 32)
    }

    private func resultsView(response: JobStatusResponse) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            // Description
            if let description = response.description {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Scene Description")
                        .font(.headline)

                    Text(description)
                        .font(.body)
                        .foregroundStyle(.secondary)
                }
            }

            // Quality visualization
            if let quality = response.qualityVisualization {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Meditation Quality")
                        .font(.headline)

                    Text(quality.capitalized)
                        .font(.title2)
                        .fontWeight(.medium)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Color.accentColor.opacity(0.15))
                        .clipShape(Capsule())
                }
            }

            // Audio controls
            if let audioUrl = response.audioUrl {
                VStack(spacing: 12) {
                    Button {
                        if let url = URL(string: audioUrl) {
                            audioPlayer.play(url: url)
                        }
                    } label: {
                        Label(
                            audioPlayer.isPlaying ? "Playing..." : "Play Meditation",
                            systemImage: audioPlayer.isPlaying ? "speaker.wave.3.fill" : "play.fill"
                        )
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(audioPlayer.isPlaying ? Color.green : Color.accentColor)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                    }

                    if audioPlayer.isPlaying {
                        Button {
                            audioPlayer.stop()
                        } label: {
                            Label("Stop", systemImage: "stop.fill")
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.red)
                                .foregroundStyle(.white)
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                        }
                    }
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private func errorView(message: String) -> some View {
        HStack {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(.orange)

            Text(message)
                .font(.callout)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color.orange.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    // MARK: - Actions

    private func loadAndProcessImage(from item: PhotosPickerItem?) async {
        guard let item = item else { return }

        errorMessage = nil

        // Load the image
        do {
            guard let data = try await item.loadTransferable(type: Data.self),
                  let image = UIImage(data: data) else {
                errorMessage = "Could not load the selected image"
                return
            }

            selectedImage = image
            isProcessing = true
            lastResponse = nil

            // Process the image
            let response = try await APIClient.shared.processImage(image)
            lastResponse = response
        } catch {
            errorMessage = error.localizedDescription
        }

        isProcessing = false
    }
}

// MARK: - Flow Layout for Tags

struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = computeLayout(proposal: proposal, subviews: subviews)
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = computeLayout(proposal: proposal, subviews: subviews)

        for (index, position) in result.positions.enumerated() {
            subviews[index].place(at: CGPoint(x: bounds.minX + position.x, y: bounds.minY + position.y), proposal: .unspecified)
        }
    }

    private func computeLayout(proposal: ProposedViewSize, subviews: Subviews) -> (size: CGSize, positions: [CGPoint]) {
        var positions: [CGPoint] = []
        var currentX: CGFloat = 0
        var currentY: CGFloat = 0
        var lineHeight: CGFloat = 0
        var maxWidth: CGFloat = 0

        let containerWidth = proposal.width ?? .infinity

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)

            if currentX + size.width > containerWidth && currentX > 0 {
                currentX = 0
                currentY += lineHeight + spacing
                lineHeight = 0
            }

            positions.append(CGPoint(x: currentX, y: currentY))
            currentX += size.width + spacing
            lineHeight = max(lineHeight, size.height)
            maxWidth = max(maxWidth, currentX)
        }

        return (CGSize(width: maxWidth, height: currentY + lineHeight), positions)
    }
}

// MARK: - Settings View

struct SettingsView: View {
    @EnvironmentObject var authContext: AuthContext
    @EnvironmentObject var navigationManager: AuthNavigationManager
    @Environment(\.dismiss) private var dismiss

    @State private var showLogoutConfirm = false

    var userName: String {
        if let displayName = authContext.user?["display"].string, !displayName.isEmpty {
            return displayName
        }
        if let username = authContext.user?["username"].string, !username.isEmpty {
            return username
        }
        if let email = authContext.user?["email"].string {
            return email
        }
        return "User"
    }

    var body: some View {
        NavigationStack {
            List {
                // User info section
                Section {
                    HStack(spacing: 16) {
                        Image(systemName: "person.circle.fill")
                            .font(.system(size: 50))
                            .foregroundColor(.blue)

                        VStack(alignment: .leading, spacing: 4) {
                            Text(userName)
                                .font(.headline)

                            if let email = authContext.user?["email"].string {
                                Text(email)
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    .padding(.vertical, 8)
                }

                // Account settings
                Section("Account") {
                    NavigationLink {
                        ChangeEmailView()
                    } label: {
                        Label("Email Addresses", systemImage: "envelope")
                    }

                    NavigationLink {
                        ChangePasswordView()
                    } label: {
                        Label("Change Password", systemImage: "lock")
                    }
                }

                // Sign out
                Section {
                    Button(role: .destructive) {
                        showLogoutConfirm = true
                    } label: {
                        Label("Sign Out", systemImage: "rectangle.portrait.and.arrow.right")
                    }
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showLogoutConfirm) {
                LogoutView()
                    .presentationDetents([.medium])
            }
        }
    }
}

#Preview {
    NavigationStack {
        HomeView()
            .environmentObject(AuthContext.shared)
            .environmentObject(AuthNavigationManager(authContext: AuthContext.shared))
    }
}
