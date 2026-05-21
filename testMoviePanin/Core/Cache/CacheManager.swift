import Foundation

// MARK: - CacheManager (Cache-First Strategy)
final class CacheManager {

    static let shared = CacheManager()

    private let db      = DatabaseManager.shared
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    private init() {
        // Periodically clean expired cache
        cleanExpiredCacheIfNeeded()
    }

    // MARK: - Save
    func save<T: Encodable>(_ object: T, forKey key: String, expiresIn: TimeInterval = CacheConstants.movieCacheDuration) {
        guard let data = try? encoder.encode(object) else {
            print("⚠️ CacheManager: Failed to encode object for key: \(key)")
            return
        }
        db.saveCache(key: key, data: data, expiresIn: expiresIn)
    }

    // MARK: - Fetch (Cache-First)
    func fetch<T: Decodable>(forKey key: String, type: T.Type) -> T? {
        guard let data = db.fetchCache(key: key) else { return nil }
        do {
            return try decoder.decode(T.self, from: data)
        } catch {
            print("⚠️ CacheManager: Failed to decode cache for key: \(key) — \(error)")
            return nil
        }
    }

    // MARK: - Invalidate
    func invalidate(forKey key: String) {
        // Overwrite with expired data effectively removing it
        db.saveCache(key: key, data: Data(), expiresIn: -1)
    }

    // MARK: - Cleanup
    private func cleanExpiredCacheIfNeeded() {
        DispatchQueue.global(qos: .background).async { [weak self] in
            self?.db.clearExpiredCache()
        }
    }
}
