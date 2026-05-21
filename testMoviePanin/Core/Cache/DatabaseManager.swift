import Foundation
import SQLite3

// MARK: - DatabaseManager
final class DatabaseManager {

    static let shared = DatabaseManager()

    private var db: OpaquePointer?
    private let dbName = "CineTrack.sqlite"
    private let queue  = DispatchQueue(label: "com.cinetrack.database", attributes: .concurrent)

    private init() {}

    // MARK: - Setup
    func setupDatabase() {
        let path = getDatabasePath()
        if sqlite3_open(path, &db) == SQLITE_OK {
            createTables()
            print("✅ Database opened at: \(path)")
        } else {
            print("❌ Failed to open database")
        }
    }

    private func getDatabasePath() -> String {
        let dirs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        return dirs[0].appendingPathComponent(dbName).path
    }

    // MARK: - Create Tables
    private func createTables() {
        let apiCacheTable = """
            CREATE TABLE IF NOT EXISTS api_cache (
                cache_key   TEXT PRIMARY KEY,
                data        BLOB NOT NULL,
                created_at  REAL NOT NULL,
                expires_at  REAL NOT NULL
            );
        """

        let favoritesTable = """
            CREATE TABLE IF NOT EXISTS favorites (
                movie_id    INTEGER PRIMARY KEY,
                data        BLOB NOT NULL,
                added_at    REAL NOT NULL
            );
        """

        execute(sql: apiCacheTable)
        execute(sql: favoritesTable)
    }

    // MARK: - Generic Execute
    private func execute(sql: String) {
        var statement: OpaquePointer?
        if sqlite3_prepare_v2(db, sql, -1, &statement, nil) == SQLITE_OK {
            sqlite3_step(statement)
        }
        sqlite3_finalize(statement)
    }

    // MARK: - API Cache CRUD

    func saveCache(key: String, data: Data, expiresIn: TimeInterval) {
        queue.async(flags: .barrier) { [weak self] in
            guard let self else { return }
            let now       = Date().timeIntervalSince1970
            let expiresAt = now + expiresIn
            let sql = """
                INSERT OR REPLACE INTO api_cache (cache_key, data, created_at, expires_at)
                VALUES (?, ?, ?, ?);
            """
            var statement: OpaquePointer?
            if sqlite3_prepare_v2(self.db, sql, -1, &statement, nil) == SQLITE_OK {
                sqlite3_bind_text(statement, 1, (key as NSString).utf8String, -1, nil)
                _ = data.withUnsafeBytes { bytes in
                    sqlite3_bind_blob(statement, 2, bytes.baseAddress, Int32(data.count), nil)
                }
                sqlite3_bind_double(statement, 3, now)
                sqlite3_bind_double(statement, 4, expiresAt)
                sqlite3_step(statement)
            }
            sqlite3_finalize(statement)
        }
    }

    func fetchCache(key: String) -> Data? {
        var result: Data?
        queue.sync { [weak self] in
            guard let self else { return }
            let now = Date().timeIntervalSince1970
            let sql = "SELECT data FROM api_cache WHERE cache_key = ? AND expires_at > ?;"
            var statement: OpaquePointer?
            if sqlite3_prepare_v2(self.db, sql, -1, &statement, nil) == SQLITE_OK {
                sqlite3_bind_text(statement, 1, (key as NSString).utf8String, -1, nil)
                sqlite3_bind_double(statement, 2, now)
                if sqlite3_step(statement) == SQLITE_ROW {
                    let size  = Int(sqlite3_column_bytes(statement, 0))
                    let bytes = sqlite3_column_blob(statement, 0)
                    if let bytes = bytes {
                        result = Data(bytes: bytes, count: size)
                    }
                }
            }
            sqlite3_finalize(statement)
        }
        return result
    }

    func clearExpiredCache() {
        queue.async(flags: .barrier) { [weak self] in
            guard let self else { return }
            let sql = "DELETE FROM api_cache WHERE expires_at <= ?;"
            var statement: OpaquePointer?
            if sqlite3_prepare_v2(self.db, sql, -1, &statement, nil) == SQLITE_OK {
                sqlite3_bind_double(statement, 1, Date().timeIntervalSince1970)
                sqlite3_step(statement)
            }
            sqlite3_finalize(statement)
        }
    }

    // MARK: - Favorites CRUD

    func saveFavorite(movie: Movie) {
        queue.async(flags: .barrier) { [weak self] in
            guard let self,
                  let data = try? JSONEncoder().encode(movie) else { return }
            let sql = """
                INSERT OR REPLACE INTO favorites (movie_id, data, added_at)
                VALUES (?, ?, ?);
            """
            var statement: OpaquePointer?
            if sqlite3_prepare_v2(self.db, sql, -1, &statement, nil) == SQLITE_OK {
                sqlite3_bind_int(statement, 1, Int32(movie.id))
                _ = data.withUnsafeBytes { bytes in
                    sqlite3_bind_blob(statement, 2, bytes.baseAddress, Int32(data.count), nil)
                }
                sqlite3_bind_double(statement, 3, Date().timeIntervalSince1970)
                sqlite3_step(statement)
            }
            sqlite3_finalize(statement)
        }
    }

    func removeFavorite(movieId: Int) {
        queue.async(flags: .barrier) { [weak self] in
            guard let self else { return }
            let sql = "DELETE FROM favorites WHERE movie_id = ?;"
            var statement: OpaquePointer?
            if sqlite3_prepare_v2(self.db, sql, -1, &statement, nil) == SQLITE_OK {
                sqlite3_bind_int(statement, 1, Int32(movieId))
                sqlite3_step(statement)
            }
            sqlite3_finalize(statement)
        }
    }

    func fetchAllFavorites() -> [Movie] {
        var movies: [Movie] = []
        queue.sync { [weak self] in
            guard let self else { return }
            let sql = "SELECT data FROM favorites ORDER BY added_at DESC;"
            var statement: OpaquePointer?
            if sqlite3_prepare_v2(self.db, sql, -1, &statement, nil) == SQLITE_OK {
                while sqlite3_step(statement) == SQLITE_ROW {
                    let size  = Int(sqlite3_column_bytes(statement, 0))
                    let bytes = sqlite3_column_blob(statement, 0)
                    if let bytes = bytes,
                       let movie = try? JSONDecoder().decode(Movie.self, from: Data(bytes: bytes, count: size)) {
                        movies.append(movie)
                    }
                }
            }
            sqlite3_finalize(statement)
        }
        return movies
    }

    func isFavorite(movieId: Int) -> Bool {
        var result = false
        queue.sync { [weak self] in
            guard let self else { return }
            let sql = "SELECT COUNT(*) FROM favorites WHERE movie_id = ?;"
            var statement: OpaquePointer?
            if sqlite3_prepare_v2(self.db, sql, -1, &statement, nil) == SQLITE_OK {
                sqlite3_bind_int(statement, 1, Int32(movieId))
                if sqlite3_step(statement) == SQLITE_ROW {
                    result = sqlite3_column_int(statement, 0) > 0
                }
            }
            sqlite3_finalize(statement)
        }
        return result
    }

    deinit {
        sqlite3_close(db)
    }
}
