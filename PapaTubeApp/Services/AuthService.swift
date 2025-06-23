import Foundation
import GoogleSignIn
import UIKit

final class AuthService: ObservableObject {
    static let shared = AuthService()

    @Published private(set) var isSignedIn: Bool = false
    @Published var accessToken: String? = nil

    private init() {
        restorePreviousSignIn()
    }

    /// Attempts to silently restore a previous Google session so the user isn't surprised by a sign-in prompt.
    func restorePreviousSignIn() {
        GIDSignIn.sharedInstance.restorePreviousSignIn { [weak self] user, error in
            DispatchQueue.main.async {
                self?.isSignedIn = (user != nil)
                self?.accessToken = user?.accessToken.tokenString
            }
        }
    }

    /// Presents the Google sign-in flow from the top-most view controller.
    func signIn() {
        guard let rootVC = UIApplication.shared.connectedScenes
                .compactMap({ ($0 as? UIWindowScene)?.keyWindow })
                .first?.rootViewController else { return }

        let clientID = Bundle.main.object(forInfoDictionaryKey: "GOOGLE_CLIENT_ID") as? String ?? ""
        GIDSignIn.sharedInstance.configuration = GIDConfiguration(clientID: clientID)

        let ytScope = "https://www.googleapis.com/auth/youtube.readonly"

        // If we're already signed in but missing the YouTube scope, request it.
        if let currentUser = GIDSignIn.sharedInstance.currentUser,
           currentUser.grantedScopes?.contains(ytScope) == false {
            currentUser.addScopes([ytScope], presenting: rootVC) { [weak self] result, error in
                DispatchQueue.main.async {
                    if let token = result?.user.accessToken.tokenString {
                        self?.isSignedIn = true
                        self?.accessToken = token
                    }
                }
            }
            return
        }

        // Fresh sign-in
        GIDSignIn.sharedInstance.signIn(withPresenting: rootVC, hint: nil, additionalScopes: [ytScope]) { [weak self] result, error in
            DispatchQueue.main.async {
                if let token = result?.user.accessToken.tokenString {
                    self?.isSignedIn = true
                    self?.accessToken = token
                } else {
                    self?.isSignedIn = false
                    self?.accessToken = nil
                }
            }
        }
    }

    func signOut() {
        GIDSignIn.sharedInstance.signOut()
        isSignedIn = false
        accessToken = nil
    }
} 