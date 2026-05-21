import Foundation

// MARK: - Movie Model
struct Movie: Codable, Equatable {
    let id: Int
    let title: String
    let overview: String
    let posterPath: String?
    let backdropPath: String?
    let releaseDate: String?
    let voteAverage: Double
    let voteCount: Int
    let popularity: Double
    let genreIds: [Int]?
    let originalLanguage: String?

    enum CodingKeys: String, CodingKey {
        case id, title, overview, popularity
        case posterPath      = "poster_path"
        case backdropPath    = "backdrop_path"
        case releaseDate     = "release_date"
        case voteAverage     = "vote_average"
        case voteCount       = "vote_count"
        case genreIds        = "genre_ids"
        case originalLanguage = "original_language"
    }

    // MARK: - Computed Properties
    var posterURL: String? {
        guard let path = posterPath else { return nil }
        return APIConstants.imageBaseURL + APIConstants.ImageSize.poster + path
    }

    var backdropURL: String? {
        guard let path = backdropPath else { return nil }
        return APIConstants.imageBaseURL + APIConstants.ImageSize.backdrop + path
    }

    var formattedRating: String {
        voteAverage.toRatingString()
    }

    var releaseYear: String {
        releaseDate?.toYear() ?? "N/A"
    }
}

// MARK: - Movie List Response
struct MovieResponse: Codable {
    let page: Int
    let results: [Movie]
    let totalPages: Int
    let totalResults: Int

    enum CodingKeys: String, CodingKey {
        case page, results
        case totalPages   = "total_pages"
        case totalResults = "total_results"
    }
}

// MARK: - Genre Model
struct Genre: Codable, Equatable {
    let id: Int
    let name: String
}

struct GenreResponse: Codable {
    let genres: [Genre]
}

// MARK: - Movie Detail Model (Full detail from API)
struct MovieDetail: Codable {
    let id: Int
    let title: String
    let overview: String
    let posterPath: String?
    let backdropPath: String?
    let releaseDate: String?
    let voteAverage: Double
    let voteCount: Int
    let popularity: Double
    let runtime: Int?
    let genres: [Genre]
    let originalLanguage: String?
    let tagline: String?
    let status: String?
    let budget: Int?
    let revenue: Int?
    let homepage: String?

    enum CodingKeys: String, CodingKey {
        case id, title, overview, popularity, runtime, genres, status, budget, revenue, homepage, tagline
        case posterPath      = "poster_path"
        case backdropPath    = "backdrop_path"
        case releaseDate     = "release_date"
        case voteAverage     = "vote_average"
        case voteCount       = "vote_count"
        case originalLanguage = "original_language"
    }

    var posterURL: String? {
        guard let path = posterPath else { return nil }
        return APIConstants.imageBaseURL + APIConstants.ImageSize.poster + path
    }

    var backdropURL: String? {
        guard let path = backdropPath else { return nil }
        return APIConstants.imageBaseURL + APIConstants.ImageSize.backdrop + path
    }

    var formattedRating: String { voteAverage.toRatingString() }
    var formattedDate: String  { releaseDate?.toFormattedDate() ?? "N/A" }
    var formattedRuntime: String { runtime?.toRuntimeString() ?? "N/A" }
    var genreNames: String { genres.map { $0.name }.joined(separator: " • ") }

    /// Convert MovieDetail → Movie (for favorites caching)
    func toMovie() -> Movie {
        Movie(
            id: id,
            title: title,
            overview: overview,
            posterPath: posterPath,
            backdropPath: backdropPath,
            releaseDate: releaseDate,
            voteAverage: voteAverage,
            voteCount: voteCount,
            popularity: popularity,
            genreIds: genres.map { $0.id },
            originalLanguage: originalLanguage
        )
    }
}

// MARK: - App Error
enum AppError: Error, LocalizedError {
    case invalidURL
    case noData
    case decodingFailed(String)
    case networkError(String)
    case serverError(Int)
    case cacheError(String)
    case noInternet
    case unknown

    var errorDescription: String? {
        switch self {
        case .invalidURL:           return "URL tidak valid."
        case .noData:               return "Data tidak ditemukan."
        case .decodingFailed(let msg): return "Gagal memproses data: \(msg)"
        case .networkError(let msg):   return "Koneksi bermasalah: \(msg)"
        case .serverError(let code):   return "Server error (\(code)). Coba beberapa saat lagi."
        case .cacheError(let msg):     return "Cache error: \(msg)"
        case .noInternet:           return "Tidak ada koneksi internet. Menampilkan data cache."
        case .unknown:              return "Terjadi kesalahan yang tidak diketahui."
        }
    }
}

// MARK: - Filter Option
enum SortOption: String, CaseIterable {
    case popularity  = "Popularity"
    case rating      = "Rating"
    case releaseDate = "Release Date"
    case title       = "Title"
}
