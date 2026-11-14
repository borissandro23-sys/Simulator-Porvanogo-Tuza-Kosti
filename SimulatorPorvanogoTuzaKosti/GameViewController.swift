import UIKit

final class GameViewController: UIViewController {
    private let titleLabel = UILabel()
    private let subtitleLabel = UILabel()
    private let cardView = AceCardView()
    private let progressView = UIProgressView(progressViewStyle: .default)
    private let tearButton = UIButton(type: .system)
    private let resetButton = UIButton(type: .system)
    private let scoreLabel = UILabel()

    private let tapsToTear = 25
    private var taps = 0
    private var tornAces = 0

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor(red: 0.07, green: 0.09, blue: 0.14, alpha: 1)
        buildInterface()
        updateProgress()
    }

    private func buildInterface() {
        titleLabel.text = "Симулятор порванного туза Кости"
        titleLabel.font = .systemFont(ofSize: 27, weight: .heavy)
        titleLabel.textColor = .white
        titleLabel.textAlignment = .center
        titleLabel.numberOfLines = 0

        subtitleLabel.text = "Нажимай на кнопку, чтобы порвать туз!"
        subtitleLabel.font = .systemFont(ofSize: 16, weight: .medium)
        subtitleLabel.textColor = .lightGray
        subtitleLabel.textAlignment = .center
        subtitleLabel.numberOfLines = 0

        progressView.progressTintColor = .systemOrange
        progressView.trackTintColor = UIColor.white.withAlphaComponent(0.15)
        progressView.layer.cornerRadius = 5
        progressView.clipsToBounds = true

        tearButton.setTitle("✂️  ПОРВАТЬ ТУЗ", for: .normal)
        tearButton.titleLabel?.font = .systemFont(ofSize: 19, weight: .bold)
        tearButton.setTitleColor(.white, for: .normal)
        tearButton.backgroundColor = .systemOrange
        tearButton.layer.cornerRadius = 16
        tearButton.contentEdgeInsets = UIEdgeInsets(top: 17, left: 24, bottom: 17, right: 24)
        tearButton.addTarget(self, action: #selector(tear), for: .touchUpInside)

        resetButton.setTitle("Начать заново", for: .normal)
        resetButton.setTitleColor(.systemGray2, for: .normal)
        resetButton.titleLabel?.font = .systemFont(ofSize: 15, weight: .semibold)
        resetButton.addTarget(self, action: #selector(resetGame), for: .touchUpInside)

        scoreLabel.textColor = .white
        scoreLabel.font = .systemFont(ofSize: 17, weight: .semibold)
        scoreLabel.textAlignment = .center

        let stack = UIStackView(arrangedSubviews: [
            titleLabel, subtitleLabel, cardView, progressView,
            tearButton, scoreLabel, resetButton
        ])
        stack.axis = .vertical
        stack.alignment = .fill
        stack.spacing = 20
        stack.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(stack)

        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 22),
            stack.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -22),
            stack.centerYAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerYAnchor),
            cardView.heightAnchor.constraint(equalToConstant: 300),
            progressView.heightAnchor.constraint(equalToConstant: 10),
            tearButton.heightAnchor.constraint(equalToConstant: 58)
        ])
    }

    @objc private func tear() {
        guard taps < tapsToTear else { return }
        taps += 1
        cardView.setDamage(taps: taps, total: tapsToTear)
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        updateProgress()

        if taps == tapsToTear {
            tornAces += 1
            cardView.tearApart {
                self.scoreLabel.text = "Порвано тузов: \(self.tornAces) 🎉"
                self.tearButton.setTitle("ЕЩЁ ОДИН ТУЗ", for: .normal)
            }
        }
    }

    @objc private func resetGame() {
        taps = 0
        cardView.resetCard()
        tearButton.setTitle("✂️  ПОРВАТЬ ТУЗ", for: .normal)
        updateProgress()
    }

    private func updateProgress() {
        progressView.setProgress(Float(taps) / Float(tapsToTear), animated: true)
        scoreLabel.text = "Прогресс: \(taps) / \(tapsToTear)"
        if taps == tapsToTear {
            scoreLabel.text = "Туз порван! Всего: \(tornAces) 🎉"
        }
    }
}

private final class AceCardView: UIView {
    private let card = UIView()
    private let aceLabel = UILabel()
    private let suitLabel = UILabel()
    private let crackLayer = CAShapeLayer()

    override init(frame: CGRect) {
        super.init(frame: frame)
        translatesAutoresizingMaskIntoConstraints = false
        card.backgroundColor = UIColor(red: 0.98, green: 0.97, blue: 0.92, alpha: 1)
        card.layer.cornerRadius = 18
        card.layer.shadowColor = UIColor.black.cgColor
        card.layer.shadowOpacity = 0.35
        card.layer.shadowRadius = 18
        card.layer.shadowOffset = CGSize(width: 0, height: 10)
        card.translatesAutoresizingMaskIntoConstraints = false
        addSubview(card)

        aceLabel.text = "A"
        aceLabel.font = .systemFont(ofSize: 58, weight: .black)
        aceLabel.textColor = .systemRed
        aceLabel.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(aceLabel)

        suitLabel.text = "♥"
        suitLabel.font = .systemFont(ofSize: 112, weight: .regular)
        suitLabel.textColor = .systemRed
        suitLabel.textAlignment = .center
        suitLabel.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(suitLabel)

        crackLayer.strokeColor = UIColor.black.withAlphaComponent(0.8).cgColor
        crackLayer.lineWidth = 3
        crackLayer.lineCap = .round
        card.layer.addSublayer(crackLayer)

        NSLayoutConstraint.activate([
            card.centerXAnchor.constraint(equalTo: centerXAnchor),
            card.centerYAnchor.constraint(equalTo: centerYAnchor),
            card.widthAnchor.constraint(equalToConstant: 190),
            card.heightAnchor.constraint(equalToConstant: 270),
            aceLabel.topAnchor.constraint(equalTo: card.topAnchor, constant: 12),
            aceLabel.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 16),
            suitLabel.centerXAnchor.constraint(equalTo: card.centerXAnchor),
            suitLabel.centerYAnchor.constraint(equalTo: card.centerYAnchor, constant: 15)
        ])
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    func setDamage(taps: Int, total: Int) {
        let alpha = CGFloat(taps) / CGFloat(total)
        crackLayer.frame = card.bounds
        let path = UIBezierPath()
        path.move(to: CGPoint(x: card.bounds.midX, y: 80))
        path.addLine(to: CGPoint(x: card.bounds.midX - 12, y: 115))
        path.addLine(to: CGPoint(x: card.bounds.midX + 9, y: 145))
        path.addLine(to: CGPoint(x: card.bounds.midX - 8, y: 180))
        crackLayer.path = path.cgPath
        crackLayer.opacity = Float(alpha)
        card.transform = CGAffineTransform(rotationAngle: CGFloat.random(in: -0.025...0.025))
    }

    func tearApart(completion: @escaping () -> Void) {
        UIView.animate(withDuration: 0.55, animations: {
            self.card.transform = CGAffineTransform(translationX: -42, y: 12).rotated(by: -0.16)
            self.card.alpha = 0.35
        }) { _ in
            completion()
        }
    }

    func resetCard() {
        UIView.animate(withDuration: 0.25) {
            self.card.transform = .identity
            self.card.alpha = 1
            self.crackLayer.opacity = 0
        }
    }
}
