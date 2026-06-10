import Foundation

enum APIError: LocalizedError {
    case invalidURL
    case invalidResponse
    case transport(Error)
    case httpError(statusCode: Int, message: String?)
    case decodingFailed(Error)
    case emptyData

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid backend URL."
        case .invalidResponse:
            return "Invalid server response."
        case .transport(let error):
            if let urlError = error as? URLError {
                switch urlError.code {
                case .notConnectedToInternet:
                    return "No internet or local network connection."
                case .cannotConnectToHost, .networkConnectionLost, .timedOut:
                    return "Cannot connect to the QueueEase backend. Make sure the backend is running and the base URL is correct."
                default:
                    return urlError.localizedDescription
                }
            }
            return error.localizedDescription
        case .httpError(let statusCode, let message):
            return message ?? "Request failed with status code \(statusCode)."
        case .decodingFailed(let error):
            return "Failed to read server response: \(error.localizedDescription)"
        case .emptyData:
            return "Server response did not contain data."
        }
    }
}

final class APIService {
    static let shared = APIService()

    private init() {}

    func get<T: Decodable>(_ path: String) async throws -> T {
        let request = try makeRequest(path: path, method: "GET")
        return try await send(request)
    }

    func post<T: Decodable, Body: Encodable>(_ path: String, body: Body) async throws -> T {
        var request = try makeRequest(path: path, method: "POST")
        request.httpBody = try JSONEncoder().encode(body)
        return try await send(request)
    }

    func put<T: Decodable, Body: Encodable>(_ path: String, body: Body) async throws -> T {
        var request = try makeRequest(path: path, method: "PUT")
        request.httpBody = try JSONEncoder().encode(body)
        return try await send(request)
    }

    func delete<T: Decodable>(_ path: String) async throws -> T {
        let request = try makeRequest(path: path, method: "DELETE")
        return try await send(request)
    }

    private func makeRequest(path: String, method: String) throws -> URLRequest {
        guard let baseURL = URL(string: APIConfig.baseURL) else {
            throw APIError.invalidURL
        }

        let url = baseURL.appending(path: path)
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.timeoutInterval = 15
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        return request
    }

    private func send<T: Decodable>(_ request: URLRequest) async throws -> T {
        let data: Data
        let response: URLResponse

        do {
            (data, response) = try await URLSession.shared.data(for: request)
        } catch {
            throw APIError.transport(error)
        }

        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            let message = decodeErrorMessage(from: data)
            throw APIError.httpError(statusCode: httpResponse.statusCode, message: message)
        }

        guard !data.isEmpty else {
            throw APIError.emptyData
        }

        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase

        do {
            return try decoder.decode(T.self, from: data)
        } catch {
            throw APIError.decodingFailed(error)
        }
    }

    private func decodeErrorMessage(from data: Data) -> String? {
        guard !data.isEmpty else {
            return nil
        }

        if let apiError = try? JSONDecoder().decode(APIResponse<EmptyResponse>.self, from: data),
           let message = apiError.message {
            return message
        }

        if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
            if let message = json["message"] as? String {
                return message
            }

            if let error = json["error"] as? String {
                return error
            }
        }

        if let text = String(data: data, encoding: .utf8),
           !text.trimmingCharacters(in: .whitespacesAndNewlines).hasPrefix("{") {
            return text
        }

        return "The server returned an error. Please refresh and try again."
    }
}

private struct EmptyResponse: Decodable {}
