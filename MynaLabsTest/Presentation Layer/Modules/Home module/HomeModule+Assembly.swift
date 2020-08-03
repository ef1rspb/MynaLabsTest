import UIKit

extension NavigationService {

  static func makeHomeModule() -> UIViewController {
    let presenter = HomePresenterImpl()
    let vc = HomeViewController()
    vc.presenter = presenter
    return vc
  }
}
