import SwiftUI
import FirebaseAuth

struct SignInView: View {
    @EnvironmentObject var authVM: AuthViewModel

    @State private var email = ""
    @State private var password = ""
    @State private var showPassword = false
    @State private var isLoading = false
    @State private var errorMessage = ""
    @State private var showSignUp = false
    @State private var showResetSheet = false
    @State private var resetEmail = ""
    @State private var resetMessage = ""
    @State private var showingResetAlert = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Spacer()

                // Logo or Image
                Image("CampusHireLogo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 120, height: 120)
                    .padding()

                // Email & Password Fields
                VStack(spacing: 15) {
                    TextField("Email", text: $email)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .autocapitalization(.none)
                        .keyboardType(.emailAddress)

                    ZStack(alignment: .trailing) {
                        Group {
                            if showPassword {
                                TextField("Password", text: $password)
                            } else {
                                SecureField("Password", text: $password)
                            }
                        }
                        .textFieldStyle(RoundedBorderTextFieldStyle())

                        Button {
                            showPassword.toggle()
                        } label: {
                            Image(systemName: showPassword ? "eye.slash" : "eye")
                                .foregroundColor(.gray)
                        }
                        .padding(.trailing, 8)
                    }
                }

                // Error Message
                if !errorMessage.isEmpty {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .font(.subheadline)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }

                // Login Button
                Button {
                    login()
                } label: {
                    if isLoading {
                        ProgressView()
                            .frame(maxWidth: .infinity)
                            .padding()
                    } else {
                        Text("Login")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(8)
                    }
                }
                .disabled(isLoading)
                .padding(.top, 10)

                // Forgot Password
                Button("Forgot Password?") {
                    showResetSheet = true
                }
                .font(.subheadline)
                .foregroundColor(.blue)

                // Sign Up Navigation
                Button("Don't have an account? Sign Up") {
                    showSignUp = true
                }
                .font(.subheadline)

                Spacer()
            }
            .padding()
            .navigationTitle("Sign In")
            .navigationBarTitleDisplayMode(.inline)

            // Sign Up Sheet
            .fullScreenCover(isPresented: $showSignUp) {
                SignUpView()
                    .environmentObject(authVM)
            }

            // Password Reset Sheet
            .sheet(isPresented: $showResetSheet) {
                NavigationStack {
                    VStack(spacing: 20) {
                        Text("Reset Password")
                            .font(.title2)
                            .bold()
                            .padding(.top)

                        TextField("Enter your email", text: $resetEmail)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .autocapitalization(.none)
                            .keyboardType(.emailAddress)
                            .padding(.horizontal)

                        Button("Send Reset Link") {
                            sendPasswordReset()
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                        .padding(.horizontal)

                        Spacer()
                    }
                    .alert(resetMessage, isPresented: $showingResetAlert) {
                        Button("OK", role: .cancel) { }
                    }
                }
            }
        }
    }

    // MARK: – Login
    private func login() {
        errorMessage = ""
        guard !email.isEmpty, !password.isEmpty else {
            errorMessage = "Please enter both email and password."
            return
        }
        guard isValidEmail(email) else {
            errorMessage = "Please enter a valid email address."
            return
        }

        isLoading = true
        Auth.auth().signIn(withEmail: email, password: password) { _, error in
            isLoading = false
            if let error = error {
                errorMessage = mapFirebaseError(error)
            }
            // On success, AuthViewModel’s listener will switch view
        }
    }

    // MARK: – Password Reset
    private func sendPasswordReset() {
        resetMessage = ""
        guard !resetEmail.isEmpty else {
            resetMessage = "Enter your email to reset password."
            showingResetAlert = true
            return
        }
        Auth.auth().sendPasswordReset(withEmail: resetEmail) { error in
            if let error = error {
                resetMessage = "Failed: \(error.localizedDescription)"
            } else {
                resetMessage = "A reset link has been sent to your email."
            }
            showingResetAlert = true
            showResetSheet = false
        }
    }

    // MARK: – Validation Helpers
    private func isValidEmail(_ email: String) -> Bool {
        let regex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}"
        return NSPredicate(format:"SELF MATCHES %@", regex).evaluate(with: email)
    }

    private func mapFirebaseError(_ error: Error) -> String {
        let code = (error as NSError).code
        switch AuthErrorCode(rawValue: code) {
        case .wrongPassword:     return "Incorrect password. Please try again."
        case .invalidEmail:      return "Invalid email address."
        case .userNotFound:      return "No account found with this email."
        default:                 return error.localizedDescription
        }
    }
}
