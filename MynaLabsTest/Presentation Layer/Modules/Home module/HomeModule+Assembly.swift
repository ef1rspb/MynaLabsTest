import UIKit

extension NavigationService {

  static func makeHomeModule() -> UIViewController {
    let viewController = HomeViewController()
    let presenter = HomePresenterImpl(
      view: viewController,
      audioEffectProcessor: AudioEffectProcessorImpl(),
      videoPreviewGenerator: DefailtVideoPreviewGenerator()
    )
    viewController.presenter = presenter
    return viewController
  }
}
