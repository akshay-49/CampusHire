import Foundation
import FirebaseFirestore

struct JobPosting: Identifiable, Codable {
    @DocumentID var id: String?
    var company: String?
    var title: String
    var location: String?
    var salary: String?
    var onlineTestDate: String?
    var interviewDate: String?
    var applicationDeadline: String?
    var description: String?
    var isUrgent: Bool?
    var postedDate: Date?
}
