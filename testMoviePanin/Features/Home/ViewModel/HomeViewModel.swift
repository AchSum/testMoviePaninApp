import Foundation

// MARK: - HomeViewModel
final class HomeViewModel {

    // MARK: - State
    enum State {
        case idle
        case loading
        case loaded
        case loadingMore
        case error(AppError)
    }

    // MARK: - Callbacks (MVVM bindings)
    var onStateChanged: ((State) -> Void)?
    var onMoviesUpdated: (() -> Void)?
    var onGenresUpdated: (() -> Void)?
    var onFavoritesChanged: ((Int, Bool) -> Void)?

    // MARK: - Data
    private(set) var movies: [Movie]       = []
    private(set) var genres: [Genre]       = []
    private(set) var filteredMovies: [Movie] = []

    private var currentPage: Int           = 1
    private var totalPages: Int            = 1
    private var selectedGenreId: Int?      = nil
    private var selectedSort: SortOption   = .popularity
    private var isFetchingMore: Bool       = false

    private let apiClient = APIClient.shared
    private let db        = DatabaseManager.shared

    var canLoadMore: Bool { currentPage < totalPages && !isFetchingMore }

    // MARK: - Fetch Popular Movies
    func fetchPopularMovies(refresh: Bool = false) {
        if refresh {
            currentPage = 1
            movies = []
        }

        guard currentPage == 1 else { return }
        onStateChanged?(.loading)

        Task { [weak self] in
            guard let self else { return }
            do {
                let response = try await apiClient.request(
                    .popularMovies(page: currentPage),
                    type: MovieResponse.self
                )
                await MainActor.run {
                    self.movies      = response.results
                    self.totalPages  = response.totalPages
                    self.currentPage = response.page
                    self.applyFilters()
                    self.onStateChanged?(.loaded)
                }
            } catch let error as AppError {
                await MainActor.run {
                    self.onStateChanged?(.error(error))
                }
            } catch {
                await MainActor.run {
                    self.onStateChanged?(.error(.networkError(error.localizedDescription)))
                }
            }
        }
    }

    // MARK: - Load More
    func loadMoreMovies() {
        guard canLoadMore else { return }
        isFetchingMore = true
        onStateChanged?(.loadingMore)

        let nextPage = currentPage + 1
        let endpoint: APIEndpoint = selectedGenreId != nil
            ? .moviesByGenre(genreId: selectedGenreId!, page: nextPage)
            : .popularMovies(page: nextPage)

        Task { [weak self] in
            guard let self else { return }
            do {
                let response = try await apiClient.request(endpoint, type: MovieResponse.self)
                await MainActor.run {
                    self.movies.append(contentsOf: response.results)
                    self.currentPage   = response.page
                    self.totalPages    = response.totalPages
                    self.isFetchingMore = false
                    self.applyFilters()
                    self.onStateChanged?(.loaded)
                }
            } catch {
                await MainActor.run {
                    self.isFetchingMore = false
                    self.onStateChanged?(.loaded)
                }
            }
        }
    }

    // MARK: - Fetch Genres
    func fetchGenres() {
        Task { [weak self] in
            guard let self else { return }
            do {
                let response = try await apiClient.request(.genres, type: GenreResponse.self)
                await MainActor.run {
                    self.genres = response.genres
                    self.onGenresUpdated?()
                }
            } catch {}
        }
    }

    // MARK: - Filter by Genre
    func selectGenre(id: Int?) {
        guard selectedGenreId != id else { return }
        selectedGenreId = id
        currentPage = 1
        movies = []

        onStateChanged?(.loading)

        let endpoint: APIEndpoint = id != nil
            ? .moviesByGenre(genreId: id!, page: 1)
            : .popularMovies(page: 1)

        Task { [weak self] in
            guard let self else { return }
            do {
                let response = try await apiClient.request(endpoint, type: MovieResponse.self)
                await MainActor.run {
                    self.movies      = response.results
                    self.totalPages  = response.totalPages
                    self.currentPage = response.page
                    self.applyFilters()
                    self.onStateChanged?(.loaded)
                }
            } catch let error as AppError {
                await MainActor.run { self.onStateChanged?(.error(error)) }
            }
        }
    }

    // MARK: - Sort
    func applySorting(_ option: SortOption) {
        selectedSort = option
        applyFilters()
        onMoviesUpdated?()
    }

    // MARK: - Apply Filters & Sort
    private func applyFilters() {
        var result = movies

        switch selectedSort {
        case .popularity:   result.sort { $0.popularity > $1.popularity }
        case .rating:       result.sort { $0.voteAverage > $1.voteAverage }
        case .releaseDate:  result.sort { ($0.releaseDate ?? "") > ($1.releaseDate ?? "") }
        case .title:        result.sort { $0.title < $1.title }
        }

        filteredMovies = result
        onMoviesUpdated?()
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
