import UIKit

final class HomeLayoutView: UIView {

  let thumbnailImageView = UIImageView()
  private let playView: UIView = {
    let imageView = UIImageView(image: UIImage(named: "play"))
    imageView.contentMode = .scaleAspectFit
    return imageView
  }()

  let shareVideoButton: UIButton
  let selectVideoButton: UIButton
  let recordVideoButton: UIButton

  override init(frame: CGRect) {
    shareVideoButton = Self.createButton(titled: "home_share_video_button_title".localized)
    selectVideoButton = Self.createButton(titled: "home_select_video_button_title".localized)
    recordVideoButton = Self.createButton(titled: "home_record_video_button_title".localized)

    super.init(frame: frame)

    backgroundColor = Colors.orage
    setupInitialLayout()
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  private func setupInitialLayout() {
    thumbnailImageView.addSubview(playView)
    playView.translatesAutoresizingMaskIntoConstraints = false
    NSLayoutConstraint.activate([
      playView.centerYAnchor.constraint(equalTo: thumbnailImageView.centerYAnchor),
      playView.centerXAnchor.constraint(equalTo: thumbnailImageView.centerXAnchor),
      playView.widthAnchor.constraint(equalTo: thumbnailImageView.widthAnchor, multiplier: 0.3, constant: 0),
      playView.heightAnchor.constraint(equalTo: thumbnailImageView.widthAnchor, multiplier: 0.3, constant: 0)
    ])

    addSubview(thumbnailImageView)
    thumbnailImageView.translatesAutoresizingMaskIntoConstraints = false
    NSLayoutConstraint.activate([
      thumbnailImageView.topAnchor.constraint(equalTo: safeAreaLayoutGuide.topAnchor),
      thumbnailImageView.leadingAnchor.constraint(equalTo: leadingAnchor),
      thumbnailImageView.trailingAnchor.constraint(equalTo: trailingAnchor),
      thumbnailImageView.heightAnchor.constraint(equalTo: heightAnchor, multiplier: 0.3, constant: 0)
    ])

    let stackView = UIStackView(arrangedSubviews: [shareVideoButton, recordVideoButton, selectVideoButton])
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

  private static func createButton(titled: String) -> UIButton {
    let button = UIButton()
    button.setTitle(titled, for: .normal)
    button.titleLabel?.textColor = .white
    button.layer.borderColor = UIColor.white.cgColor
    button.layer.borderWidth = 1.0
    button.layer.cornerRadius = 5;
    button.layer.masksToBounds = true;
    return button
  }
}
