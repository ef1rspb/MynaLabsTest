import Foundation
import UIKit.UIImage

protocol HomeView: class {
  func setInitialState()
  func showLibraryPicker()
  func showCameraPicker()
  func shareMedia(url: URL)
  func showAvailableEffects(_ effects: [MLTAudioEffect])
  func playVideo(url: URL)
  func setShareState(thumnailPreview: UIImage?)
  func showError(message: String)
}

protocol HomePresenter {
  func viewDidLoad()
  func shareVideoButtonPressed()
  func selectVideoButtonPressed()
  func recordVideoButtonPressed()
  func thumbnailPressed()
  func selectedMedia(url: URL)
  func apply(effect: MLTAudioEffect)
}

final class HomePresenterImpl: HomePresenter {

  private weak var view: HomeView?
  private var currentVideoUrl: URL?
  private let audioEffectProcessor: AudioEffectProcessor
  private let videoPreviewGenerator: VideoPreviewGenerator

  init(
    view: HomeView,
    audioEffectProcessor: AudioEffectProcessor,
    videoPreviewGenerator: VideoPreviewGenerator
  ) {
    self.view = view
    self.audioEffectProcessor = audioEffectProcessor
    self.videoPreviewGenerator = videoPreviewGenerator
  }

  func viewDidLoad() {
    view?.setInitialState()
  }

  func shareVideoButtonPressed() {
    guard let url = currentVideoUrl else { return }
    view?.shareMedia(url: url)
  }

  func selectVideoButtonPressed() {
    view?.showLibraryPicker()
  }

  func recordVideoButtonPressed() {
    view?.showCameraPicker()
  }

  func thumbnailPressed() {
    guard let url = currentVideoUrl else { return }
    view?.playVideo(url: url)
  }

  func selectedMedia(url: URL) {
    currentVideoUrl = url
    view?.showAvailableEffects([.reverb, .delay, .distortion])
  }

  func apply(effect: MLTAudioEffect) {
    guard let url = currentVideoUrl else { return }
    view?.setInitialState()

    audioEffectProcessor.apply(effect: effect, toVideo: url) { [weak self] result in
      DispatchQueue.main.async { [weak self] in
        switch result {
          case let .success(url):
            let thumnail = self?.videoPreviewGenerator.thumbnail(for: url)
            self?.view?.setShareState(thumnailPreview: thumnail)
          case let .failure(error):
            self?.view?.showError(message: error.localizedDescription)
        }
      }
    }
  }

}
