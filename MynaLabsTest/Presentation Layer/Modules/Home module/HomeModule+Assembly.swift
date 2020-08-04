import UIKit

extension NavigationService {

  static func makeHomeModule() -> UIViewController {
    let vc = HomeViewController()
    let presenter = HomePresenterImpl(view: vc)
    vc.presenter = presenter
    return vc
  }
}
