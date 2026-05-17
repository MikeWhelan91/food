import Foundation

struct OpenAIConfiguration: Sendable {
    let apiKey: String
    let model: String

    static func local() throws -> OpenAIConfiguration {
        let environment = ProcessInfo.processInfo.environment
        if let apiKey = environment["OPENAI_API_KEY"], !apiKey.isEmpty {
            return OpenAIConfiguration(
                apiKey: apiKey,
                model: environment["OPENAI_MODEL"]?.nilIfEmpty ?? "gpt-4.1-mini"
            )
        }

        guard
            let url = Bundle.main.url(forResource: "OpenAISecrets", withExtension: "plist"),
            let data = try? Data(contentsOf: url),
            let plist = try? PropertyListSerialization.propertyList(from: data, format: nil) as? [String: String],
            let apiKey = plist["OPENAI_API_KEY"]?.nilIfEmpty
        else {
            throw ShelfServiceError.missingConfiguration
        }

        return OpenAIConfiguration(
            apiKey: apiKey,
            model: plist["OPENAI_MODEL"]?.nilIfEmpty ?? "gpt-4.1-mini"
        )
    }
}

private extension String {
    var nilIfEmpty: String? {
        let trimmed = trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }
}
