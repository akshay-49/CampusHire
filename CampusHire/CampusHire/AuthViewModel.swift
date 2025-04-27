import Foundation
import FirebaseAuth
import Combine

/// ObservableObject that publishes the Firebase Auth user.
final class AuthViewModel: ObservableObject {
  @Published var user: User?

  private var handle: AuthStateDidChangeListenerHandle?

  init() {
    // Start listening as soon as this is created
    handle = Auth.auth().addStateDidChangeListener { [weak self] _, user in
      self?.user = user
    }
  }

  deinit {
    if let handle = handle {
      Auth.auth().removeStateDidChangeListener(handle)
    }
  }

  /// sign out convenience
  func signOut() throws {
    try Auth.auth().signOut()
    // the listener will set `user = nil`
  }
}
