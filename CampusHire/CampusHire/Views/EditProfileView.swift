import SwiftUI
import FirebaseAuth
import FirebaseFirestore
import FirebaseStorage
import UniformTypeIdentifiers
import PDFKit

struct EditProfileView: View {
    @State private var fullName = ""
    @State private var branch = ""
    @State private var cgpa = ""
    @State private var preferredRole = ""
    @State private var locationPreference = ""
    @State private var skills = ""
    @State private var resumeURL: String = ""
    
    @State private var isSaving = false
    @State private var isUploading = false
    @State private var uploadProgress: Double = 0.0
    @State private var uploadSuccess: Bool = false
    @State private var isLoggedOut = false
    @State private var showDocumentPicker = false
    @State private var selectedPDFURL: URL?
    @State private var showPDFViewer = false

    let branchOptions = ["Computer Science", "Electronics", "Mechanical", "Civil", "AI/ML"]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Group {
                        floatingTextField(label: "Full Name", text: $fullName)
                        
                        Text("Branch")
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        Picker("Select Branch", selection: $branch) {
                            ForEach(branchOptions, id: \.self) { branchName in
                                Text(branchName)
                            }
                        }
                        .pickerStyle(.menu)

                        floatingTextField(label: "CGPA", text: $cgpa, keyboardType: .decimalPad)
                        floatingTextField(label: "Preferred Role", text: $preferredRole)
                        floatingTextField(label: "Preferred Location", text: $locationPreference)
                        floatingTextField(label: "Skills (comma separated)", text: $skills)
                    }

                    Group {
                        if isUploading {
                            VStack {
                                Text("Uploading Resume...")
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                                ProgressView(value: uploadProgress)
                                    .progressViewStyle(LinearProgressViewStyle(tint: Color.blue))
                                    .frame(height: 6)
                                    .padding(.top, 5)
                            }
                            .padding(.vertical)
                        }
                        
                        Button(action: {
                            if !isUploading {
                                showDocumentPicker = true
                            }
                        }) {
                            Label(resumeURL.isEmpty ? "Upload Resume (PDF)" : "Update Resume", systemImage: "doc.badge.plus")
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(isUploading ? Color.gray : Color.green)
                                .foregroundColor(.white)
                                .cornerRadius(10)
                        }
                        .disabled(isUploading)
                        .padding(.top)

                        if !resumeURL.isEmpty {
                            Button(action: {
                                showPDFViewer = true
                            }) {
                                Label("View Uploaded Resume", systemImage: "doc.richtext")
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color.blue)
                                    .foregroundColor(.white)
                                    .cornerRadius(10)
                            }
                            .padding(.top)

                            Button(action: {
                                removeResume()
                            }) {
                                Label("Remove Resume", systemImage: "trash")
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color.red)
                                    .foregroundColor(.white)
                                    .cornerRadius(10)
                            }
                            .padding(.top)
                        }
                    }
                    
                    Button(action: {
                        saveProfile()
                    }) {
                        if isSaving {
                            ProgressView()
                        } else {
                            Text("Save Profile")
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.blue)
                                .foregroundColor(.white)
                                .cornerRadius(10)
                        }
                    }
                    .padding(.top)

                    Button(action: {
                        signOut()
                    }) {
                        Text("Sign Out")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.red)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                    .padding(.top, 10)
                }
                .padding()
            }
            .navigationTitle("Edit Profile")
            .alert(isPresented: $uploadSuccess) {
                Alert(title: Text("Resume Uploaded!"), message: Text("Your resume has been uploaded successfully."), dismissButton: .default(Text("OK")))
            }
            .fullScreenCover(isPresented: $isLoggedOut) {
                SignInView()
            }
            .sheet(isPresented: $showDocumentPicker) {
                DocumentPicker(selectedPDFURL: $selectedPDFURL)
            }
            .sheet(isPresented: $showPDFViewer) {
                if let url = URL(string: resumeURL) {
                    PDFViewer(url: url)
                }
            }
            .onChange(of: selectedPDFURL) { _ in
                uploadResume()
            }
            .onAppear {
                fetchProfile()
            }
        }
    }
    
    // MARK: - Functions

    func floatingTextField(label: String, text: Binding<String>, keyboardType: UIKeyboardType = .default) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(label)
                .font(.headline)
                .foregroundColor(.primary)
            TextField("", text: text)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .keyboardType(keyboardType)
        }
    }

    func saveProfile() {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        let db = Firestore.firestore()
        let profileUpdates: [String: Any] = [
            "fullName": fullName,
            "branch": branch,
            "cgpa": Double(cgpa) ?? 0.0,
            "preferredRole": preferredRole,
            "locationPreference": locationPreference,
            "skills": skills.components(separatedBy: ",").map { $0.trimmingCharacters(in: .whitespaces) },
            "resumeURL": resumeURL
        ]
        
        isSaving = true
        
        db.collection("users").document(uid).setData(profileUpdates, merge: true) { error in
            isSaving = false
            if let error = error {
                print("❌ Error saving profile: \(error.localizedDescription)")
            } else {
                print("✅ Profile saved successfully!")
            }
        }
    }

    func fetchProfile() {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        let db = Firestore.firestore()
        
        db.collection("users").document(uid).getDocument { document, error in
            if let data = document?.data() {
                fullName = data["fullName"] as? String ?? ""
                branch = data["branch"] as? String ?? ""
                cgpa = String(data["cgpa"] as? Double ?? 0.0)
                preferredRole = data["preferredRole"] as? String ?? ""
                locationPreference = data["locationPreference"] as? String ?? ""
                skills = (data["skills"] as? [String] ?? []).joined(separator: ", ")
                resumeURL = data["resumeURL"] as? String ?? ""
            }
        }
    }

    func uploadResume() {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        guard let fileURL = selectedPDFURL else { return }

        if fileURL.startAccessingSecurityScopedResource() {
            defer { fileURL.stopAccessingSecurityScopedResource() }
            
            let tmpDir = FileManager.default.temporaryDirectory
            let localURL = tmpDir.appendingPathComponent("\(uid)_resume.pdf")
            
            do {
                if FileManager.default.fileExists(atPath: localURL.path) {
                    try FileManager.default.removeItem(at: localURL)
                }
                try FileManager.default.copyItem(at: fileURL, to: localURL)
            } catch {
                print("❌ Error copying file: \(error.localizedDescription)")
                return
            }
            
            let storageRef = Storage.storage().reference().child("resumes/\(uid).pdf")
            isUploading = true
            uploadProgress = 0.0
            
            let uploadTask = storageRef.putFile(from: localURL, metadata: nil)
            
            uploadTask.observe(.progress) { snapshot in
                guard let progress = snapshot.progress else { return }
                uploadProgress = Double(progress.completedUnitCount) / Double(progress.totalUnitCount)
            }
            
            uploadTask.observe(.success) { _ in
                storageRef.downloadURL { url, error in
                    if let url = url {
                        resumeURL = url.absoluteString
                        saveProfile()
                        uploadSuccess = true
                    }
                    isUploading = false
                }
            }
            
            uploadTask.observe(.failure) { _ in
                print("❌ Upload failed")
                isUploading = false
            }
        }
    }

    func removeResume() {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        let storageRef = Storage.storage().reference().child("resumes/\(uid).pdf")
        
        storageRef.delete { error in
            if error == nil {
                Firestore.firestore().collection("users").document(uid).updateData(["resumeURL": FieldValue.delete()])
                resumeURL = ""
            }
        }
    }

    func signOut() {
        do {
            try Auth.auth().signOut()
            isLoggedOut = true
        } catch {
            print("❌ Sign out error: \(error.localizedDescription)")
        }
    }
}
