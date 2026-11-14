import UIKit

final class GameViewController: UIViewController {
    private let titleLabel = UILabel()
    private let subtitleLabel = UILabel()
    private let cardView = AceCardView()
    private let progressView = UIProgressView(progressViewStyle: .default)
    private let tearButton = UIButton(type: .system)
    private let coinsLabel = UILabel()
    private let statsLabel = UILabel()
    private let levelLabel = UILabel()
    private let achievementLabel = UILabel()
    private let powerButton = UIButton(type: .system)
    private let autoButton = UIButton(type: .system)
    private let bonusButton = UIButton(type: .system)
    private let prestigeButton = UIButton(type: .system)

    private let defaults = UserDefaults.standard
    private var damage = 0
    private var coins = 0
    private var tornAces = 0
    private var lifetimeAces = 0
    private var prestige = 0
    private var damageNeeded: Int { 100 + (lifetimeAces / 10) * 25 }
    private var coinMultiplier: Int { 1 + prestige / 2 }
    private var tapPower = 1
    private var autoPower = 0
    private var tearBonus = 0
    private var autoTimer: Timer?

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor(red: 0.07, green: 0.09, blue: 0.14, alpha: 1)
        loadProgress()
        buildInterface()
        updateInterface()
        autoTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            self?.applyAutoDamage()
        }
        NotificationCenter.default.addObserver(self, selector: #selector(saveProgress), name: UIApplication.willResignActiveNotification, object: nil)
    }

    deinit {
        autoTimer?.invalidate()
        NotificationCenter.default.removeObserver(self)
    }

    private func buildInterface() {
        titleLabel.text = "Симулятор порванного туза Кости"
        titleLabel.font = .systemFont(ofSize: 26, weight: .heavy)
        titleLabel.textColor = .white
        titleLabel.textAlignment = .center
        titleLabel.numberOfLines = 0

        subtitleLabel.text = "Прокачивай силу и рви тузы быстрее!"
        subtitleLabel.font = .systemFont(ofSize: 15, weight: .medium)
        subtitleLabel.textColor = .lightGray
        subtitleLabel.textAlignment = .center
        subtitleLabel.numberOfLines = 0

        coinsLabel.font = .systemFont(ofSize: 21, weight: .bold)
        coinsLabel.textColor = .systemYellow
        coinsLabel.textAlignment = .center

        levelLabel.font = .systemFont(ofSize: 16, weight: .semibold)
        levelLabel.textColor = .white
        levelLabel.textAlignment = .center

        progressView.progressTintColor = .systemOrange
        progressView.trackTintColor = UIColor.white.withAlphaComponent(0.15)
        progressView.layer.cornerRadius = 5
        progressView.clipsToBounds = true

        configureButton(tearButton, title: "✂️  ПОРВАТЬ ТУЗ", color: .systemOrange, size: 19)
        tearButton.addTarget(self, action: #selector(tear), for: .touchUpInside)

        configureButton(powerButton, title: "", color: UIColor(red: 0.18, green: 0.38, blue: 0.68, alpha: 1), size: 15)
        configureButton(autoButton, title: "", color: UIColor(red: 0.24, green: 0.48, blue: 0.38, alpha: 1), size: 15)
        configureButton(bonusButton, title: "", color: UIColor(red: 0.48, green: 0.30, blue: 0.62, alpha: 1), size: 15)
        powerButton.addTarget(self, action: #selector(buyPower), for: .touchUpInside)
        autoButton.addTarget(self, action: #selector(buyAuto), for: .touchUpInside)
        bonusButton.addTarget(self, action: #selector(buyBonus), for: .touchUpInside)
        configureButton(prestigeButton, title: "", color: UIColor(red: 0.55, green: 0.32, blue: 0.18, alpha: 1), size: 15)
        prestigeButton.addTarget(self, action: #selector.performPrestige), for: .touchUpInside)

        statsLabel.font = .systemFont(ofSize: 15, weight: .medium)
        statsLabel.textColor = .white
        statsLabel.textAlignment = .center
        statsLabel.numberOfLines = 0

        achievementLabel.font = .systemFont(ofSize: 14, weight: .medium)
        achievementLabel.textColor = .systemTeal
        achievementLabel.textAlignment = .center
        achievementLabel.numberOfLines = 0

        let shopTitle = makeSectionTitle("МАГАЗИН УЛУЧШЕНИЙ")
        let stack = UIStackView(arrangedSubviews: [
            titleLabel, subtitleLabel, coinsLabel, levelLabel, cardView,
            progressView, tearButton, shopTitle, powerButton, autoButton,
            bonusButton, prestigeButton, statsLabel, achievementLabel
        ])
        stack.axis = .vertical
        stack.alignment = .fill
        stack.spacing = 13
        stack.translatesAutoresizingMaskIntoConstraints = false

        let scrollView = UIScrollView()
        scrollView.alwaysBounceVertical = true
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scrollView)
        scrollView.addSubview(stack)

        NSLayoutConstraint.activate([
            scrollView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 18),
            scrollView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -18),
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 10),
            scrollView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -8),
            stack.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor),
            stack.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor),
            stack.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor),
            stack.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor),
            cardView.heightAnchor.constraint(equalToConstant: 255),
            progressView.heightAnchor.constraint(equalToConstant: 10),
            tearButton.heightAnchor.constraint(equalToConstant: 55),
            powerButton.heightAnchor.constraint(greaterThanOrEqualToConstant: 54),
            autoButton.heightAnchor.constraint(greaterThanOrEqualToConstant: 54),
            bonusButton.heightAnchor.constraint(greaterThanOrEqualToConstant: 54),
            prestigeButton.heightAnchor.constraint(greaterThanOrEqualToConstant: 58)
        ])
    }

    private func makeSectionTitle(_ text: String) -> UILabel {
        let label = UILabel()
        label.text = text
        label.textColor = .systemOrange
        label.font = .systemFont(ofSize: 14, weight: .heavy)
        label.textAlignment = .center
        return label
    }

    private func configureButton(_ button: UIButton, title: String, color: UIColor, size: CGFloat) {
        button.setTitle(title, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: size, weight: .bold)
        button.titleLabel?.numberOfLines = 0
        button.titleLabel?.textAlignment = .center
        button.setTitleColor(.white, for: .normal)
        button.backgroundColor = color
        button.layer.cornerRadius = 13
        button.contentEdgeInsets = UIEdgeInsets(top: 10, left: 12, bottom: 10, right: 12)
    }

    @objc private func tear() {
        guard damage < damageNeeded else { return }
        damage = min(damageNeeded, damage + tapPower)
        coins += tapPower * coinMultiplier
        cardView.setDamage(damage: damage, total: damageNeeded)
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        if damage == damageNeeded { finishAce() }
        updateInterface()
    }

    private func applyAutoDamage() {
        guard autoPower > 0, damage < damageNeeded else { return }
        damage = min(damageNeeded, damage + autoPower)
        coins += autoPower * coinMultiplier
        cardView.setDamage(damage: damage, total: damageNeeded)
        if damage == damageNeeded { finishAce() }
        updateInterface()
    }

    private func finishAce() {
        tornAces += 1
        lifetimeAces += 1
        coins += (25 + tearBonus * 10) * coinMultiplier
        UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
        cardView.tearApart { [weak self] in
            guard let self = self else { return }
            self.damage = 0
            self.cardView.resetCard()
            self.updateInterface()
        }
    }

    @objc private func buyPower() {
        let cost = powerCost
        guard coins >= cost else { return }
        coins -= cost
        tapPower += 1
        updateInterface()
        saveProgress()
    }

    @objc private func buyAuto() {
        let cost = autoCost
        guard coins >= cost else { return }
        coins -= cost
        autoPower += 1
        updateInterface()
        saveProgress()
    }

    @objc private func performPrestige() {
        guard tornAces >= 10 else { return }
        prestige += 1
        coins = 0
        tornAces = 0
        tapPower = 1
        autoPower = 0
        tearBonus = 0
        damage = 0
        cardView.resetCard()
        updateInterface()
        saveProgress()
    }

    @objc private func buyBonus() {
        let cost = bonusCost
        guard coins >= cost else { return }
        coins -= cost
        tearBonus += 1
        updateInterface()
        saveProgress()
    }

    private var powerCost: Int { Int(ceil(25 * pow(1.55, Double(tapPower - 1)))) }
    private var autoCost: Int { Int(ceil(60 * pow(1.75, Double(autoPower)))) }
    private var bonusCost: Int { Int(ceil(40 * pow(1.65, Double(tearBonus)))) }

    private func updateInterface() {
        coinsLabel.text = "🪙  Монеты: \(coins)"
        levelLabel.text = "Уровень \(tornAces / 5 + 1)  •  Порвано тузов: \(tornAces)"
        progressView.setProgress(Float(damage) / Float(damageNeeded), animated: true)
        cardView.setDamage(damage: damage, total: damageNeeded)
        tearButton.setTitle("✂️  ПОРВАТЬ ТУЗ  (+\(tapPower) силы)", for: .normal)
        powerButton.setTitle("💪 Сила клика: \(tapPower) → \(tapPower + 1)\nЦена: \(powerCost) монет", for: .normal)
        autoButton.setTitle("⚙️ Авто-надрыв: \(autoPower) в секунду\nЦена: \(autoCost) монет", for: .normal)
        bonusButton.setTitle("🎁 Бонус за туз: +\(tearBonus * 10) монет\nУлучшить за: \(bonusCost) монет", for: .normal)
        prestigeButton.setTitle("♻️ ПРЕСТИЖ: \(prestige)  •  Доход x\(coinMultiplier)\nСбросить улучшения за 10 тузов текущего забега", for: .normal)
        statsLabel.text = "Прочность карты: \(damage) / \(damageNeeded)\nСила клика: \(tapPower)  •  Авто-сила: \(autoPower)/сек\nВсего порвано: \(lifetimeAces)  •  Престиж: \(prestige)"
        achievementLabel.text = achievementText()
        let canPower = coins >= powerCost
        let canAuto = coins >= autoCost
        let canBonus = coins >= bonusCost
        prestigeButton.alpha = tornAces >= 10 ? 1 : 0.55
        powerButton.alpha = canPower ? 1 : 0.65
        autoButton.alpha = canAuto ? 1 : 0.65
        bonusButton.alpha = canBonus ? 1 : 0.65
        saveProgress()
    }

    private func achievementText() -> String {
        if tornAces >= 100 { return "🏆 Легенда колоды! 100 тузов!" }
        if tornAces >= 50 { return "🥇 Мастер разрыва! 50 тузов!" }
        if tornAces >= 25 { return "🔥 Без остановки! 25 тузов!" }
        if tornAces >= 10 { return "⭐ Коллекционер! 10 тузов!" }
        if tornAces >= 5 { return "🎯 Первое достижение: 5 тузов!" }
        return "Цель: порви 5 тузов и получи достижение!"
    }

    @objc private func saveProgress() {
        defaults.set(coins, forKey: "coins")
        defaults.set(tornAces, forKey: "tornAces")
        defaults.set(lifetimeAces, forKey: "lifetimeAces")
        defaults.set(prestige, forKey: "prestige")
        defaults.set(tapPower, forKey: "tapPower")
        defaults.set(autoPower, forKey: "autoPower")
        defaults.set(tearBonus, forKey: "tearBonus")
        defaults.set(damage, forKey: "damage")
    }

    private func loadProgress() {
        coins = defaults.integer(forKey: "coins")
        tornAces = defaults.integer(forKey: "tornAces")
        lifetimeAces = defaults.integer(forKey: "lifetimeAces")
        prestige = defaults.integer(forKey: "prestige")
        tapPower = max(1, defaults.integer(forKey: "tapPower"))
        autoPower = defaults.integer(forKey: "autoPower")
        tearBonus = defaults.integer(forKey: "tearBonus")
        let savedDamage = defaults.integer(forKey: "damage")
        damage = savedDamage >= damageNeeded ? 0 : max(0, savedDamage)
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
            card.widthAnchor.constraint(equalToConstant: 180),
            card.heightAnchor.constraint(equalToConstant: 245),
            aceLabel.topAnchor.constraint(equalTo: card.topAnchor, constant: 12),
            aceLabel.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 16),
            suitLabel.centerXAnchor.constraint(equalTo: card.centerXAnchor),
            suitLabel.centerYAnchor.constraint(equalTo: card.centerYAnchor, constant: 15)
        ])
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    func setDamage(damage: Int, total: Int) {
        let alpha = CGFloat(damage) / CGFloat(total)
        crackLayer.frame = card.bounds
        let path = UIBezierPath()
        path.move(to: CGPoint(x: card.bounds.midX, y: 65))
        path.addLine(to: CGPoint(x: card.bounds.midX - 12, y: 100))
        path.addLine(to: CGPoint(x: card.bounds.midX + 9, y: 130))
        path.addLine(to: CGPoint(x: card.bounds.midX - 8, y: 165))
        path.addLine(to: CGPoint(x: card.bounds.midX + 5, y: 205))
        crackLayer.path = path.cgPath
        crackLayer.opacity = Float(alpha)
        card.transform = CGAffineTransform(rotationAngle: CGFloat.random(in: -0.025...0.025))
    }

    func tearApart(completion: @escaping () -> Void) {
        UIView.animate(withDuration: 0.5, animations: {
            self.card.transform = CGAffineTransform(translationX: -38, y: 10).rotated(by: -0.16)
            self.card.alpha = 0.25
        }) { _ in
            completion()
        }
    }

    func resetCard() {
        UIView.animate(withDuration: 0.22) {
            self.card.transform = .identity
            self.card.alpha = 1
            self.crackLayer.opacity = 0
        }
    }
}
