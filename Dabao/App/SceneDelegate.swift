import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?

    // The first screen waits for two things: the splash animation and the app's start-up work.
    private var isSplashFinished = false
    private var isBootstrapFinished = false

    func scene(_ scene: UIScene,
               willConnectTo session: UISceneSession,
               options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = scene as? UIWindowScene else { return }

        DS.applyGlobalAppearance()

        // No storyboards here: we build the first screen in code.
        let window = UIWindow(windowScene: windowScene)
        self.window = window

        if LaunchOptions.skipSplash {
            isSplashFinished = true
            window.rootViewController = LaunchPlaceholderViewController()
        } else {
            window.rootViewController = SplashViewController { [weak self] in
                self?.isSplashFinished = true
                self?.showMainIfReady()
            }
        }
        window.makeKeyAndVisible()

        AppBootstrap.start { [weak self] _ in
            // If the catalogue failed to load, the Home tab shows the error and offers a retry.
            self?.isBootstrapFinished = true
            self?.showMainIfReady()
        }
    }

    func sceneDidEnterBackground(_ scene: UIScene) {
        PersistenceController.shared.flush()
    }

    private func showMainIfReady() {
        guard isSplashFinished, isBootstrapFinished, let window,
              !(window.rootViewController is MainTabBarController) else { return }

        let swap = { window.rootViewController = MainTabBarController() }
        if UIAccessibility.isReduceMotionEnabled {
            swap()
        } else {
            UIView.transition(with: window, duration: 0.25, options: .transitionCrossDissolve, animations: swap)
        }
    }
}

/// Shown instead of the splash when it's skipped, for the instant before the tab bar is ready.
private final class LaunchPlaceholderViewController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = DS.Color.background
    }
}
