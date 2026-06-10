import Foundation

struct APIResponse<T: Decodable>: Decodable {
    let success: Bool?
    let message: String?
    let data: T?
}

struct HealthResponse: Decodable {
    let status: String
    let database: String
}
