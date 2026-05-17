import Foundation

struct ShelfBackendAIClient: Sendable {
    private let configurationProvider: @Sendable () throws -> ShelfBackendConfiguration
    private let session: URLSession

    init(
        configurationProvider: @escaping @Sendable () throws -> ShelfBackendConfiguration = { try ShelfBackendConfiguration.local() },
        session: URLSession = .shared
    ) {
        self.configurationProvider = configurationProvider
        self.session = session
    }

    func post<Response: Decodable, Body: Encodable>(_ path: String, body: Body, responseType: Response.Type = Response.self) async throws -> Response {
        let configuration = try configurationProvider()
        let url = configuration.baseURL.appending(path: path)
        var request = URLRequest(url: url, timeoutInterval: 24)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.httpBody = try JSONEncoder().encode(body)

        let (data, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw ShelfServiceError.unavailable
        }
        guard (200..<300).contains(httpResponse.statusCode) else {
            throw ShelfServiceError.unavailable
        }
        return try JSONDecoder().decode(Response.self, from: data)
    }
}

private extension URL {
    func appending(path: String) -> URL {
        var url = self
        path.split(separator: "/").forEach { component in
            url.append(path: String(component))
        }
        return url
    }
}
