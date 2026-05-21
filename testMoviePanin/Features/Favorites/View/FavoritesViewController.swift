import UIKit
import SnapKit

// MARK: - FavoritesViewController
final class FavoritesViewController: UIViewController {

    // MARK: - ViewModel
    private let viewModel = FavoritesViewModel()

    // MARK: - UI Elements
    private lazy var collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.minimumInteritemSpacing = 8
        layout.minimumLineSpacing      = 12
        layout.sectionInset = UIEdgeInsets(top: 12, left: 12, bottom: 20, right: 12)

        let cv = UICollectionView(frame: .zero, collectionViewLayout: layout)
        cv.backgroundColor = .clear
        cv.register(MovieCardCell.self, forCellWithReuseIdentifier: MovieCardCell.reuseIdentifier)
        cv.dataSource = self
        cv.delegate   = self
        cv.showsVerticalScrollIndicator = false
        return cv
    }()

    private let emptyStateView = EmptyStateView(
        icon: "❤️",
        title: AppStrings.noFavorites,
        subtitle: AppStrings.addFavoriteHint
    )

    private let countLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 13)
        l.textColor = AppColors.secondaryText
        l.textAlignment = .center
        return l
    }()

    private lazy var sortButton: UIBarButtonItem = {
        UIBarButtonItem(
            image: UIImage(systemName: "arrow.up.arrow.down"),
            style: .plain,
            target: self,
            action: #selector(showSortOptions)
        )
    }()

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        bindViewModel()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        viewModel.fetchFavorites()
    }

    // MARK: - Setup UI
    private func setupUI() {
        title = AppStrings.favorites
        view.backgroundColor = AppColors.background
        navigationItem.rightBarButtonItem = sortButton

        view.addSubview(collectionView)
        view.addSubview(emptyStateView)
        view.addSubview(countLabel)

        countLabel.snp.makeConstraints {
            $0.top.equalTo(view.safeAreaLayoutGuide).offset(8)
            $0.centerX.equalToSuperview()
        }

        collectionView.snp.makeConstraints {
            $0.top.equalTo(view.safeAreaLayoutGuide).offset(36)
            $0.left.right.bottom.equalTo(view.safeAreaLayoutGuide)
        }

        emptyStateView.snp.makeConstraints { $0.edges.equalToSuperview() }
    }

    // MARK: - Bind ViewModel
    private func bindViewModel() {
        viewModel.onDataChanged = { [weak self] in
            DispatchQueue.main.async { self?.refresh() }
        }
    }

    private func refresh() {
        let isEmpty = viewModel.isEmpty
        emptyStateView.isHidden = !isEmpty
        collectionView.isHidden = isEmpty
        countLabel.text = isEmpty ? nil : "\(viewModel.filteredFavorites.count) saved"
        collectionView.reloadData()
    }

    // MARK: - Sort
    @objc private func showSortOptions() {
        let sheet = UIAlertController(title: "Sort Favorites", message: nil, preferredStyle: .actionSheet)
        SortOption.allCases.forEach { option in
            sheet.addAction(UIAlertAction(title: option.rawValue, style: .default) { [weak self] _ in
                self?.viewModel.applySorting(option)
            })
        }
        sheet.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        present(sheet, animated: true)
    }
}

// MARK: - UICollectionView DataSource
extension FavoritesViewController: UICollectionViewDataSource {

    func collectionView(_ collectionView: UICollectionView,
                        numberOfItemsInSection section: Int) -> Int {
        viewModel.filteredFavorites.count
    }

    func collectionView(_ collectionView: UICollectionView,
                        cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: MovieCardCell.reuseIdentifier, for: indexPath
        ) as! MovieCardCell
        let movie = viewModel.filteredFavorites[indexPath.item]
        cell.configure(with: movie, isFavorite: true)
        cell.onFavoriteTapped = { [weak self] in
            guard let self else { return }
            self.viewModel.removeFavorite(movieId: movie.id)
        }
        return cell
    }
}

// MARK: - UICollectionView Delegate
extension FavoritesViewController: UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {

    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        sizeForItemAt indexPath: IndexPath) -> CGSize {
        let width = (collectionView.frame.width - 32) / 2
        return CGSize(width: width, height: LayoutConstants.movieCardHeight)
    }

    func collectionView(_ collectionView: UICollectionView,
                        didSelectItemAt indexPath: IndexPath) {
        let movie = viewModel.filteredFavorites[indexPath.item]
        let vc = DetailViewController(movieId: movie.id)
        navigationController?.pushViewController(vc, animated: true)
    }

    // Swipe to delete (long press menu)
    func collectionView(
        _ collectionView: UICollectionView,
        contextMenuConfigurationForItemAt indexPath: IndexPath,
        point: CGPoint
    ) -> UIContextMenuConfiguration? {
        UIContextMenuConfiguration(identifier: nil, previewProvider: nil) { [weak self] _ in
            let delete = UIAction(
                title: "Remove from Favorites",
                image: UIImage(systemName: "heart.slash"),
                attributes: .destructive
            ) { _ in
                self?.viewModel.removeFavorite(at: indexPath)
            }
            return UIMenu(title: "", children: [delete])
        }
    }
}
