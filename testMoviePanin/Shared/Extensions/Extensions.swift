import UIKit

// MARK: - UIColor Extension
extension UIColor {
    convenience init(hex: String) {
        var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        hexSanitized = hexSanitized.replacingOccurrences(of: "#", with: "")

        var rgb: UInt64 = 0
        Scanner(string: hexSanitized).scanHexInt64(&rgb)

        let r = CGFloat((rgb & 0xFF0000) >> 16) / 255
        let g = CGFloat((rgb & 0x00FF00) >> 8) / 255
        let b = CGFloat(rgb & 0x0000FF) / 255

        self.init(red: r, green: g, blue: b, alpha: 1.0)
    }
}

// MARK: - UIView Extension
extension UIView {
    func addShadow(
        color: UIColor = .black,
        opacity: Float = 0.3,
        offset: CGSize = CGSize(width: 0, height: 4),
        radius: CGFloat = 8
    ) {
        layer.shadowColor = color.cgColor
        layer.shadowOpacity = opacity
        layer.shadowOffset = offset
        layer.shadowRadius = radius
        layer.masksToBounds = false
    }

    func roundCorners(radius: CGFloat) {
        layer.cornerRadius = radius
        layer.masksToBounds = true
    }

    func addGradient(colors: [UIColor], startPoint: CGPoint = CGPoint(x: 0.5, y: 0),
                     endPoint: CGPoint = CGPoint(x: 0.5, y: 1)) {
        let gradient = CAGradientLayer()
        gradient.frame = bounds
        gradient.colors = colors.map { $0.cgColor }
        gradient.startPoint = startPoint
        gradient.endPoint = endPoint
        layer.insertSublayer(gradient, at: 0)
    }

    func animateTap(completion: (() -> Void)? = nil) {
        UIView.animate(
            withDuration: 0.1,
            animations: { self.transform = CGAffineTransform(scaleX: 0.95, y: 0.95) },
            completion: { _ in
                UIView.animate(withDuration: 0.1) {
                    self.transform = .identity
                } completion: { _ in completion?() }
            }
        )
    }
}

// MARK: - UIImageView Extension
extension UIImageView {
    func setImage(from urlString: String?, placeholder: UIImage? = nil) {
        image = placeholder ?? UIImage(systemName: "film")?.withTintColor(AppColors.secondaryText, renderingMode: .alwaysOriginal)

        guard let urlString = urlString, !urlString.isEmpty,
              let url = URL(string: urlString) else { return }

        ImageCacheManager.shared.loadImage(from: url) { [weak self] image in
            DispatchQueue.main.async {
                if let img = image {
                    UIView.transition(with: self ?? UIImageView(), duration: 0.25,
                                      options: .transitionCrossDissolve) {
                        self?.image = img
                    }
                }
            }
        }
    }
}

// MARK: - UIViewController Extension
extension UIViewController {
    func showAlert(title: String, message: String, retryAction: (() -> Void)? = nil) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: AppStrings.ok, style: .cancel))
        if let retry = retryAction {
            alert.addAction(UIAlertAction(title: AppStrings.retry, style: .default) { _ in retry() })
        }
        present(alert, animated: true)
    }

    func showLoading(_ activityIndicator: UIActivityIndicatorView) {
        activityIndicator.startAnimating()
    }

    func hideLoading(_ activityIndicator: UIActivityIndicatorView) {
        activityIndicator.stopAnimating()
    }
}

// MARK: - String Extension
extension String {
    func toYear() -> String {
        let input = DateFormatter()
        input.dateFormat = "yyyy-MM-dd"
        let output = DateFormatter()
        output.dateFormat = "yyyy"
        if let date = input.date(from: self) {
            return output.string(from: date)
        }
        return self
    }

    func toFormattedDate() -> String {
        let input = DateFormatter()
        input.dateFormat = "yyyy-MM-dd"
        let output = DateFormatter()
        output.dateFormat = "dd MMM yyyy"
        if let date = input.date(from: self) {
            return output.string(from: date)
        }
        return self
    }
}

// MARK: - Int Extension
extension Int {
    func toRuntimeString() -> String {
        guard self > 0 else { return "N/A" }
        let hours = self / 60
        let minutes = self % 60
        if hours == 0 { return "\(minutes)m" }
        return "\(hours)h \(minutes)m"
    }
}

// MARK: - Double Extension
extension Double {
    func toRatingString() -> String {
        return String(format: "%.1f", self)
    }
}
