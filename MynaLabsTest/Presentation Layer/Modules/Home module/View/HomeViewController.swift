import UIKit
import MobileCoreServices

final class HomeViewController: UIViewController, ViewHolder {

  typealias RootViewType = HomeLayoutView

  var presenter: HomePresenter!
  private let picker = UIImagePickerController()

  override func loadView() {
    view = HomeLayoutView()
  }

  override func viewDidLoad() {
    super.viewDidLoad()

    configureButtons()
    configurePicker()
  }

  private func configureButtons() {
    rootView.selectVideoButton.addTarget(
      self, action:
      #selector(selectVideoButtonPressed),
      for: .touchUpInside
    )

    rootView.recordVideoButton.addTarget(
      self, action:
      #selector(recordVideoButtonPressed),
      for: .touchUpInside
    )
  }

  private func configurePicker() {
    picker.mediaTypes = [kUTTypeMovie as String]
    picker.delegate = self
  }

  @objc
  private func selectVideoButtonPressed() {
    presenter.selectVideoButtonPressed()
  }

  @objc
  private func recordVideoButtonPressed() {
    presenter.recordVideoButtonPressed()
  }
}

extension HomeViewController: HomeView {

  func showLibraryPicker() {
    picker.sourceType = .photoLibrary
    present(picker, animated: true, completion: nil)
  }

  func showCameraPicker() {
    picker.sourceType = .camera
    present(picker, animated: true, completion: nil)
  }

  func shareMedia(url: URL) {
    let activityViewController = UIActivityViewController(activityItems: [url], applicationActivities: nil)
    present(activityViewController, animated: true, completion: nil)
  }

  func showAvailableEffects(_ effects: [MLTAudioEffect]) {
    let alert = UIAlertController(title: "Choose audio effect", message: nil, preferredStyle: .actionSheet)

    effects.forEach { effect in
      let action = UIAlertAction(title: effect.title, style: .default) { [weak self] _ in
        self?.presenter.apply(effect: effect)
      }
      alert.addAction(action)
    }

    let cancel = UIAlertAction(title: "cancel", style: .cancel) { [weak self] _ in
      self?.dismiss(animated: true, completion: nil)
    }
    alert.addAction(cancel)

    present(alert, animated: true, completion: nil)
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
    presenter.selectedMedia(url: url)
  }
}
