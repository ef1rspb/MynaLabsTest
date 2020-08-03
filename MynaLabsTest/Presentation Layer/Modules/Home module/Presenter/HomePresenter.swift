import Foundation

protocol HomePresenter {

  func selectVideoButtonPressed()
}

final class HomePresenterImpl: HomePresenter {

  func selectVideoButtonPressed() {
    print("asdasd")
  }
}
