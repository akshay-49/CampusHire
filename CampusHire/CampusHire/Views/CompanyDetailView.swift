import SwiftUI
import FirebaseFirestore
import FirebaseAuth
import MapKit

struct CompanyDetailView: View {
    let job: JobPosting
    @State private var hasApplied = false
    @State private var showSuccess = false
    @State private var savedJobs: Set<String> = []
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Company header
                Text(job.company ?? "-")
                    .font(.largeTitle).bold()
                Text(job.title)
                    .font(.title2).foregroundColor(.secondary)
                
                // Location & Salary
                if let loc = job.location {
                    Label(loc, systemImage: "mappin.and.ellipse")
                        .font(.subheadline).foregroundColor(.gray)
                }
                if let sal = job.salary {
                    Label(sal, systemImage: "dollarsign.circle")
                        .font(.subheadline).foregroundColor(.gray)
                }
                
                Divider()
                
                // Important Dates
                Text("Important Dates").font(.title3).bold()
                if let test = job.onlineTestDate { dateRow(label: "Online Test", date: test, icon: "pencil.and.outline", color: .blue) }
                if let interview = job.interviewDate { dateRow(label: "Interview", date: interview, icon: "person.2.fill", color: .green) }
                if let deadline = job.applicationDeadline { dateRow(label: "Deadline", date: deadline, icon: "clock", color: .red) }
                
                Divider()
                
                // Description
                Text("Job Description").font(.title3).bold()
                Text(job.description ?? "-").font(.body).padding(.top, 5)
                
                Spacer()
                
                // Apply button
                if !hasApplied {
                    Button {
                        applyNow()
                    } label: {
                        Text("Apply Now")
                            .frame(maxWidth: .infinity).padding()
                            .background(Color.blue).foregroundColor(.white)
                            .cornerRadius(10)
                    }
                    .padding(.top, 30)
                } else {
                    Label("You have already applied!", systemImage: "checkmark.seal.fill")
                        .foregroundColor(.green).font(.headline)
                        .padding(.top, 30)
                }
            }
            .padding()
        }
        .navigationTitle("Job Details")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItemGroup(placement: .navigationBarTrailing) {
                // Share
                Button { shareJob() } label: {
                    Image(systemName: "square.and.arrow.up")
                }
                // Maps
                Button { openInMaps() } label: {
                    Image(systemName: "map")
                }
                // Save/Unsave
                Button { saveJob() } label: {
                    Image(systemName: savedJobs.contains(job.id ?? "") ? "bookmark.fill" : "bookmark")
                }
            }
        }
        .alert("Application Submitted", isPresented: $showSuccess) {
            Button("OK", role: .cancel) {}
        }
        .onAppear {
            checkIfAlreadyApplied()
            fetchSavedJobs()
        }
    }
    
    // MARK: - Helpers
    
    @ViewBuilder
    private func dateRow(label: String, date: String, icon: String, color: Color) -> some View {
        HStack {
            Image(systemName: icon).foregroundColor(color)
            Text("\(label): \(date)")
                .font(.subheadline)
                .foregroundColor(.primary)
        }
    }
    
    private func applyNow() {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        let data: [String:Any] = [
            "companyName": job.company ?? "-",
            "appliedDate": DateFormatter.localizedString(from: Date(), dateStyle: .medium, timeStyle: .none),
            "onlineTestDate": job.onlineTestDate ?? "",
            "interviewDate": job.interviewDate ?? "",
            "applicationDeadline": job.applicationDeadline ?? ""
        ]
        Firestore.firestore()
            .collection("users").document(uid)
            .collection("applications").addDocument(data: data) { err in
                if err == nil { hasApplied = true; showSuccess = true }
            }
    }
    
    private func checkIfAlreadyApplied() {
        guard let uid = Auth.auth().currentUser?.uid,
              let name = job.company else { return }
        Firestore.firestore()
            .collection("users").document(uid)
            .collection("applications")
            .whereField("companyName", isEqualTo: name)
            .getDocuments { snap, _ in
                if let docs = snap?.documents, !docs.isEmpty {
                    hasApplied = true
                }
            }
    }
    
    private func shareJob() {
        let shareText = """
        Company: \(job.company ?? "-")
        Role: \(job.title)
        Location: \(job.location ?? "-")
        Salary: \(job.salary ?? "-")
        Online Test: \(job.onlineTestDate ?? "-")
        Interview: \(job.interviewDate ?? "-")
        Deadline: \(job.applicationDeadline ?? "-")
        
        Description:
        \(job.description ?? "-")
        """
        let vc = UIActivityViewController(activityItems: [shareText], applicationActivities: nil)
        UIApplication.shared.windows.first?.rootViewController?
            .present(vc, animated: true)
    }
    
    private func openInMaps() {
        guard let place = job.location else { return }
        let req = MKLocalSearch.Request()
        req.naturalLanguageQuery = place
        MKLocalSearch(request: req).start { res, _ in
            if let item = res?.mapItems.first {
                item.openInMaps()
            }
        }
    }
    
    private func saveJob() {
        guard let uid = Auth.auth().currentUser?.uid,
              let jobId = job.id else { return }
        let ref = Firestore.firestore().collection("users").document(uid).collection("savedJobs")
        if savedJobs.contains(jobId) {
            ref.document(jobId).delete(); savedJobs.remove(jobId)
        } else {
            let info: [String:Any] = [
                "companyName": job.company ?? "-",
                "savedDate": Timestamp(date: Date())
            ]
            ref.document(jobId).setData(info)
            savedJobs.insert(jobId)
        }
    }
    
    private func fetchSavedJobs() {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        Firestore.firestore()
            .collection("users").document(uid)
            .collection("savedJobs")
            .getDocuments { snap, _ in
                if let docs = snap?.documents {
                    savedJobs = Set(docs.map { $0.documentID })
                }
            }
    }
}
