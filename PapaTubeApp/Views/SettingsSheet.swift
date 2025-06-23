import SwiftUI

struct SettingsSheet: View {
    @EnvironmentObject var app: AppModel
    @ObservedObject private var auth = AuthService.shared
    @State private var draftID: String = ""

    var body: some View {
        NavigationView {
            List {
                TextField("YouTube playlist URL or ID", text: $draftID, onCommit: {
                    app.playlistService.setPlaylistInput(draftID)
                    draftID = app.playlistService.playlistID
                    app.refreshPlaylist()
                    // Auto-close settings once videos arrive
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {      
                        if !app.playlist.isEmpty {
                            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                        }
                    }
                })
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled(true)
                .onChange(of: draftID) { newVal in
                    // Trigger automatically when user pastes (length jump) or clears
                    debounceApply(newVal)
                }
                Button(action: authButtonTapped) {
                    if auth.isSignedIn {
                        Label("Sign out of Google", systemImage: "person.crop.circle.badge.xmark")
                    } else {
                        Label("Authenticate with Google", systemImage: "person.crop.circle.badge.checkmark")
                    }
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
        }
        .onAppear {
            draftID = app.playlistService.playlistID
        }
    }

    private func authButtonTapped() {
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
        if auth.isSignedIn {
            auth.signOut()
        } else {
            auth.signIn()
        }
    }

    // MARK: - Debounce Helper
    @State private var pendingWork: DispatchWorkItem?
    private func debounceApply(_ text: String) {
        pendingWork?.cancel()
        let work = DispatchWorkItem { [text] in
            guard !text.isEmpty else { return }
            app.playlistService.setPlaylistInput(text)
            draftID = app.playlistService.playlistID
            app.refreshPlaylist()
        }
        pendingWork = work
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4, execute: work)
    }
} 