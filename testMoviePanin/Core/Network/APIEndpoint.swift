import Foundation

// MARK: - API Endpoint
enum APIEndpoint {
    case popularMovies(page: Int)
    case searchMovies(query: String, page: Int)
    case movieDetail(id: Int)
    case moviesByGenre(genreId: Int, page: Int)
    case genres
    case topRated(page: Int)
    case nowPlaying(page: Int)

    // MARK: - Path
    var path: String {
        switch self {
        case .popularMovies:         return "/movie/popular"
        case .searchMovies:          return "/search/movie"
        case .movieDetail(let id):   return "/movie/\(id)"
        case .moviesByGenre:         return "/discover/movie"
        case .genres:                return "/genre/movie/list"
        case .topRated:              return "/movie/top_rated"
        case .nowPlaying:            return "/movie/now_playing"
        }
    }

    // MARK: - Query Parameters
    var queryItems: [URLQueryItem] {
        var items: [URLQueryItem] = [
            URLQueryItem(name: "api_key", value: APIConstants.apiKey),
            URLQueryItem(name: "language", value: "en-US")
        ]

        switch self {
        case .popularMovies(let page):
            items.append(URLQueryItem(name: "page", value: "\(page)"))

        case .searchMovies(let query, let page):
            items.append(URLQueryItem(name: "query", value: query))
            items.append(URLQueryItem(name: "page", value: "\(page)"))

        case .movieDetail:
            items.append(URLQueryItem(name: "append_to_response", value: "credits,videos"))

        case .moviesByGenre(let genreId, let page):
            items.append(URLQueryItem(name: "with_genres", value: "\(genreId)"))
            items.append(URLQueryItem(name: "sort_by", value: "popularity.desc"))
            items.append(URLQueryItem(name: "page", value: "\(page)"))

        case .genres, .topRated, .nowPlaying:
            if case .topRated(let page) = self {
                items.append(URLQueryItem(name: "page", value: "\(page)"))
            }
            if case .nowPlaying(let page) = self {
                items.append(URLQueryItem(name: "page", value: "\(page)"))
            }
        }

        return items
    }

    // MARK: - Build URL
    var url: URL? {
        var components = URLComponents(string: APIConstants.baseURL + path)
        components?.queryItems = queryItems
        return components?.url
    }

    // MARK: - Cache Key
    var cacheKey: String {
        switch self {
        case .popularMovies(let page):         return "popular_page_\(page)"
        case .searchMovies(let query, let page): return "search_\(query)_page_\(page)"
        case .movieDetail(let id):             return "detail_\(id)"
        case .moviesByGenre(let id, let page): return "genre_\(id)_page_\(page)"
        case .genres:                          return "genres"
        case .topRated(let page):              return "toprated_page_\(page)"
        case .nowPlaying(let page):            return "nowplaying_page_\(page)"
        }
    }
}
