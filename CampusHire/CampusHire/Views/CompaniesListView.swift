import SwiftUI
import FirebaseFirestore
import FirebaseAuth

struct CompaniesListView: View {
    @State private var jobs: [JobPosting] = []
    @State private var isLoading = true
    @State private var appliedCompanyNames: Set<String> = []
    @State private var searchQuery = ""

    var filteredJobs: [JobPosting] {
        guard !searchQuery.isEmpty else { return jobs }
        return jobs.filter { job in
            let company = job.company ?? ""
            let location = job.location
            return company.localizedCaseInsensitiveContains(searchQuery) ||
                   (location?.localizedCaseInsensitiveContains(searchQuery) ?? false)
        }
    }
    
    var body: some View {
        NavigationStack {
            VStack {
                if isLoading {
                    ProgressView()
                        .scaleEffect(1.5)
                        .padding()
                } else if filteredJobs.isEmpty {
                    VStack {
                        Image(systemName: "building.2")
                            .resizable()
                            .frame(width: 100, height: 100)
                            .foregroundColor(.gray)
                            .padding()
                        Text("No Companies Found")
                            .font(.headline)
                            .foregroundColor(.gray)
                    }
                    .padding()
                } else {
                    List(filteredJobs) { job in
                        NavigationLink(destination: CompanyDetailView(job: job)) {
                            HStack {
                                VStack(alignment: .leading, spacing: 5) {
                                    Text(job.company ?? "-")
                                        .font(.headline)
                                        .foregroundColor(.primary)
                                    Text(job.title)
                                        .font(.subheadline)
                                        .foregroundColor(.gray)
                                }
                                Spacer()
                                if appliedCompanyNames.contains(job.company ?? "") {
                                    Image(systemName: "checkmark.seal.fill")
                                        .foregroundColor(.green)
                                }
                            }
                            .padding(.vertical, 6)
                        }
                    }
                    .listStyle(.plain)
                }
            }
            .padding(.horizontal)
            .navigationTitle("Eligible Companies")
            .navigationBarTitleDisplayMode(.large)
        }
        .searchable(text: $searchQuery, prompt: "Search by company or location")
        .onAppear {
            fetchJobs()
            fetchAppliedCompanies()
        }
        .refreshable {
            fetchJobs()
            fetchAppliedCompanies()
        }
    }
    
    // MARK: - Fetch Jobs
    func fetchJobs() {
        Firestore.firestore().collection("jobs").getDocuments { snapshot, error in
            if let docs = snapshot?.documents {
                self.jobs = docs.compactMap { try? $0.data(as: JobPosting.self) }
            }
            self.isLoading = false
        }
    }
    
    // MARK: - Fetch Applied Companies
    func fetchAppliedCompanies() {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        Firestore.firestore()
            .collection("users").document(uid)
            .collection("applications").getDocuments { snapshot, _ in
                if let docs = snapshot?.documents {
                    self.appliedCompanyNames = Set(
                        docs.compactMap { $0.data()["companyName"] as? String }
                    )
                }
            }
    }
}
