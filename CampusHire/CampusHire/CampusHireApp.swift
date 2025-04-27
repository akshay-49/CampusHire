import SwiftUI
import FirebaseCore

@main
struct CampusHireApp: App {
  @StateObject private var authVM = AuthViewModel()

  init() {
    FirebaseApp.configure()
  }

  var body: some Scene {
    WindowGroup {
      // Automatically switches based on authVM.user
      Group {
        if authVM.user != nil {
          MainTabView()
        } else {
          SignInView()
        }
      }
      .environmentObject(authVM)
    }
  }
}
