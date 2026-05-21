import Foundation

// MARK: - DetailViewModel
final class DetailViewModel {

    // MARK: - State
    enum State {
        case loading
        case loaded
        case error(AppError)
    }

    // MARK: - Callbacks
    var onStateChanged: ((State) -> Void)?
    var onFavoriteToggled: ((Bool) -> Void)?

    // MARK: - Data
    private(set) var movieDetail: MovieDetail?
    private(set) var isFavorite: Bool = false

    private let movieId: Int
    private let apiClient = APIClient.shared
    private let db        = DatabaseManager.shared

    init(movieId: Int) {
        self.movieId   = movieId
        self.isFavorite = db.isFavorite(movieId: movieId)
    }

    // MARK: - Fetch Detail
    func fetchDetail() {
        onStateChanged?(.loading)

        Task { [weak self] in
            guard let self else { return }
            do {
                let detail = try await apiClient.request(
                    .movieDetail(id: movieId),
                    type: MovieDetail.self
                )
                await MainActor.run {
                    self.movieDetail = detail
                    self.onStateChanged?(.loaded)
                }
            } catch let error as AppError {
                await MainActor.run { self.onStateChanged?(.error(error)) }
            } catch {
                await MainActor.run { self.onStateChanged?(.error(.networkError(error.localizedDescription))) }
            }
        }
    }

    // MARK: - Toggle Favorite
    func toggleFavorite() {
        guard let detail = movieDetail else { return }
        let movie = detail.toMovie()

        if isFavorite {
            db.removeFavorite(movieId: movieId)
            isFavorite = false
        } else {
            db.saveFavorite(movie: movie)
            isFavorite = true
        }
        onFavoriteToggled?(isFavorite)
    }
}
