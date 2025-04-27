# CampusHire iOS

CampusHire is a SwiftUI-based iOS app that streamlines real-time campus placement and internship updates.  
Students can browse eligible companies, apply with one click, track application status, save favorite jobs, and manage their profile (including uploading a PDF résumé).

---

## 🚀 Table of Contents

- [Features Implemented](#features-implemented)
- [Planned Features (To Do)](#planned-features-to-do)
- [Getting Started](#getting-started)
- [Project Structure](#project-structure)
- [Tech Stack](#tech-stack)

---

##  Features Implemented

| Category | Feature |
|:--|:--|
| **Authentication** | Email/password sign-in, sign-up, password reset, persistent login via `AuthViewModel` |
| **Home (Companies)** | List all jobs from Firestore, search by company or location, pull-to-refresh, "applied" tick |
| **Detail View** | View company info, salary, location, description, important dates; share; open in Maps; save |
| **Applications** | "My Applications" page with large heading, searchable & sortable list, upcoming-event + progress bar |
| **Saved Jobs** | Separate tab for saved (bookmark) jobs, pull-to-refresh, preserves save order |
| **Profile** | Edit name/branch/CGPA/role/location/skills; upload/update/remove résumé (PDF) with progress bar; preview; sign out |
| **Navigation** | `MainTabView` with Home, Applications, Saved, Profile tabs; `NavigationStack` |
| **Models** | `JobPosting` & `Application` structs, Firestore coding using `@DocumentID` & `Codable` |
| **Persistence** | Firebase Auth, Firestore, Storage integration; secure rules for user data & résumé files |

---

## 🛠 Planned Features (To Do)

| Priority | Feature |
|:--|:--|
| **High** | Push notifications for new jobs & upcoming deadlines (FCM) |
| **High** | Intelligent job matching based on student profile (branch, CGPA, skills) |
| **Medium** | Interview scheduling & calendar integration with automated reminders |
| **Medium** | Preparation resources section (practice tests, interview guides) |
| **Low** | Feedback system (students submit feedback, admin dashboard) |
| **Low** | Dark mode & theming support |

---

## 🏁 Getting Started

### 1. Clone the repository

```bash
git clone https://github.com/YourUser/CampusHire.git
cd CampusHire
```
### 2. Open the project in Xcode
- Open CampusHire.xcodeproj (or CampusHire.xcworkspace if workspace was created).
- If prompted, Resolve Swift Packages by allowing Xcode to fetch Firebase dependencies automatically.

### 3. Set up Firebase

- Create a Firebase project at [Firebase Console](https://console.firebase.google.com/).
- Enable the following services:
  - **Authentication** (Email/Password)
  - **Firestore Database**
  - **Firebase Storage**
- Download the `GoogleService-Info.plist` file.
- Add the `GoogleService-Info.plist` file into your Xcode project    
- Set proper Firestore and Storage security rules according to your project needs.

### 4. Run the project

- Open the `CampusHire.xcworkspace` file in Xcode.
- Select a simulator or a connected device.
- Press **Run** (or ⌘ + R) to build and launch the app.

---

## Project Structure

```plaintext
CampusHire/
├── App/
│   └── CampusHireApp.swift
│
├── Views/
│   ├── SignInView.swift
│   ├── SignUpView.swift
│   ├── MainTabView.swift
│   ├── CompaniesListView.swift
│   ├── CompanyDetailView.swift
│   ├── ApplicationsView.swift
│   ├── SavedJobsView.swift
│   ├── EditProfileView.swift
│   ├── DocumentPicker.swift
│   └── PDFViewer.swift
│
├── Models/
│   ├── JobPosting.swift
│   └── Application.swift
│
├── Services/
│   └── AuthViewModel.swift
│
├── Resources/
│   ├── Assets.xcassets
│   └── GoogleService-Info.plist
│
├── Supporting Files/
│   └── Info.plist
│
├── Podfile (optional)
├── Podfile.lock (optional)
├── CampusHire.xcodeproj
└── CampusHire.xcworkspace (optional)

```

### Tech Stack
-Language: Swift 5, SwiftUI
-Backend: Firebase Authentication, Firestore, Storage
-File Uploads: PDFKit for résumé preview
-Architecture: Lightweight MVVM (ObservableObject based)
-Dependency Manager: Swift Package Manager (Xcode SPM)



