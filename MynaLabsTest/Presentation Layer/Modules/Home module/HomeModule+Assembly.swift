import UIKit

extension NavigationService {

  static func makeHomeModule() -> UIViewController {
    let vc = HomeViewController()
    let audioEffectProcessor = AudioEffectProcessorImpl()
    let presenter = HomePresenterImpl(view: vc, audioEffectProcessor: audioEffectProcessor)
    vc.presenter = presenter
    return vc
  }
}
