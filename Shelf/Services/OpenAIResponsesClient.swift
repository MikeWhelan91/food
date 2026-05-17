import Foundation

struct OpenAIResponsesClient: Sendable {
    private let configurationProvider: @Sendable () throws -> OpenAIConfiguration
    private let session: URLSession

    init(
        configurationProvider: @escaping @Sendable () throws -> OpenAIConfiguration = { try OpenAIConfiguration.local() },
        session: URLSession = .shared
    ) {
        self.configurationProvider = configurationProvider
        self.session = session
    }

    func generateJSON(prompt: String) async throws -> String {
        let configuration = try configurationProvider()
        var request = URLRequest(url: URL(string: "https://api.openai.com/v1/responses")!, timeoutInterval: 18)
        request.httpMethod = "POST"
        request.setValue("Bearer \(configuration.apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body = OpenAIResponsesRequest(
            model: configuration.model,
            input: [
                OpenAIInputMessage(
                    role: "system",
                    content: [
                        OpenAIInputContent(
                            type: "input_text",
                            text: "You extract household inventory data for Shelf. Return compact valid JSON only. Do not include prose."
                        )
                    ]
                ),
                OpenAIInputMessage(
                    role: "user",
                    content: [
                        OpenAIInputContent(type: "input_text", text: prompt)
                    ]
                )
            ],
            temperature: 0.1,
            maxOutputTokens: 900
        )
        request.httpBody = try JSONEncoder().encode(body)

        let (data, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw ShelfServiceError.unavailable
        }
        guard (200..<300).contains(httpResponse.statusCode) else {
            throw ShelfServiceError.unavailable
        }

        let decoded = try JSONDecoder().decode(OpenAIResponsesResponse.self, from: data)
        guard let text = decoded.outputText.nilIfEmpty else {
            throw ShelfServiceError.unavailable
        }
        return text
    }
}

private struct OpenAIResponsesRequest: Encodable {
    let model: String
    let input: [OpenAIInputMessage]
    let temperature: Double
    let maxOutputTokens: Int

    enum CodingKeys: String, CodingKey {
        case model
        case input
        case temperature
        case maxOutputTokens = "max_output_tokens"
    }
}

private struct OpenAIInputMessage: Encodable {
    let role: String
    let content: [OpenAIInputContent]
}

private struct OpenAIInputContent: Encodable {
    let type: String
    let text: String
}

private struct OpenAIResponsesResponse: Decodable {
    let output: [OpenAIOutputItem]

    var outputText: String {
        output
            .flatMap(\.content)
            .compactMap(\.text)
            .joined(separator: "\n")
    }
}

private struct OpenAIOutputItem: Decodable {
    let content: [OpenAIOutputContent]

    enum CodingKeys: String, CodingKey {
        case content
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        content = try container.decodeIfPresent([OpenAIOutputContent].self, forKey: .content) ?? []
    }
}

private struct OpenAIOutputContent: Decodable {
    let text: String?
}

private extension String {
    var nilIfEmpty: String? {
        let trimmed = trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }
}
