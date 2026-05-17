import Foundation

struct ShelfBackendConfiguration: Sendable {
    let baseURL: URL

    static func local() throws -> ShelfBackendConfiguration {
        let environment = ProcessInfo.processInfo.environment
        if let value = environment["SHELF_API_BASE_URL"], let url = URL(string: value), !value.isEmpty {
            return ShelfBackendConfiguration(baseURL: url)
        }

        guard
            let url = Bundle.main.url(forResource: "ShelfBackend", withExtension: "plist"),
            let data = try? Data(contentsOf: url),
            let plist = try? PropertyListSerialization.propertyList(from: data, format: nil) as? [String: String],
            let baseURLString = plist["SHELF_API_BASE_URL"]?.nilIfEmpty,
            let baseURL = URL(string: baseURLString)
        else {
            throw ShelfServiceError.missingConfiguration
        }

        return ShelfBackendConfiguration(baseURL: baseURL)
    }
}

private extension String {
    var nilIfEmpty: String? {
        let trimmed = trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }
}
