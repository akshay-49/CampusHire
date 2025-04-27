import SwiftUI
import FirebaseFirestore
import FirebaseAuth

struct SavedJobsView: View {
    @State private var savedJobs: [JobPosting] = []
    @State private var isLoading = true

    var body: some View {
        NavigationStack {
            Group {
                if isLoading {
                    ProgressView()
                        .scaleEffect(1.5)
                        .padding()
                } else if savedJobs.isEmpty {
                    VStack {
                        Image(systemName: "bookmark")
                            .resizable()
                            .frame(width: 80, height: 80)
                            .foregroundColor(.gray)
                            .padding()
                        Text("No Saved Jobs")
                            .font(.headline)
                            .foregroundColor(.gray)
                    }
                    .padding()
                } else {
                    List(savedJobs) { job in
                        NavigationLink(destination: CompanyDetailView(job: job)) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(job.company ?? "-")
                                    .font(.headline)
                                Text(job.title)
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                            }
                        }
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle("Saved Jobs")
            .navigationBarTitleDisplayMode(.large)
            .onAppear { fetchSavedJobs() }
            .refreshable { fetchSavedJobs() }
        }
    }

    private func fetchSavedJobs() {
        isLoading = true
        guard let uid = Auth.auth().currentUser?.uid else {
            isLoading = false; return
        }

        let db = Firestore.firestore()
        let userSaved = db.collection("users").document(uid).collection("savedJobs")

        // 1. load saved job IDs
        userSaved.getDocuments { snap, err in
            guard let docs = snap?.documents, err == nil else {
                print("Error loading saved IDs:", err?.localizedDescription ?? "")
                self.isLoading = false
                return
            }
            let ids = docs.map { $0.documentID }
            if ids.isEmpty {
                self.savedJobs = []
                self.isLoading = false
                return
            }
            // 2. fetch each job doc
            var temp: [JobPosting] = []
            let group = DispatchGroup()
            for id in ids {
                group.enter()
                db.collection("jobs").document(id).getDocument { jobDoc, jErr in
                    if let jobDoc = jobDoc,
                       let job = try? jobDoc.data(as: JobPosting.self) {
                        temp.append(job)
                    } else {
                        print("Missing or parse error for job \(id):", jErr?.localizedDescription ?? "")
                    }
                    group.leave()
                }
            }
            // 3. when done, preserve order
            group.notify(queue: .main) {
                self.savedJobs = ids.compactMap { id in
                    temp.first(where: { $0.id == id })
                }
                self.isLoading = false
            }
        }
    }
}
