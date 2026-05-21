import UIKit

// MARK: - App Colors
enum AppColors {
    static let background   = UIColor(hex: "#0D0D0D")
    static let surface      = UIColor(hex: "#1A1A2E")
    static let card         = UIColor(hex: "#16213E")
    static let accent       = UIColor(hex: "#E94560")
    static let accentLight  = UIColor(hex: "#FF6B6B")
    static let primaryText  = UIColor.white
    static let secondaryText = UIColor(hex: "#A0A0B0")
    static let starColor    = UIColor(hex: "#FFD700")
    static let success      = UIColor(hex: "#4CAF50")
    static let warning      = UIColor(hex: "#FF9800")
}

// MARK: - API Constants
enum APIConstants {
    static let baseURL      = "https://api.themoviedb.org/3"
    static let imageBaseURL = "https://image.tmdb.org/t/p"
    static let apiKey       = "GANTI_DENGAN_API_KEY_TMDB_KAMU"

    enum ImageSize {
        static let poster    = "/w342"
        static let backdrop  = "/w780"
        static let original  = "/original"
        static let small     = "/w185"
    }

    enum Timeout {
        static let request: TimeInterval  = 30
        static let resource: TimeInterval = 60
    }
}

// MARK: - Cache Constants
enum CacheConstants {
    static let movieCacheDuration: TimeInterval = 3600        // 1 hour
    static let genreCacheDuration: TimeInterval = 86400       // 24 hours
    static let detailCacheDuration: TimeInterval = 7200       // 2 hours
    static let imageDiskCacheLimit: Int = 200 * 1024 * 1024   // 200 MB
    static let imageMemoryCacheCount: Int = 100
}

// MARK: - App String Constants
enum AppStrings {
    static let appName          = "CineTrack"
    static let popularMovies    = "Popular Movies"
    static let search           = "Search"
    static let favorites        = "Favorites"
    static let searchPlaceholder = "Search movies..."
    static let noResults        = "No results found"
    static let noFavorites      = "No favorites yet"
    static let addFavoriteHint  = "Tap ♥ on any movie to save it here"
    static let errorTitle       = "Oops!"
    static let retry            = "Retry"
    static let ok               = "OK"
    static let loadingMore      = "Loading more..."
    static let genres           = "Genres"
    static let overview         = "Overview"
    static let rating           = "Rating"
    static let releaseDate      = "Release Date"
    static let runtime          = "Runtime"
    static let language         = "Language"
}

// MARK: - Layout Constants
enum LayoutConstants {
    static let defaultPadding: CGFloat   = 16
    static let cardRadius: CGFloat       = 12
    static let smallRadius: CGFloat      = 8
    static let movieCardWidth: CGFloat   = UIScreen.main.bounds.width / 2 - 24
    static let movieCardHeight: CGFloat  = 280
    static let posterAspectRatio: CGFloat = 1.5
}
