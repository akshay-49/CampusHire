import Foundation
import FirebaseFirestore

struct Application: Identifiable, Codable {
    @DocumentID var id: String?
    var companyName: String
    var appliedDate: String
    var onlineTestDate: String
    var interviewDate: String
    var applicationDeadline: String
}
