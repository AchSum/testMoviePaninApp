import Foundation

// MARK: - SearchViewModel
final class SearchViewModel {

    // MARK: - State
    enum State {
        case idle
        case loading
        case loaded
        case empty
        case error(AppError)
    }

    // MARK: - Callbacks
    var onStateChanged: ((State) -> Void)?
    var onFavoritesChanged: ((Int, Bool) -> Void)?

    // MARK: - Data
    private(set) var movies: [Movie] = []

    private var currentQuery: String = ""
    private var currentPage: Int     = 1
    private var totalPages: Int      = 1
    private var isFetchingMore       = false
    private var searchTask: Task<Void, Never>?

    var canLoadMore: Bool { currentPage < totalPages && !isFetchingMore }

    private let apiClient = APIClient.shared
    private let db        = DatabaseManager.shared

    // MARK: - Search with Debounce
    func search(query: String) {
        let trimmed = query.trimmingCharacters(in: .whitespaces)

        guard trimmed != currentQuery else { return }
        currentQuery = trimmed

        searchTask?.cancel()

        guard !trimmed.isEmpty else {
            movies = []
            onStateChanged?(.idle)
            return
        }

        onStateChanged?(.loading)

        searchTask = Task { [weak self] in
            guard let self else { return }

            // Debounce 400ms
            try? await Task.sleep(nanoseconds: 400_000_000)
            guard !Task.isCancelled else { return }

            await self.performSearch(query: trimmed, page: 1, reset: true)
        }
    }

    // MARK: - Load More Search Results
    func loadMore() {
        guard canLoadMore else { return }
        isFetchingMore = true
        Task { [weak self] in
            guard let self else { return }
            await self.performSearch(query: self.currentQuery, page: self.currentPage + 1, reset: false)
        }
    }

    // MARK: - Perform Search
    @MainActor
    private func performSearch(query: String, page: Int, reset: Bool) async {
        do {
            let response = try await apiClient.request(
                .searchMovies(query: query, page: page),
                type: MovieResponse.self
            )
            if reset {
                movies = response.results
            } else {
                movies.append(contentsOf: response.results)
            }
            currentPage    = response.page
            totalPages     = response.totalPages
            isFetchingMore = false
            onStateChanged?(movies.isEmpty ? .empty : .loaded)
        } catch let error as AppError {
            isFetchingMore = false
            onStateChanged?(.error(error))
        } catch {
            isFetchingMore = false
            onStateChanged?(.error(.networkError(error.localizedDescription)))
        }
    }

    // MARK: - Favorites
    func toggleFavorite(for movie: Movie) {
        let isFav = db.isFavorite(movieId: movie.id)
        if isFav {
            db.removeFavorite(movieId: movie.id)
        } else {
            db.saveFavorite(movie: movie)
        }
        onFavoritesChanged?(movie.id, !isFav)
    }

    func isFavorite(movieId: Int) -> Bool {
        db.isFavorite(movieId: movieId)
    }
}
