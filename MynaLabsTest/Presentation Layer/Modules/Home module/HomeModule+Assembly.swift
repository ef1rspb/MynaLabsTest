import UIKit

extension NavigationService {

  static func makeHomeModule() -> UIViewController {
    let viewController = HomeViewController()
    let presenter = HomePresenterImpl(
      view: viewController,
      audioEffectProcessor: AudioEffectProcessorImpl(),
      videoPreviewGenerator: DefaultVideoPreviewGenerator()
    )
    viewController.presenter = presenter
    return viewController
  }
}
