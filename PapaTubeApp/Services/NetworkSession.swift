import Foundation

// Lightweight abstraction over URLSession for testability.
protocol NetworkSession {
    func data(for request: URLRequest) async throws -> (Data, URLResponse)
}

extension URLSession: NetworkSession {} 