import UIKit

final class HomeViewController: UIViewController, ViewHolder {

  typealias RootViewType = HomeView

  var presenter: HomePresenter!

  override func loadView() {
    view = HomeView()
  }

  override func viewDidLoad() {
    super.viewDidLoad()

    print("hello")
  }
}
