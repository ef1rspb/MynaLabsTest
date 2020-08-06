import UIKit

struct NavigationService {

  static var currentViewController: UIViewController? {
    return appWindow?.rootViewController
  }

  static var currentNavController: UINavigationController? {
    return appWindow?.rootViewController as? UINavigationController
  }
}

extension NavigationService {

  static var appWindow: UIWindow? {
    let app = UIApplication.shared
    var window = app.windows.first

    if window == nil {
      window = UIWindow(frame: UIScreen.main.bounds)
      (app.delegate as? AppDelegate)?.window = window
    }

    return window
  }
}
