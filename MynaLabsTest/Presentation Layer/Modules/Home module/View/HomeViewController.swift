import UIKit
import MobileCoreServices

final class HomeViewController: UIViewController, HomeView, ViewHolder {

  typealias RootViewType = HomeLayoutView

  var presenter: HomePresenter!
  private let picker = UIImagePickerController()

  override func loadView() {
    view = HomeLayoutView()
  }

  override func viewDidLoad() {
    super.viewDidLoad()

    configureButtons()
    picker.mediaTypes = [kUTTypeMovie as String]
    picker.delegate = self
  }

  private func configureButtons() {
    rootView.selectVideoButton.addTarget(
      self, action:
      #selector(selectVideoButtonPressed),
      for: .touchUpInside
    )

    rootView.recordVideoButton.addTarget(
      self, action:
      #selector(showCameraPicker),
      for: .touchUpInside
    )
  }

  @objc
  private func selectVideoButtonPressed() {
    //presenter.selectVideoButtonPressed()
    showImagePicker()
  }

  private func showImagePicker() {
    picker.sourceType = .photoLibrary
    present(picker, animated: true, completion: nil)
  }

  @objc
  private func showCameraPicker() {
    picker.sourceType = .camera
    present(picker, animated: true, completion: nil)
  }

  func shareAudio(url: URL) {
    let activityViewController = UIActivityViewController(activityItems: [url], applicationActivities: nil)
    present(activityViewController, animated: true, completion: nil)
  }
}

extension HomeViewController: UINavigationControllerDelegate {

}

extension HomeViewController: UIImagePickerControllerDelegate {

  @objc
  func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
    dismiss(animated: true, completion: nil)
  }

  @objc
  func imagePickerController(
    _ picker: UIImagePickerController,
    didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]
  ) {
    dismiss(animated: true, completion: nil)
    guard
      let mediaType = info[.mediaType] as? String,
      mediaType == (kUTTypeMovie as String),
      let url = info[.mediaURL] as? URL
      else { return }
    presenter.loadVideo(by: url)
  }
}
