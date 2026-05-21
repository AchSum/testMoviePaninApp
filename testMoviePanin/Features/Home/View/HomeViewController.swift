import UIKit
import SnapKit

// MARK: - HomeViewController
final class HomeViewController: UIViewController {

    // MARK: - ViewModel
    private let viewModel = HomeViewModel()

    // MARK: - UI Elements
    private lazy var collectionView: UICollectionView = {
        let cv = UICollectionView(frame: .zero, collectionViewLayout: createLayout())
        cv.backgroundColor = .clear
        cv.register(MovieCardCell.self, forCellWithReuseIdentifier: MovieCardCell.reuseIdentifier)
        cv.register(GenreChipCell.self, forCellWithReuseIdentifier: GenreChipCell.reuseIdentifier)
        cv.register(
            SectionHeaderView.self,
            forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader,
            withReuseIdentifier: SectionHeaderView.reuseIdentifier
        )
        cv.dataSource = self
        cv.delegate   = self
        cv.showsVerticalScrollIndicator = false
        return cv
    }()

    private let loadingView  = LoadingView()
    private let emptyView    = EmptyStateView(icon: "🎬", title: "No Movies", subtitle: "Pull down to refresh")

    private lazy var sortButton: UIBarButtonItem = {
        UIBarButtonItem(
            image: UIImage(systemName: "arrow.up.arrow.down"),
            style: .plain,
            target: self,
            action: #selector(showSortOptions)
        )
    }()

    private var selectedGenreIndex: Int? = nil
    private var currentSortLabel = SortOption.popularity.rawValue

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        bindViewModel()
        viewModel.fetchGenres()
        viewModel.fetchPopularMovies()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // Refresh favorites state
        collectionView.reloadData()
    }

    // MARK: - Setup UI
    private func setupUI() {
        title = AppStrings.popularMovies
        view.backgroundColor = AppColors.background
        navigationItem.rightBarButtonItem = sortButton

        view.addSubview(collectionView)
        view.addSubview(loadingView)
        view.addSubview(emptyView)

        collectionView.snp.makeConstraints { $0.edges.equalTo(view.safeAreaLayoutGuide) }
        loadingView.snp.makeConstraints { $0.edges.equalToSuperview() }
        emptyView.snp.makeConstraints { $0.edges.equalToSuperview() }

        emptyView.isHidden = true
        loadingView.isHidden = true
    }

    // MARK: - Bind ViewModel
    private func bindViewModel() {
        viewModel.onStateChanged = { [weak self] state in
            guard let self else { return }
            DispatchQueue.main.async {
                switch state {
                case .loading:
                    self.loadingView.startAnimating()
                    self.emptyView.isHidden = true
                case .loaded:
                    self.loadingView.stopAnimating()
                    self.emptyView.isHidden = !self.viewModel.filteredMovies.isEmpty
                    self.collectionView.reloadData()
                case .loadingMore:
                    break
                case .error(let error):
                    self.loadingView.stopAnimating()
                    if self.viewModel.filteredMovies.isEmpty {
                        self.emptyView.isHidden = false
                    }
                    if case .noInternet = error {} else {
                        self.showAlert(title: AppStrings.errorTitle, message: error.localizedDescription) {
                            self.viewModel.fetchPopularMovies(refresh: true)
                        }
                    }
                case .idle: break
                }
            }
        }

        viewModel.onMoviesUpdated = { [weak self] in
            
            guard let self = self else { return }

            DispatchQueue.main.async {
                self.collectionView.reloadData()
            }
        }

        viewModel.onGenresUpdated = { [weak self] in

            guard let self = self else { return }

            DispatchQueue.main.async {
                self.collectionView.reloadData()
            }
        }

        viewModel.onFavoritesChanged = { [weak self] movieId, isFav in
            DispatchQueue.main.async {
                self?.updateFavoriteCell(movieId: movieId, isFav: isFav)
            }
        }
    }

    // MARK: - Compositional Layout
    private func createLayout() -> UICollectionViewLayout {
        UICollectionViewCompositionalLayout { [weak self] sectionIndex, _ in
            sectionIndex == 0 ? self?.makeGenreSection() : self?.makeMoviesSection()
        }
    }

    private func makeGenreSection() -> NSCollectionLayoutSection {
        let itemSize    = NSCollectionLayoutSize(widthDimension: .estimated(80), heightDimension: .absolute(32))
        let item        = NSCollectionLayoutItem(layoutSize: itemSize)
        let groupSize   = NSCollectionLayoutSize(widthDimension: .estimated(80), heightDimension: .absolute(32))
        let group       = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitems: [item])
        let section     = NSCollectionLayoutSection(group: group)
        section.orthogonalScrollingBehavior = .continuous
        section.interGroupSpacing = 8
        section.contentInsets = NSDirectionalEdgeInsets(top: 12, leading: 16, bottom: 8, trailing: 16)
        return section
    }

    private func makeMoviesSection() -> NSCollectionLayoutSection {
        let itemSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(0.5),
            heightDimension: .absolute(LayoutConstants.movieCardHeight)
        )
        let item  = NSCollectionLayoutItem(layoutSize: itemSize)
        item.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 4, bottom: 0, trailing: 4)

        let groupSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1.0),
            heightDimension: .absolute(LayoutConstants.movieCardHeight)
        )
        let group   = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitem: item, count: 2)
        let section = NSCollectionLayoutSection(group: group)
        section.interGroupSpacing = 12
        section.contentInsets = NSDirectionalEdgeInsets(top: 8, leading: 12, bottom: 20, trailing: 12)

        let headerSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .absolute(44))
        let header = NSCollectionLayoutBoundarySupplementaryItem(
            layoutSize: headerSize,
            elementKind: UICollectionView.elementKindSectionHeader,
            alignment: .top
        )
        section.boundarySupplementaryItems = [header]
        return section
    }

    // MARK: - Sort
    @objc private func showSortOptions() {
        let sheet = UIAlertController(title: "Sort By", message: nil, preferredStyle: .actionSheet)
        SortOption.allCases.forEach { option in
            let action = UIAlertAction(title: option.rawValue, style: .default) { [weak self] _ in
                self?.viewModel.applySorting(option)
                self?.currentSortLabel = option.rawValue
            }
            sheet.addAction(action)
        }
        sheet.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        present(sheet, animated: true)
    }

    // MARK: - Update Single Cell Favorite State
    private func updateFavoriteCell(movieId: Int, isFav: Bool) {
        let movies = viewModel.filteredMovies
        if let index = movies.firstIndex(where: { $0.id == movieId }) {
            let indexPath = IndexPath(item: index, section: 1)
            if let cell = collectionView.cellForItem(at: indexPath) as? MovieCardCell {
                cell.updateFavorite(isFav)
            }
        }
    }
}

// MARK: - UICollectionView DataSource
extension HomeViewController: UICollectionViewDataSource {

    func numberOfSections(in collectionView: UICollectionView) -> Int { 2 }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        section == 0 ? viewModel.genres.count : viewModel.filteredMovies.count
    }

    func collectionView(_ collectionView: UICollectionView,
                        cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if indexPath.section == 0 {
            let cell = collectionView.dequeueReusableCell(
                withReuseIdentifier: GenreChipCell.reuseIdentifier, for: indexPath
            ) as! GenreChipCell
            let genre    = viewModel.genres[indexPath.item]
            let isSelected = indexPath.item == selectedGenreIndex
            cell.configure(with: genre.name, isSelected: isSelected)
            return cell
        } else {
            let cell = collectionView.dequeueReusableCell(
                withReuseIdentifier: MovieCardCell.reuseIdentifier, for: indexPath
            ) as! MovieCardCell
            let movie    = viewModel.filteredMovies[indexPath.item]
            let isFav    = viewModel.isFavorite(movieId: movie.id)
            cell.configure(with: movie, isFavorite: isFav)
            cell.onFavoriteTapped = { [weak self] in
                self?.viewModel.toggleFavorite(for: movie)
            }
            return cell
        }
    }

    func collectionView(_ collectionView: UICollectionView,
                        viewForSupplementaryElementOfKind kind: String,
                        at indexPath: IndexPath) -> UICollectionReusableView {
        guard indexPath.section == 1 else { return UICollectionReusableView() }
        let header = collectionView.dequeueReusableSupplementaryView(
            ofKind: kind,
            withReuseIdentifier: SectionHeaderView.reuseIdentifier,
            for: indexPath
        ) as! SectionHeaderView
        header.configure(title: "Movies", subtitle: "Sorted by \(currentSortLabel)")
        return header
    }
}

// MARK: - UICollectionView Delegate
extension HomeViewController: UICollectionViewDelegate {

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if indexPath.section == 0 {
            handleGenreSelection(at: indexPath)
        } else {
            let movie = viewModel.filteredMovies[indexPath.item]
            openDetail(for: movie)
        }
    }

    private func handleGenreSelection(at indexPath: IndexPath) {
        if selectedGenreIndex == indexPath.item {
            selectedGenreIndex = nil
            viewModel.selectGenre(id: nil)
        } else {
            selectedGenreIndex = indexPath.item
            viewModel.selectGenre(id: viewModel.genres[indexPath.item].id)
        }
        collectionView.reloadSections(IndexSet(integer: 0))
    }

    private func openDetail(for movie: Movie) {
        let vc = DetailViewController(movieId: movie.id)
        navigationController?.pushViewController(vc, animated: true)
    }

    // MARK: - Infinite Scroll
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let offsetY      = scrollView.contentOffset.y
        let contentHeight = scrollView.contentSize.height
        let threshold    = contentHeight - scrollView.frame.height - 200

        if offsetY > threshold && viewModel.canLoadMore {
            viewModel.loadMoreMovies()
        }
    }
}

// MARK: - SectionHeaderView
final class SectionHeaderView: UICollectionReusableView {

    static let reuseIdentifier = "SectionHeaderView"

    private let titleLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 18, weight: .bold)
        l.textColor = AppColors.primaryText
        return l
    }()

    private let subtitleLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 12)
        l.textColor = AppColors.secondaryText
        return l
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        addSubview(titleLabel)
        addSubview(subtitleLabel)
        titleLabel.snp.makeConstraints {
            $0.left.equalToSuperview().offset(4)
            $0.centerY.equalToSuperview().offset(-8)
        }
        subtitleLabel.snp.makeConstraints {
            $0.left.equalTo(titleLabel)
            $0.top.equalTo(titleLabel.snp.bottom).offset(2)
        }
    }

    required init?(coder: NSCoder) { fatalError() }

    func configure(title: String, subtitle: String) {
        titleLabel.text    = title
        subtitleLabel.text = subtitle
    }
}
