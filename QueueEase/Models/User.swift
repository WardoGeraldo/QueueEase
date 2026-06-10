import Foundation

struct User: Codable, Identifiable {
    let userId: Int
    let name: String
    let username: String
    let role: String
    let isActive: Bool?

    var id: Int {
        userId
    }
}
