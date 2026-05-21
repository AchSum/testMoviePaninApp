import UIKit
import SnapKit

// MARK: - SearchViewController
final class SearchViewController: UIViewController {

    // MARK: - ViewModel
    private let viewModel = SearchViewModel()

    // MARK: - UI Elements
    private lazy var searchController: UISearchController = {
        let sc = UISearchController(searchResultsController: nil)
        sc.searchResultsUpdater           = self
        sc.obscuresBackgroundDuringPresentation = false
        sc.searchBar.placeholder          = AppStrings.searchPlaceholder
        sc.searchBar.tintColor            = AppColors.accent
        sc.searchBar.searchTextField.backgroundColor = AppColors.card
        sc.searchBar.searchTextField.textColor = AppColors.primaryText
        return sc
    }()

    private lazy var collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.minimumInteritemSpacing = 8
        layout.minimumLineSpacing      = 12
        layout.sectionInset            = UIEdgeInsets(top: 12, left: 12, bottom: 20, right: 12)

        let cv = UICollectionView(frame: .zero, collectionViewLayout: layout)
        cv.backgroundColor = .clear
        cv.register(MovieCardCell.self, forCellWithReuseIdentifier: MovieCardCell.reuseIdentifier)
        cv.dataSource = self
        cv.delegate   = self
        cv.keyboardDismissMode = .onDrag
        return cv
    }()

    private let loadingView = LoadingView()

    private let idleStateView = EmptyStateView(
        icon: "🔍",
        title: "Search Movies",
        subtitle: "Find your favorite films"
    )

    private let emptyStateView = EmptyStateView(
        icon: "😕",
        title: AppStrings.noResults,
        subtitle: "Try different keywords"
    )

    private let resultsCountLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 13)
        l.textColor = AppColors.secondaryText
        l.textAlignment = .center
        return l
    }()

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        bindViewModel()
    }

    // MARK: - Setup UI
    private func setupUI() {
        title = AppStrings.search
        view.backgroundColor = AppColors.background

        navigationItem.searchController        = searchController
        navigationItem.hidesSearchBarWhenScrolling = false
        definesPresentationContext = true

        view.addSubview(collectionView)
        view.addSubview(loadingView)
        view.addSubview(idleStateView)
        view.addSubview(emptyStateView)
        view.addSubview(resultsCountLabel)

        collectionView.snp.makeConstraints {
            $0.top.equalTo(view.safeAreaLayoutGuide).offset(36)
            $0.left.right.bottom.equalTo(view.safeAreaLayoutGuide)
        }

        loadingView.snp.makeConstraints { $0.edges.equalToSuperview() }
        idleStateView.snp.makeConstraints { $0.edges.equalToSuperview() }
        emptyStateView.snp.makeConstraints { $0.edges.equalToSuperview() }

        resultsCountLabel.snp.makeConstraints {
            $0.top.equalTo(view.safeAreaLayoutGuide).offset(8)
            $0.centerX.equalToSuperview()
        }

        setState(.idle)
    }

    // MARK: - Bind ViewModel
    private func bindViewModel() {
        viewModel.onStateChanged = { [weak self] state in
            DispatchQueue.main.async { self?.handleState(state) }
        }

        viewModel.onFavoritesChanged = { [weak self] movieId, isFav in
            DispatchQueue.main.async {
                self?.updateFavoriteCell(movieId: movieId, isFav: isFav)
            }
        }
    }

    private func handleState(_ state: SearchViewModel.State) {
        switch state {
        case .idle:
            setState(.idle)
        case .loading:
            loadingView.startAnimating()
            idleStateView.isHidden  = true
            emptyStateView.isHidden = true
            resultsCountLabel.text  = nil
        case .loaded:
            loadingView.stopAnimating()
            idleStateView.isHidden  = true
            emptyStateView.isHidden = true
            resultsCountLabel.text  = "\(viewModel.movies.count) results"
            collectionView.reloadData()
        case .empty:
            loadingView.stopAnimating()
            setState(.empty)
            resultsCountLabel.text = nil
            collectionView.reloadData()
        case .error(let error):
            loadingView.stopAnimating()
            showAlert(title: AppStrings.errorTitle, message: error.localizedDescription)
        }
    }

    private func setState(_ state: SearchViewModel.State) {
        idleStateView.isHidden  = true
        emptyStateView.isHidden = true
        loadingView.stopAnimating()

        switch state {
        case .idle:  idleStateView.isHidden = false
        case .empty: emptyStateView.isHidden = false
        default: break
        }
    }

    private func updateFavoriteCell(movieId: Int, isFav: Bool) {
        if let index = viewModel.movies.firstIndex(where: { $0.id == movieId }) {
            let ip = IndexPath(item: index, section: 0)
            if let cell = collectionView.cellForItem(at: ip) as? MovieCardCell {
                cell.updateFavorite(isFav)
            }
        }
    }
}

// MARK: - UISearchResultsUpdating
extension SearchViewController: UISearchResultsUpdating {
    func updateSearchResults(for searchController: UISearchController) {
        viewModel.search(query: searchController.searchBar.text ?? "")
    }
}

// MARK: - UICollectionView DataSource
extension SearchViewController: UICollectionViewDataSource {

    func collectionView(_ collectionView: UICollectionView,
                        numberOfItemsInSection section: Int) -> Int {
        viewModel.movies.count
    }

    func collectionView(_ collectionView: UICollectionView,
                        cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: MovieCardCell.reuseIdentifier, for: indexPath
        ) as! MovieCardCell
        let movie = viewModel.movies[indexPath.item]
        let isFav = viewModel.isFavorite(movieId: movie.id)
        cell.configure(with: movie, isFavorite: isFav)
        cell.onFavoriteTapped = { [weak self] in
            self?.viewModel.toggleFavorite(for: movie)
        }
        return cell
    }
}

// MARK: - UICollectionView Delegate + FlowLayout
extension SearchViewController: UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {

    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        sizeForItemAt indexPath: IndexPath) -> CGSize {
        let width = (collectionView.frame.width - 32) / 2
        return CGSize(width: width, height: LayoutConstants.movieCardHeight)
    }

    func collectionView(_ collectionView: UICollectionView,
                        didSelectItemAt indexPath: IndexPath) {
        let movie = viewModel.movies[indexPath.item]
        let vc = DetailViewController(movieId: movie.id)
        navigationController?.pushViewController(vc, animated: true)
    }

    // Infinite scroll
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let offsetY       = scrollView.contentOffset.y
        let contentHeight = scrollView.contentSize.height
        let threshold     = contentHeight - scrollView.frame.height - 200
        if offsetY > threshold && viewModel.canLoadMore {
            viewModel.loadMore()
        }
    }
}
