import UIKit

final class HomeLayoutView: UIView {

  let selectVideoButton: UIButton = {
    let button = UIButton()
    button.setTitle("home_select_video_button_title".localized, for: .normal)
    button.titleLabel?.textColor = .white
    button.layer.borderColor = UIColor.white.cgColor
    button.layer.borderWidth = 1.0
    button.layer.cornerRadius = 5;
    button.layer.masksToBounds = true;
    return button
  }()

  override init(frame: CGRect) {
    super.init(frame: frame)

    backgroundColor = Colors.orage
    setupInitialLayout()
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  private func setupInitialLayout() {
    let stackView = UIStackView(arrangedSubviews: [selectVideoButton])
    stackView.translatesAutoresizingMaskIntoConstraints = false
    stackView.axis = .vertical

    addSubview(stackView)
    NSLayoutConstraint.activate([
      stackView.bottomAnchor.constraint(equalTo: safeAreaLayoutGuide.bottomAnchor),
      stackView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: Layout.padding),
      stackView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -Layout.padding),
      selectVideoButton.heightAnchor.constraint(equalToConstant: Layout.butttonHeight)
    ])
  }
}
