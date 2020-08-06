import UIKit
import MobileCoreServices
import AVKit

final class HomeViewController: UIViewController, ViewHolder {

  typealias RootViewType = HomeLayoutView

  var presenter: HomePresenter!
  private let picker = UIImagePickerController()
  private lazy var playerViewController: AVPlayerViewController = {
    let player = AVPlayer()
    let playerViewController = AVPlayerViewController()
    playerViewController.player = player
    return playerViewController
  }()

  override func loadView() {
    view = HomeLayoutView()
  }

  override func viewDidLoad() {
    super.viewDidLoad()

    presenter.viewDidLoad()
    configureButtons()
    configurePicker()
  }

  private func configureButtons() {
    rootView.shareVideoButton.addTarget(
      self, action:
      #selector(shareVideoButtonPressed),
      for: .touchUpInside
    )

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

    let tapRecognizer = UITapGestureRecognizer(target: self, action: #selector(thumbnailViewPressed))
    rootView.thumbnailImageView.isUserInteractionEnabled = true
    rootView.thumbnailImageView.addGestureRecognizer(tapRecognizer)
  }

  private func configurePicker() {
    picker.mediaTypes = [kUTTypeMovie as String]
    picker.delegate = self
  }

  @objc
  private func thumbnailViewPressed() {
    presenter.thumbnailPressed()
  }

  @objc
  private func shareVideoButtonPressed() {
    presenter.shareVideoButtonPressed()
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

  func setInitialState() {
    rootView.thumbnailImageView.isHidden = true
    rootView.shareVideoButton.isHidden = true
  }

  func showLibraryPicker() {
    picker.sourceType = .photoLibrary
    present(picker, animated: true, completion: nil)
  }

  func showCameraPicker() {
    picker.sourceType = .camera
    present(picker, animated: true, completion: nil)
  }

  func setShareState(thumnailPreview: UIImage?) {
    rootView.thumbnailImageView.image = thumnailPreview
    rootView.thumbnailImageView.isHidden = false
    rootView.shareVideoButton.isHidden = false
  }

  func playVideo(url: URL) {
    playerViewController.player!.replaceCurrentItem(with: .init(url: url))
    present(playerViewController, animated: true) {
      self.playerViewController.player!.play()
    }
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

  func showError(message: String) {
    let alert = UIAlertController(title: "Something went wrong", message: message, preferredStyle: .alert)
    let okAktion = UIAlertAction(title: "OK", style: .default) { [weak self] _ in
      self?.dismiss(animated: true, completion: nil)
    }
    alert.addAction(okAktion)
    present(alert, animated: true, completion: nil)
  }

  func startProcessingAnimation() {
    rootView.spinnerView.start()
  }

  func stopProcessingAnimation() {
    rootView.spinnerView.stop()
  }
}

extension HomeViewController: UINavigationControllerDelegate {}

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
