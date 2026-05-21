import Foundation

// MARK: - APIClient Protocol
protocol APIClientProtocol {

    func request<T: Codable>(
        _ endpoint: APIEndpoint,
        type: T.Type
    ) async throws -> T

    func requestWithCompletion<T: Codable>(
        _ endpoint: APIEndpoint,
        type: T.Type,
        completion: @escaping (Result<T, AppError>) -> Void
    )
}

// MARK: - APIClient
final class APIClient: APIClientProtocol {

    // MARK: Singleton
    static let shared = APIClient()

    // MARK: Properties
    private let session: URLSession
    private let decoder: JSONDecoder
    private let cacheManager: CacheManager

    // MARK: Init
    private init() {

        let config = URLSessionConfiguration.default

        config.timeoutIntervalForRequest = APIConstants.Timeout.request
        config.timeoutIntervalForResource = APIConstants.Timeout.resource
        config.requestCachePolicy = .reloadIgnoringLocalCacheData

        self.session = URLSession(configuration: config)
        self.decoder = JSONDecoder()
        self.cacheManager = CacheManager.shared
    }

    // MARK: - Async/Await Request
    func request<T: Codable>(
        _ endpoint: APIEndpoint,
        type: T.Type
    ) async throws -> T {

        // 1️⃣ Cache First
        if let cached: T = cacheManager.fetch(
            forKey: endpoint.cacheKey,
            type: T.self
        ) {
            return cached
        }

        // 2️⃣ Internet Check
        guard NetworkMonitor.shared.isConnected else {
            throw AppError.noInternet
        }

        // 3️⃣ URL Validation
        guard let url = endpoint.url else {
            throw AppError.invalidURL
        }

        do {

            // 4️⃣ Network Request
            let (data, response) = try await session.data(from: url)

            // 5️⃣ Validate Response
            guard let httpResponse = response as? HTTPURLResponse else {
                throw AppError.invalidURL
            }

            guard (200...299).contains(httpResponse.statusCode) else {
                throw AppError.serverError(httpResponse.statusCode)
            }

            // 6️⃣ Decode Data
            let decoded = try decoder.decode(T.self, from: data)

            // 7️⃣ Save Cache
            cacheManager.save(
                decoded,
                forKey: endpoint.cacheKey
            )

            return decoded

        } catch let error as AppError {

            throw error

        } catch let decodingError as DecodingError {

            throw AppError.decodingFailed(
                decodingError.localizedDescription
            )

        } catch {

            throw AppError.networkError(
                error.localizedDescription
            )
        }
    }

    // MARK: - Completion Handler Version
    func requestWithCompletion<T: Codable>(
        _ endpoint: APIEndpoint,
        type: T.Type,
        completion: @escaping (Result<T, AppError>) -> Void
    ) {

        Task {

            do {

                let result = try await request(
                    endpoint,
                    type: type
                )

                completion(.success(result))

            } catch let error as AppError {

                completion(.failure(error))

            } catch {

                completion(
                    .failure(
                        .networkError(error.localizedDescription)
                    )
                )
            }
        }
    }
}
