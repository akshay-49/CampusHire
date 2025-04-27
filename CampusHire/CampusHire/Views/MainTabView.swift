import SwiftUI

struct MainTabView: View {
    var body: some View {
        TabView {
            CompaniesListView()
                .tabItem {
                    Image(systemName: "briefcase.fill")
                    Text("Home")
                }
            
            ApplicationsView()
                .tabItem {
                    Image(systemName: "doc.fill")
                    Text("Applications")
                }
            
            SavedJobsView()
                .tabItem {
                    Image(systemName: "bookmark.fill")
                    Text("Saved")
                }
            
            EditProfileView()
                .tabItem {
                    Image(systemName: "person.crop.circle.fill")
                    Text("Profile")
                }
        }
    }
}
