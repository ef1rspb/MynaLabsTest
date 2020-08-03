import UIKit
import MobileCoreServices

final class HomeViewController: UIViewController, ViewHolder {

  typealias RootViewType = HomeLayoutView

  var presenter: HomePresenter!

  override func loadView() {
    view = HomeLayoutView()
  }

  override func viewDidLoad() {
    super.viewDidLoad()

    configureButtons()
  }

  private func configureButtons() {
    rootView.selectVideoButton.addTarget(
      self, action:
      #selector(selectVideoButtonPressed),
      for: .touchUpInside
    )
  }

  @objc
  private func selectVideoButtonPressed() {
    //presenter.selectVideoButtonPressed()
    showImagePicker()
  }

  private func showImagePicker() {
    let picker = UIImagePickerController()
    picker.sourceType = .photoLibrary
    picker.mediaTypes = [kUTTypeMovie as String]
    picker.delegate = self
    present(picker, animated: true, completion: nil)
  }

}

extension HomeViewController: UINavigationControllerDelegate {

}

extension HomeViewController: UIImagePickerControllerDelegate {

  func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
    dismiss(animated: true, completion: nil)
  }

  func imagePickerController(
    _ picker: UIImagePickerController,
    didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]
  ) {
    dismiss(animated: true, completion: nil)
  }
}
