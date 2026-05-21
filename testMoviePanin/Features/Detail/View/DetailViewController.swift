import UIKit
import SnapKit

// MARK: - DetailViewController
final class DetailViewController: UIViewController {

    // MARK: - ViewModel
    private let viewModel: DetailViewModel

    // MARK: - UI Elements
    private let scrollView = UIScrollView()
    private let contentView = UIView()

    private let backdropImageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
        iv.backgroundColor = AppColors.card
        return iv
    }()

    private let backdropGradient: UIView = UIView()

    private let posterImageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
        iv.layer.cornerRadius = 10
        iv.layer.borderWidth  = 2
        iv.layer.borderColor  = AppColors.accent.cgColor
        iv.backgroundColor    = AppColors.card
        return iv
    }()

    private let titleLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 22, weight: .bold)
        l.textColor = AppColors.primaryText
        l.numberOfLines = 2
        return l
    }()

    private let taglineLabel: UILabel = {
        let l = UILabel()
        l.font = .italicSystemFont(ofSize: 14)
        l.textColor = AppColors.secondaryText
        l.numberOfLines = 2
        return l
    }()

    private let ratingStars = RatingStarsView()

    private let ratingLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 15, weight: .semibold)
        l.textColor = AppColors.starColor
        return l
    }()

    private let voteCountLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 12)
        l.textColor = AppColors.secondaryText
        return l
    }()

    private let metaStackView: UIStackView = {
        let s = UIStackView()
        s.axis = .horizontal
        s.spacing = 16
        s.alignment = .center
        return s
    }()

    private let genreLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 13)
        l.textColor = AppColors.accent
        l.numberOfLines = 2
        return l
    }()

    private let overviewTitleLabel: UILabel = {
        let l = UILabel()
        l.text = AppStrings.overview
        l.font = .systemFont(ofSize: 17, weight: .bold)
        l.textColor = AppColors.primaryText
        return l
    }()

    private let overviewLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 14)
        l.textColor = AppColors.secondaryText
        l.numberOfLines = 0
        return l
    }()

    private let infoCardView: UIView = {
        let v = UIView()
        v.backgroundColor = AppColors.card
        v.layer.cornerRadius = LayoutConstants.cardRadius
        return v
    }()

    private let loadingView = LoadingView()
    private lazy var favoriteBarButton: UIBarButtonItem = {
        UIBarButtonItem(
            image: UIImage(systemName: "heart"),
            style: .plain,
            target: self,
            action: #selector(favoriteTapped)
        )
    }()

    // MARK: - Init
    init(movieId: Int) {
        self.viewModel = DetailViewModel(movieId: movieId)
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) { fatalError() }

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        bindViewModel()
        viewModel.fetchDetail()
        updateFavoriteButton(viewModel.isFavorite)
    }

    // MARK: - Setup UI
    private func setupUI() {
        view.backgroundColor = AppColors.background
        navigationItem.largeTitleDisplayMode = .never
        navigationItem.rightBarButtonItem    = favoriteBarButton

        view.addSubview(scrollView)
        scrollView.addSubview(contentView)

        scrollView.snp.makeConstraints { $0.edges.equalTo(view.safeAreaLayoutGuide) }
        contentView.snp.makeConstraints {
            $0.edges.equalToSuperview()
            $0.width.equalTo(scrollView)
        }

        setupBackdrop()
        setupInfoSection()
        setupOverview()
        setupInfoCard()

        view.addSubview(loadingView)
        loadingView.snp.makeConstraints { $0.edges.equalToSuperview() }
    }

    private func setupBackdrop() {
        contentView.addSubview(backdropImageView)
        contentView.addSubview(backdropGradient)
        contentView.addSubview(posterImageView)

        backdropImageView.snp.makeConstraints {
            $0.top.left.right.equalToSuperview()
            $0.height.equalTo(220)
        }

        backdropGradient.snp.makeConstraints { $0.edges.equalTo(backdropImageView) }

        posterImageView.snp.makeConstraints {
            $0.left.equalToSuperview().offset(16)
            $0.top.equalTo(backdropImageView.snp.bottom).offset(-60)
            $0.width.equalTo(100)
            $0.height.equalTo(150)
        }
    }

    private func setupInfoSection() {
        contentView.addSubview(titleLabel)
        contentView.addSubview(taglineLabel)
        contentView.addSubview(genreLabel)

        let ratingRow = UIStackView(arrangedSubviews: [ratingStars, ratingLabel, voteCountLabel])
        ratingRow.axis    = .horizontal
        ratingRow.spacing = 6
        ratingRow.alignment = .center
        contentView.addSubview(ratingRow)

        titleLabel.snp.makeConstraints {
            $0.top.equalTo(backdropImageView.snp.bottom).offset(12)
            $0.left.equalTo(posterImageView.snp.right).offset(12)
            $0.right.equalToSuperview().inset(16)
        }

        taglineLabel.snp.makeConstraints {
            $0.top.equalTo(titleLabel.snp.bottom).offset(4)
            $0.left.equalTo(titleLabel)
            $0.right.equalTo(titleLabel)
        }

        ratingRow.snp.makeConstraints {
            $0.top.equalTo(taglineLabel.snp.bottom).offset(8)
            $0.left.equalTo(titleLabel)
        }

        genreLabel.snp.makeConstraints {
            $0.top.equalTo(posterImageView.snp.bottom).offset(12)
            $0.left.equalToSuperview().offset(16)
            $0.right.equalToSuperview().inset(16)
        }
    }

    private func setupOverview() {
        contentView.addSubview(overviewTitleLabel)
        contentView.addSubview(overviewLabel)

        overviewTitleLabel.snp.makeConstraints {
            $0.top.equalTo(genreLabel.snp.bottom).offset(16)
            $0.left.equalToSuperview().offset(16)
        }

        overviewLabel.snp.makeConstraints {
            $0.top.equalTo(overviewTitleLabel.snp.bottom).offset(8)
            $0.left.equalToSuperview().offset(16)
            $0.right.equalToSuperview().inset(16)
        }
    }

    private func setupInfoCard() {
        contentView.addSubview(infoCardView)

        infoCardView.snp.makeConstraints {
            $0.top.equalTo(overviewLabel.snp.bottom).offset(20)
            $0.left.equalToSuperview().offset(16)
            $0.right.equalToSuperview().inset(16)
            $0.bottom.equalToSuperview().inset(30)
        }
    }

    private func populateInfoCard(detail: MovieDetail) {
        infoCardView.subviews.forEach { $0.removeFromSuperview() }

        let items: [(String, String)] = [
            ("📅 \(AppStrings.releaseDate)", detail.formattedDate),
            ("⏱ \(AppStrings.runtime)",     detail.formattedRuntime),
            ("🌐 \(AppStrings.language)",    detail.originalLanguage?.uppercased() ?? "N/A"),
            ("⭐ \(AppStrings.rating)",      "\(detail.formattedRating) / 10")
        ]

        let stack = UIStackView()
        stack.axis    = .vertical
        stack.spacing = 0

        for (index, item) in items.enumerated() {
            let row = makeInfoRow(label: item.0, value: item.1)
            stack.addArrangedSubview(row)
            if index < items.count - 1 {
                let divider = UIView()
                divider.backgroundColor = AppColors.surface
                divider.snp.makeConstraints { $0.height.equalTo(1) }
                stack.addArrangedSubview(divider)
            }
        }

        infoCardView.addSubview(stack)
        stack.snp.makeConstraints {
            $0.edges.equalToSuperview().inset(UIEdgeInsets(top: 4, left: 0, bottom: 4, right: 0))
        }
    }

    private func makeInfoRow(label: String, value: String) -> UIView {
        let container = UIView()
        let labelView = UILabel()
        labelView.text      = label
        labelView.font      = .systemFont(ofSize: 14)
        labelView.textColor = AppColors.secondaryText

        let valueView = UILabel()
        valueView.text      = value
        valueView.font      = .systemFont(ofSize: 14, weight: .semibold)
        valueView.textColor = AppColors.primaryText
        valueView.textAlignment = .right

        container.addSubview(labelView)
        container.addSubview(valueView)

        labelView.snp.makeConstraints {
            $0.left.equalToSuperview().offset(16)
            $0.centerY.equalToSuperview()
        }
        valueView.snp.makeConstraints {
            $0.right.equalToSuperview().inset(16)
            $0.centerY.equalToSuperview()
            $0.left.greaterThanOrEqualTo(labelView.snp.right).offset(8)
        }
        container.snp.makeConstraints { $0.height.equalTo(50) }
        return container
    }

    // MARK: - Bind ViewModel
    private func bindViewModel() {
        viewModel.onStateChanged = { [weak self] state in
            DispatchQueue.main.async {
                switch state {
                case .loading:
                    self?.loadingView.startAnimating()
                case .loaded:
                    self?.loadingView.stopAnimating()
                    self?.populate()
                case .error(let error):
                    self?.loadingView.stopAnimating()
                    self?.showAlert(
                        title: AppStrings.errorTitle,
                        message: error.localizedDescription
                    ) { self?.viewModel.fetchDetail() }
                }
            }
        }

        viewModel.onFavoriteToggled = { [weak self] isFav in
            DispatchQueue.main.async { self?.updateFavoriteButton(isFav) }
        }
    }

    // MARK: - Populate UI
    private func populate() {
        guard let detail = viewModel.movieDetail else { return }

        title = detail.title
        titleLabel.text     = detail.title
        taglineLabel.text   = detail.tagline?.isEmpty == false ? "\"\(detail.tagline!)\"" : nil
        overviewLabel.text  = detail.overview.isEmpty ? "No overview available." : detail.overview
        genreLabel.text     = detail.genreNames.isEmpty ? "Genre N/A" : detail.genreNames
        ratingLabel.text    = "\(detail.formattedRating)"
        voteCountLabel.text = "(\(detail.voteCount) votes)"
        ratingStars.setRating(detail.voteAverage)

        backdropImageView.setImage(from: detail.backdropURL)
        posterImageView.setImage(from: detail.posterURL)
        populateInfoCard(detail: detail)
        setupGradientOnBackdrop()
    }

    private func setupGradientOnBackdrop() {
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            let grad = CAGradientLayer()
            grad.frame  = self.backdropGradient.bounds
            grad.colors = [UIColor.clear.cgColor, AppColors.background.cgColor]
            grad.startPoint = CGPoint(x: 0.5, y: 0)
            grad.endPoint   = CGPoint(x: 0.5, y: 1)
            self.backdropGradient.layer.sublayers?.forEach { $0.removeFromSuperlayer() }
            self.backdropGradient.layer.addSublayer(grad)
        }
    }

    // MARK: - Favorite Action
    @objc private func favoriteTapped() {
        viewModel.toggleFavorite()
    }

    private func updateFavoriteButton(_ isFav: Bool) {
        let imageName = isFav ? "heart.fill" : "heart"
        favoriteBarButton.image  = UIImage(systemName: imageName)
        favoriteBarButton.tintColor = isFav ? AppColors.accent : AppColors.primaryText
    }
}
