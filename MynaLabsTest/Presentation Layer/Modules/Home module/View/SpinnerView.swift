import UIKit

protocol SpinnerView where Self: UIView {
  func start()
  func stop()
}

extension UIActivityIndicatorView: SpinnerView {

  func start() {
    startAnimating()
  }

  func stop() {
    stopAnimating()
  }
}
