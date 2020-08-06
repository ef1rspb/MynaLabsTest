import Foundation

protocol HomeView: class {
  func showLibraryPicker()
  func showCameraPicker()
  func shareMedia(url: URL)
  func showAvailableEffects(_ effects: [MLTAudioEffect])
  func showError(message: String)
}

protocol HomePresenter {
  func selectVideoButtonPressed()
  func recordVideoButtonPressed()
  func selectedMedia(url: URL)
  func apply(effect: MLTAudioEffect)
}

final class HomePresenterImpl: HomePresenter {

  private weak var view: HomeView?
  private var currentVideoUrl: URL?
  private let audioEffectProcessor: AudioEffectProcessor

  init(view: HomeView, audioEffectProcessor: AudioEffectProcessor) {
    self.view = view
    self.audioEffectProcessor = audioEffectProcessor
  }

  func selectVideoButtonPressed() {
    view?.showLibraryPicker()
  }

  func recordVideoButtonPressed() {
    view?.showCameraPicker()
  }
  
  func selectedMedia(url: URL) {
    currentVideoUrl = url
    view?.showAvailableEffects([.reverb, .delay, .distortion])
  }

  func apply(effect: MLTAudioEffect) {
    guard let url = currentVideoUrl else { return }

    audioEffectProcessor.apply(effect: effect, toVideo: url) { [weak self] result in
      self?.currentVideoUrl = nil
      DispatchQueue.main.async { [weak self] in
        switch result {
          case let .success(url):
            self?.view?.shareMedia(url: url)
          case let .failure(error):
            self?.view?.showError(message: error.localizedDescription)
        }
      }
    }
  }

}
