import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?

    func scene(
        _ scene: UIScene,
        willConnectTo session: UISceneSession,
        options connectionOptions: UIScene.ConnectionOptions
    ) {
        guard let windowScene = (scene as? UIWindowScene) else { return }

        window = UIWindow(windowScene: windowScene)
        window?.rootViewController = createTabBarController()
        window?.makeKeyAndVisible()
    }

    // MARK: - Tab Bar Setup
    private func createTabBarController() -> UITabBarController {
        let tabBar = UITabBarController()

        let homeNav = makeNavController(
            root: HomeViewController(),
            title: "Discover",
            image: UIImage(systemName: "film"),
            selectedImage: UIImage(systemName: "film.fill")
        )

        let searchNav = makeNavController(
            root: SearchViewController(),
            title: "Search",
            image: UIImage(systemName: "magnifyingglass"),
            selectedImage: UIImage(systemName: "magnifyingglass")
        )

        let favoritesNav = makeNavController(
            root: FavoritesViewController(),
            title: "Favorites",
            image: UIImage(systemName: "heart"),
            selectedImage: UIImage(systemName: "heart.fill")
        )

        tabBar.viewControllers = [homeNav, searchNav, favoritesNav]
        tabBar.tabBar.tintColor = AppColors.accent
        tabBar.tabBar.backgroundColor = AppColors.surface

        styleTabBar(tabBar.tabBar)
        return tabBar
    }

    private func makeNavController(
        root: UIViewController,
        title: String,
        image: UIImage?,
        selectedImage: UIImage?
    ) -> UINavigationController {
        root.tabBarItem = UITabBarItem(title: title, image: image, selectedImage: selectedImage)
        let nav = UINavigationController(rootViewController: root)
        nav.navigationBar.prefersLargeTitles = true
        nav.navigationBar.tintColor = AppColors.accent
        styleNavigationBar(nav.navigationBar)
        return nav
    }

    private func styleNavigationBar(_ bar: UINavigationBar) {
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = AppColors.surface
        appearance.titleTextAttributes = [.foregroundColor: AppColors.primaryText]
        appearance.largeTitleTextAttributes = [.foregroundColor: AppColors.primaryText]
        bar.standardAppearance = appearance
        bar.scrollEdgeAppearance = appearance
    }

    private func styleTabBar(_ bar: UITabBar) {
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = AppColors.surface
        bar.standardAppearance = appearance
        if #available(iOS 15.0, *) {
            bar.scrollEdgeAppearance = appearance
        }
    }
}
