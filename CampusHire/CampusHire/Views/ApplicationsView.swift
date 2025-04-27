import SwiftUI
import FirebaseFirestore
import FirebaseAuth

struct ApplicationsView: View {
    @State private var applications: [Application] = []
    @State private var isLoading = true
    @State private var searchQuery = ""
    @State private var sortByUpcoming = true

    // filter & sort
    private var filtered: [Application] {
        let base = applications.filter {
            searchQuery.isEmpty ||
            $0.companyName.localizedCaseInsensitiveContains(searchQuery)
        }
        if sortByUpcoming {
            return base.sorted {
                (upcomingDate(for: $0) ?? .distantFuture) <
                (upcomingDate(for: $1) ?? .distantFuture)
            }
        } else {
            return base.sorted { $0.companyName < $1.companyName }
        }
    }

    var body: some View {
        NavigationStack {
            VStack {
                // MARK: Sort Control
                Picker("", selection: $sortByUpcoming) {
                    Text("Upcoming").tag(true)
                    Text("Company").tag(false)
                }
                .pickerStyle(.segmented)
                .padding([.horizontal, .top])

                if isLoading {
                    ProgressView()
                        .scaleEffect(1.5)
                        .padding()
                } else if filtered.isEmpty {
                    VStack {
                        Image(systemName: "tray")
                            .resizable()
                            .frame(width: 80, height: 80)
                            .foregroundColor(.gray)
                            .padding()
                        Text("No Applications")
                            .font(.headline)
                            .foregroundColor(.gray)
                    }
                    .padding()
                } else {
                    List(filtered) { app in
                        VStack(alignment: .leading, spacing: 8) {
                            // Company Name
                            Text(app.companyName)
                                .font(.headline)

                            // Applied Date
                            HStack {
                                Image(systemName: "calendar")
                                Text("Applied: \(app.appliedDate)")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }

                            // Next Upcoming Event + Progress Bar
                            if let ev = upcomingEvent(for: app) {
                                HStack {
                                    Image(systemName: ev.icon)
                                    Text("\(ev.label): \(ev.dateString)")
                                        .font(.subheadline)
                                        .foregroundColor(.primary)
                                }
                                ProgressView(value: ev.progress)
                                    .accentColor(.blue)
                            }
                        }
                        .padding(.vertical, 6)
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle("My Applications")
            .navigationBarTitleDisplayMode(.large)
            .searchable(text: $searchQuery, prompt: "Search by company")
            .onAppear { fetchApplications() }
            .refreshable { fetchApplications() }
        }
    }

    // MARK: Fetch
    private func fetchApplications() {
        isLoading = true
        guard let uid = Auth.auth().currentUser?.uid else {
            isLoading = false; return
        }
        Firestore.firestore()
            .collection("users").document(uid)
            .collection("applications")
            .getDocuments { snap, _ in
                self.applications = snap?.documents.compactMap {
                    try? $0.data(as: Application.self)
                } ?? []
                isLoading = false
            }
    }

    // MARK: Upcoming‐Event Helper
    private func upcomingEvent(for app: Application)
      -> (label: String, dateString: String, progress: Double, icon: String)? {
        let fmt = DateFormatter(); fmt.dateFormat = "MMM d, yyyy"
        guard let applied = fmt.date(from: app.appliedDate) else { return nil }
        let now = Date()
        var events: [(String, Date, String)] = []
        if let d = fmt.date(from: app.onlineTestDate), d > now {
            events.append(("Online Test", d, "pencil"))
        }
        if let d = fmt.date(from: app.interviewDate), d > now {
            events.append(("Interview", d, "person.2.fill"))
        }
        guard let next = events.min(by: { $0.1 < $1.1 }) else { return nil }
        let total = next.1.timeIntervalSince(applied)
        let elapsed = now.timeIntervalSince(applied)
        let p = min(max(elapsed/total, 0), 1)
        return (label: next.0, dateString: fmt.string(from: next.1), progress: p, icon: next.2)
    }

    private func upcomingDate(for app: Application) -> Date? {
        let fmt = DateFormatter(); fmt.dateFormat = "MMM d, yyyy"
        let now = Date()
        let ds = [app.onlineTestDate, app.interviewDate]
            .compactMap(fmt.date)
            .filter { $0 > now }
        return ds.min()
    }
}
