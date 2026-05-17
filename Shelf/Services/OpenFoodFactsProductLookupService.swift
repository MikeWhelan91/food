import Foundation

struct OpenFoodFactsProductLookupService: ProductLookupServicing {
    private let session: URLSession
    private let cache = ProductLookupMemoryCache()

    init(session: URLSession = .shared) {
        self.session = session
    }

    func lookup(barcode: String) async throws -> ProductLookupResult? {
        let cleanedBarcode = barcode.filter(\.isNumber)
        guard !cleanedBarcode.isEmpty else {
            throw ShelfServiceError.invalidInput
        }

        if let cached = await cache.result(for: cleanedBarcode) {
            return cached
        }

        var components = URLComponents()
        components.scheme = "https"
        components.host = "world.openfoodfacts.org"
        components.path = "/api/v2/product/\(cleanedBarcode).json"
        components.queryItems = [
            URLQueryItem(
                name: "fields",
                value: [
                    "code",
                    "status",
                    "product_name",
                    "product_name_en",
                    "generic_name",
                    "generic_name_en",
                    "brands",
                    "categories_tags",
                    "quantity",
                    "image_front_small_url",
                    "image_url"
                ].joined(separator: ",")
            )
        ]

        guard let url = components.url else {
            throw ShelfServiceError.invalidInput
        }

        var request = URLRequest(url: url, timeoutInterval: 8)
        request.httpMethod = "GET"
        request.setValue("Shelf/1.0 (iOS; contact: support@example.com)", forHTTPHeaderField: "User-Agent")
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        let (data, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw ShelfServiceError.unavailable
        }

        guard (200..<300).contains(httpResponse.statusCode) else {
            throw ShelfServiceError.unavailable
        }

        let decoded = try JSONDecoder().decode(OpenFoodFactsResponse.self, from: data)
        guard decoded.status == 1, let product = decoded.product else {
            return nil
        }

        let name = product.bestName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty else {
            return nil
        }

        let result = ProductLookupResult(
            barcode: cleanedBarcode,
            name: name,
            brand: product.normalizedBrand,
            category: Self.mapCategory(from: product.categoriesTags),
            imageSystemName: Self.symbol(for: product.categoriesTags),
            imageURL: product.bestImageURL,
            confidence: product.categoriesTags.isEmpty ? 0.78 : 0.92,
            source: "Open Food Facts"
        )

        await cache.store(result, for: cleanedBarcode)
        return result
    }

    private static func mapCategory(from tags: [String]) -> CategoryKind {
        let joinedTags = tags.joined(separator: " ")
        if joinedTags.contains("frozen") || joinedTags.contains("ice-creams") {
            return .freezer
        }
        if joinedTags.contains("dair") ||
            joinedTags.contains("yogurts") ||
            joinedTags.contains("cheeses") ||
            joinedTags.contains("meats") ||
            joinedTags.contains("fish") ||
            joinedTags.contains("prepared-meals") ||
            joinedTags.contains("fresh-foods") {
            return .fridge
        }
        if joinedTags.contains("pet-food") {
            return .pet
        }
        return .pantry
    }

    private static func symbol(for tags: [String]) -> String {
        let joinedTags = tags.joined(separator: " ")
        if joinedTags.contains("beverages") || joinedTags.contains("drinks") {
            return "bottle"
        }
        if joinedTags.contains("dair") || joinedTags.contains("milk") {
            return "carton"
        }
        if joinedTags.contains("eggs") {
            return "oval.grid.3x3"
        }
        if joinedTags.contains("fruits") || joinedTags.contains("vegetables") {
            return "leaf"
        }
        if joinedTags.contains("cheeses") {
            return "cube"
        }
        return "takeoutbag.and.cup.and.straw"
    }
}

private actor ProductLookupMemoryCache {
    private var storage: [String: ProductLookupResult] = [:]

    func result(for barcode: String) -> ProductLookupResult? {
        storage[barcode]
    }

    func store(_ result: ProductLookupResult, for barcode: String) {
        storage[barcode] = result
    }
}

private struct OpenFoodFactsResponse: Decodable {
    let status: Int
    let product: OpenFoodFactsProduct?
}

private struct OpenFoodFactsProduct: Decodable {
    let productName: String?
    let productNameEnglish: String?
    let genericName: String?
    let genericNameEnglish: String?
    let brands: String?
    let categoriesTags: [String]
    let quantity: String?
    let imageFrontSmallURL: URL?
    let imageURL: URL?

    enum CodingKeys: String, CodingKey {
        case productName = "product_name"
        case productNameEnglish = "product_name_en"
        case genericName = "generic_name"
        case genericNameEnglish = "generic_name_en"
        case brands
        case categoriesTags = "categories_tags"
        case quantity
        case imageFrontSmallURL = "image_front_small_url"
        case imageURL = "image_url"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        productName = try container.decodeIfPresent(String.self, forKey: .productName)
        productNameEnglish = try container.decodeIfPresent(String.self, forKey: .productNameEnglish)
        genericName = try container.decodeIfPresent(String.self, forKey: .genericName)
        genericNameEnglish = try container.decodeIfPresent(String.self, forKey: .genericNameEnglish)
        brands = try container.decodeIfPresent(String.self, forKey: .brands)
        categoriesTags = try container.decodeIfPresent([String].self, forKey: .categoriesTags) ?? []
        quantity = try container.decodeIfPresent(String.self, forKey: .quantity)
        imageFrontSmallURL = try container.decodeIfPresent(URL.self, forKey: .imageFrontSmallURL)
        imageURL = try container.decodeIfPresent(URL.self, forKey: .imageURL)
    }

    var bestName: String {
        productNameEnglish.nonEmpty ?? productName.nonEmpty ?? genericNameEnglish.nonEmpty ?? genericName.nonEmpty ?? ""
    }

    var normalizedBrand: String {
        brands?
            .components(separatedBy: ",")
            .first?
            .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
    }

    var bestImageURL: URL? {
        imageFrontSmallURL ?? imageURL
    }
}

private extension Optional where Wrapped == String {
    var nonEmpty: String? {
        guard let value = self?.trimmingCharacters(in: .whitespacesAndNewlines), !value.isEmpty else {
            return nil
        }
        return value
    }
}
