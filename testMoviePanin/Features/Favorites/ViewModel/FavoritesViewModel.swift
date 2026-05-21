import Foundation
import UIKit

// MARK: - FavoritesViewModel
final class FavoritesViewModel {

    // MARK: - Callbacks
    var onDataChanged: (() -> Void)?

    // MARK: - Data
    private(set) var favorites: [Movie]         = []
    private(set) var filteredFavorites: [Movie] = []

    private var currentSort: SortOption = .popularity
    private let db = DatabaseManager.shared

    // MARK: - Fetch
    func fetchFavorites() {
        favorites         = db.fetchAllFavorites()
        applySort()
    }

    // MARK: - Remove
    func removeFavorite(at indexPath: IndexPath) {
        let movie = filteredFavorites[indexPath.item]
        db.removeFavorite(movieId: movie.id)
        if let idx = favorites.firstIndex(where: { $0.id == movie.id }) {
            favorites.remove(at: idx)
        }
        filteredFavorites.remove(at: indexPath.item)
        onDataChanged?()
    }

    func removeFavorite(movieId: Int) {
        db.removeFavorite(movieId: movieId)
        favorites.removeAll { $0.id == movieId }
        applySort()
    }

    // MARK: - Sort
    func applySorting(_ option: SortOption) {
        currentSort = option
        applySort()
    }

    private func applySort() {
        var result = favorites
        switch currentSort {
        case .popularity:   result.sort { $0.popularity > $1.popularity }
        case .rating:       result.sort { $0.voteAverage > $1.voteAverage }
        case .releaseDate:  result.sort { ($0.releaseDate ?? "") > ($1.releaseDate ?? "") }
        case .title:        result.sort { $0.title < $1.title }
        }
        filteredFavorites = result
        onDataChanged?()
    }

    var isEmpty: Bool { filteredFavorites.isEmpty }
}
