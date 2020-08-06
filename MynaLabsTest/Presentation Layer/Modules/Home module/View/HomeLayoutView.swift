import UIKit

final class HomeLayoutView: UIView {

  let thumbnailImageView = UIImageView()

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

  let recordVideoButton: UIButton = {
    let button = UIButton()
    button.setTitle("home_record_video_button_title".localized, for: .normal)
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
    addSubview(thumbnailImageView)
    thumbnailImageView.translatesAutoresizingMaskIntoConstraints = false
    NSLayoutConstraint.activate([
      thumbnailImageView.topAnchor.constraint(equalTo: safeAreaLayoutGuide.topAnchor),
      thumbnailImageView.leadingAnchor.constraint(equalTo: leadingAnchor),
      thumbnailImageView.trailingAnchor.constraint(equalTo: trailingAnchor),
      thumbnailImageView.heightAnchor.constraint(equalTo: heightAnchor, multiplier: 0.7, constant: 0)
    ])

    let stackView = UIStackView(arrangedSubviews: [recordVideoButton, selectVideoButton])
    stackView.translatesAutoresizingMaskIntoConstraints = false
    stackView.spacing = Layout.padding
    stackView.axis = .vertical

    addSubview(stackView)
    NSLayoutConstraint.activate([
      stackView.bottomAnchor.constraint(equalTo: safeAreaLayoutGuide.bottomAnchor, constant: -Layout.padding),
      stackView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: Layout.padding),
      stackView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -Layout.padding)
    ])
  }
}
