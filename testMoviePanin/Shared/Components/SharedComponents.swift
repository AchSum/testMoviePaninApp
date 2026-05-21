import UIKit
import SnapKit

// MARK: - MovieCardCell
final class MovieCardCell: UICollectionViewCell {

    static let reuseIdentifier = "MovieCardCell"

    // MARK: - UI Elements
    private let posterImageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
        iv.backgroundColor = AppColors.card
        return iv
    }()

    private let gradientOverlay: UIView = {
        let v = UIView()
        return v
    }()

    private let titleLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 13, weight: .semibold)
        l.textColor = AppColors.primaryText
        l.numberOfLines = 2
        return l
    }()

    private let ratingView: UIView = {
        let v = UIView()
        v.backgroundColor = UIColor.black.withAlphaComponent(0.6)
        v.layer.cornerRadius = 10
        return v
    }()

    private let starIcon: UIImageView = {
        let iv = UIImageView(image: UIImage(systemName: "star.fill"))
        iv.tintColor = AppColors.starColor
        return iv
    }()

    private let ratingLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 10, weight: .bold)
        l.textColor = AppColors.primaryText
        return l
    }()

    private let yearLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 11)
        l.textColor = AppColors.secondaryText
        return l
    }()

    private let favoriteButton: UIButton = {
        let btn = UIButton(type: .system)
        btn.setImage(UIImage(systemName: "heart.fill"), for: .normal)
        btn.tintColor = AppColors.accent
        btn.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        btn.layer.cornerRadius = 14
        return btn
    }()

    var onFavoriteTapped: (() -> Void)?
    private var isFavorite: Bool = false

    // MARK: - Init
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) { fatalError() }

    // MARK: - Setup
    private func setupUI() {
        contentView.backgroundColor = AppColors.card
        contentView.layer.cornerRadius = LayoutConstants.cardRadius
        contentView.clipsToBounds = true
        addShadow(color: .black, opacity: 0.4, offset: CGSize(width: 0, height: 6), radius: 10)

        contentView.addSubview(posterImageView)
        contentView.addSubview(gradientOverlay)
        contentView.addSubview(ratingView)
        ratingView.addSubview(starIcon)
        ratingView.addSubview(ratingLabel)
        contentView.addSubview(favoriteButton)
        contentView.addSubview(titleLabel)
        contentView.addSubview(yearLabel)

        setupConstraints()
        setupGradient()

        favoriteButton.addTarget(self, action: #selector(favoriteTapped), for: .touchUpInside)
    }

    private func setupConstraints() {
        posterImageView.snp.makeConstraints {
            $0.top.left.right.equalToSuperview()
            $0.height.equalTo(contentView.snp.height).multipliedBy(0.68)
        }

        gradientOverlay.snp.makeConstraints {
            $0.edges.equalTo(posterImageView)
        }

        ratingView.snp.makeConstraints {
            $0.top.equalToSuperview().offset(8)
            $0.left.equalToSuperview().offset(8)
            $0.height.equalTo(20)
        }

        starIcon.snp.makeConstraints {
            $0.left.equalToSuperview().offset(6)
            $0.centerY.equalToSuperview()
            $0.size.equalTo(CGSize(width: 10, height: 10))
        }

        ratingLabel.snp.makeConstraints {
            $0.left.equalTo(starIcon.snp.right).offset(3)
            $0.right.equalToSuperview().inset(6)
            $0.centerY.equalToSuperview()
        }

        favoriteButton.snp.makeConstraints {
            $0.top.equalToSuperview().offset(8)
            $0.right.equalToSuperview().inset(8)
            $0.size.equalTo(CGSize(width: 28, height: 28))
        }

        titleLabel.snp.makeConstraints {
            $0.top.equalTo(posterImageView.snp.bottom).offset(8)
            $0.left.right.equalToSuperview().inset(8)
        }

        yearLabel.snp.makeConstraints {
            $0.top.equalTo(titleLabel.snp.bottom).offset(4)
            $0.left.equalToSuperview().inset(8)
        }
    }

    private func setupGradient() {
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            let gradientLayer = CAGradientLayer()
            gradientLayer.frame = self.posterImageView.bounds
            gradientLayer.colors = [
                UIColor.clear.cgColor,
                UIColor.black.withAlphaComponent(0.5).cgColor
            ]
            gradientLayer.startPoint = CGPoint(x: 0.5, y: 0.5)
            gradientLayer.endPoint   = CGPoint(x: 0.5, y: 1.0)
            self.gradientOverlay.layer.addSublayer(gradientLayer)
        }
    }

    // MARK: - Configure
    func configure(with movie: Movie, isFavorite: Bool = false) {
        titleLabel.text    = movie.title
        ratingLabel.text   = movie.formattedRating
        yearLabel.text     = movie.releaseYear
        self.isFavorite    = isFavorite
        posterImageView.setImage(from: movie.posterURL)
        updateFavoriteButton()
    }

    func updateFavorite(_ isFav: Bool) {
        self.isFavorite = isFav
        updateFavoriteButton()
    }

    private func updateFavoriteButton() {
        let imageName = isFavorite ? "heart.fill" : "heart"
        favoriteButton.setImage(UIImage(systemName: imageName), for: .normal)
        favoriteButton.tintColor = isFavorite ? AppColors.accent : .white
    }

    @objc private func favoriteTapped() {
        animateTap()
        isFavorite.toggle()
        updateFavoriteButton()
        onFavoriteTapped?()
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        posterImageView.image = nil
        titleLabel.text = nil
        ratingLabel.text = nil
        yearLabel.text = nil
    }
}

// MARK: - LoadingView
final class LoadingView: UIView {

    private let spinner: UIActivityIndicatorView = {
        let s = UIActivityIndicatorView(style: .large)
        s.color = AppColors.accent
        return s
    }()

    private let label: UILabel = {
        let l = UILabel()
        l.text = "Loading..."
        l.font = .systemFont(ofSize: 14)
        l.textColor = AppColors.secondaryText
        return l
    }()

    init() {
        super.init(frame: .zero)
        setupUI()
    }

    required init?(coder: NSCoder) { fatalError() }

    private func setupUI() {
        let stack = UIStackView(arrangedSubviews: [spinner, label])
        stack.axis = .vertical
        stack.spacing = 12
        stack.alignment = .center

        addSubview(stack)
        stack.snp.makeConstraints { $0.center.equalToSuperview() }
    }

    func startAnimating() {
        isHidden = false
        spinner.startAnimating()
    }

    func stopAnimating() {
        isHidden = true
        spinner.stopAnimating()
    }
}

// MARK: - EmptyStateView
final class EmptyStateView: UIView {

    private let iconLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 60)
        l.textAlignment = .center
        return l
    }()

    private let titleLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 18, weight: .semibold)
        l.textColor = AppColors.primaryText
        l.textAlignment = .center
        return l
    }()

    private let subtitleLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 14)
        l.textColor = AppColors.secondaryText
        l.textAlignment = .center
        l.numberOfLines = 2
        return l
    }()

    init(icon: String, title: String, subtitle: String) {
        super.init(frame: .zero)
        iconLabel.text     = icon
        titleLabel.text    = title
        subtitleLabel.text = subtitle
        setupUI()
    }

    required init?(coder: NSCoder) { fatalError() }

    private func setupUI() {
        let stack = UIStackView(arrangedSubviews: [iconLabel, titleLabel, subtitleLabel])
        stack.axis = .vertical
        stack.spacing = 12
        stack.alignment = .center

        addSubview(stack)
        stack.snp.makeConstraints {
            $0.center.equalToSuperview()
            $0.left.right.equalToSuperview().inset(32)
        }
    }
}

// MARK: - GenreChipCell
final class GenreChipCell: UICollectionViewCell {

    static let reuseIdentifier = "GenreChipCell"

    private let label: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 13, weight: .medium)
        l.textAlignment = .center
        return l
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.addSubview(label)
        contentView.layer.cornerRadius = 14
        contentView.layer.borderWidth  = 1

        label.snp.makeConstraints {
            $0.edges.equalToSuperview().inset(UIEdgeInsets(top: 6, left: 12, bottom: 6, right: 12))
        }
    }

    required init?(coder: NSCoder) { fatalError() }

    func configure(with title: String, isSelected: Bool) {
        label.text = title
        if isSelected {
            contentView.backgroundColor = AppColors.accent
            contentView.layer.borderColor = AppColors.accent.cgColor
            label.textColor = .white
        } else {
            contentView.backgroundColor = .clear
            contentView.layer.borderColor = AppColors.secondaryText.cgColor
            label.textColor = AppColors.secondaryText
        }
    }
}

// MARK: - RatingStarsView
final class RatingStarsView: UIView {

    private let stackView: UIStackView = {
        let s = UIStackView()
        s.axis = .horizontal
        s.spacing = 2
        return s
    }()

    init() {
        super.init(frame: .zero)
        addSubview(stackView)
        stackView.snp.makeConstraints { $0.edges.equalToSuperview() }
        for _ in 0..<5 {
            let star = UIImageView(image: UIImage(systemName: "star.fill"))
            star.tintColor = AppColors.secondaryText
            star.snp.makeConstraints { $0.size.equalTo(CGSize(width: 14, height: 14)) }
            stackView.addArrangedSubview(star)
        }
    }

    required init?(coder: NSCoder) { fatalError() }

    func setRating(_ rating: Double) {
        let filled = Int(rating / 2)
        stackView.arrangedSubviews.enumerated().forEach { index, view in
            guard let star = view as? UIImageView else { return }
            star.tintColor = index < filled ? AppColors.starColor : AppColors.secondaryText
        }
    }
}
