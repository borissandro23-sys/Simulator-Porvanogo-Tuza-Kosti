import UIKit

private struct RunUpgrade {
    let title: String
    let detail: String
    let kind: Int
}

final class GameViewController: UIViewController {
    private let titleLabel = UILabel()
    private let subtitleLabel = UILabel()
    private let cardView = AceCardView()
    private let progressView = UIProgressView(progressViewStyle: .default)
    private let tearButton = UIButton(type: .system)
    private let coinsLabel = UILabel()
    private let gemsLabel = UILabel()
    private let dailyRewardButton = UIButton(type: .system)
    private let offerButton = UIButton(type: .system)
    private let skinButtons = (0..<3).map { _ in UIButton(type: .system) }
    private let statsLabel = UILabel()
    private let levelLabel = UILabel()
    private let achievementLabel = UILabel()
    private let eventLabel = UILabel()
    private let choiceTitle = UILabel()
    private let choiceButtons = (0..<3).map { _ in UIButton(type: .system) }
    private let powerButton = UIButton(type: .system)
    private let autoButton = UIButton(type: .system)
    private let bonusButton = UIButton(type: .system)
    private let prestigeButton = UIButton(type: .system)

    private let defaults = UserDefaults.standard
    private var damage = 0
    private var coins = 0
    private var gems = 0
    private var selectedSkin = 0
    private var tornAces = 0
    private var lifetimeAces = 0
    private var prestige = 0
    private var damageNeeded: Int { baseDamageNeeded * (isBoss ? 4 : 1) }
    private var baseDamageNeeded: Int { 100 + (lifetimeAces / 10) * 25 }
    private var coinMultiplier: Int { 1 + prestige }
    private var tapPower = 1
    private var autoPower = 0
    private var tearBonus = 0
    private var rareBonus = 0
    private var isBoss = false
    private var isRare = false
    private var cardRewardMultiplier = 1
    private var pendingChoices: [RunUpgrade] = []
    private var autoTimer: Timer?

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor(red: 0.07, green: 0.09, blue: 0.14, alpha: 1)
        loadProgress()
        prepareNextCard()
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

        subtitleLabel.text = "Бей боссов. Открывай редкие карты. Выбирай свой билд."
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

        eventLabel.font = .systemFont(ofSize: 16, weight: .heavy)
        eventLabel.textColor = .systemTeal
        eventLabel.textAlignment = .center
        eventLabel.numberOfLines = 0

        choiceTitle.text = "🎲 ВЫБЕРИ ОДНО УЛУЧШЕНИЕ"
        choiceTitle.font = .systemFont(ofSize: 15, weight: .heavy)
        choiceTitle.textColor = .systemYellow
        choiceTitle.textAlignment = .center

        progressView.progressTintColor = .systemOrange
        progressView.trackTintColor = UIColor.white.withAlphaComponent(0.15)
        progressView.layer.cornerRadius = 5
        progressView.clipsToBounds = true

        gemsLabel.font = .systemFont(ofSize: 17, weight: .bold)
        gemsLabel.textColor = .systemTeal
        gemsLabel.textAlignment = .center

        configureButton(dailyRewardButton, title: "🎁 ЗАБРАТЬ ЕЖЕДНЕВНУЮ НАГРАДУ", color: UIColor(red: 0.12, green: 0.48, blue: 0.38, alpha: 1), size: 15)
        dailyRewardButton.addTarget(self, action: #selector(claimDailyReward), for: .touchUpInside)
        configureButton(offerButton, title: "", color: UIColor(red: 0.55, green: 0.30, blue: 0.16, alpha: 1), size: 15)
        offerButton.addTarget(self, action: #selector(buyDailyOffer), for: .touchUpInside)
        for (index, button) in skinButtons.enumerated() {
            configureButton(button, title: "", color: UIColor(red: 0.28, green: 0.30, blue: 0.48, alpha: 1), size: 14)
            button.tag = index
            button.addTarget(self, action: #selector(buySkin(_:)), for: .touchUpInside)
        }

        configureButton(tearButton, title: "✂️ ПОРВАТЬ ТУЗ", color: .systemOrange, size: 19)
        tearButton.addTarget(self, action: #selector(tear), for: .touchUpInside)

        for (index, button) in choiceButtons.enumerated() {
            configureButton(button, title: "", color: UIColor(red: 0.30, green: 0.28, blue: 0.55, alpha: 1), size: 14)
            button.tag = index
            button.addTarget(self, action: #selector(chooseUpgrade(_:)), for: .touchUpInside)
            button.isHidden = true
        }
        choiceTitle.isHidden = true

        configureButton(powerButton, title: "", color: UIColor(red: 0.18, green: 0.38, blue: 0.68, alpha: 1), size: 15)
        configureButton(autoButton, title: "", color: UIColor(red: 0.24, green: 0.48, blue: 0.38, alpha: 1), size: 15)
        configureButton(bonusButton, title: "", color: UIColor(red: 0.48, green: 0.30, blue: 0.62, alpha: 1), size: 15)
        powerButton.addTarget(self, action: #selector(buyPower), for: .touchUpInside)
        autoButton.addTarget(self, action: #selector(buyAuto), for: .touchUpInside)
        bonusButton.addTarget(self, action: #selector(buyBonus), for: .touchUpInside)
        configureButton(prestigeButton, title: "", color: UIColor(red: 0.55, green: 0.32, blue: 0.18, alpha: 1), size: 15)
        prestigeButton.addTarget(self, action: #selector(performPrestige), for: .touchUpInside)

        statsLabel.font = .systemFont(ofSize: 15, weight: .medium)
        statsLabel.textColor = .white
        statsLabel.textAlignment = .center
        statsLabel.numberOfLines = 0

        achievementLabel.font = .systemFont(ofSize: 14, weight: .medium)
        achievementLabel.textColor = .systemTeal
        achievementLabel.textAlignment = .center
        achievementLabel.numberOfLines = 0

        let stack = UIStackView(arrangedSubviews: [
            titleLabel, subtitleLabel, coinsLabel, gemsLabel, levelLabel, eventLabel, cardView,
            progressView, tearButton, choiceTitle, choiceButtons[0], choiceButtons[1],
            choiceButtons[2], makeSectionTitle("🛍️ МАГАЗИН SIND"), dailyRewardButton, offerButton,
            skinButtons[0], skinButtons[1], skinButtons[2],
            makeSectionTitle("УЛУЧШЕНИЯ ЗА МОНЕТЫ"), powerButton,
            autoButton, bonusButton, prestigeButton, statsLabel, achievementLabel
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

    private func prepareNextCard() {
        isBoss = (lifetimeAces + 1) % 5 == 0
        isRare = !isBoss && Int.random(in: 1...100) <= min(45, 15 + rareBonus)
        cardRewardMultiplier = isBoss ? 5 : (isRare ? 3 : 1)
        let suit = ["♥", "♦", "♣", "♠"].randomElement() ?? "♥"
        let color: UIColor = (suit == "♥" || suit == "♦") ? .systemRed : .black
        let name = isBoss ? "БОСС • КОРОЛЬ" : (isRare ? "РЕДКИЙ ТУЗ" : "ТУЗ")
        let skinColors: [UIColor] = [.systemRed, .systemTeal, .systemPurple]
        cardView.setCard(name: name, suit: suit, color: skinColors[selectedSkin])
    }

    @objc private func tear() {
        guard damage < damageNeeded else { return }
        damage = min(damageNeeded, damage + tapPower)
        coins += tapPower * coinMultiplier * cardRewardMultiplier
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        if damage == damageNeeded { finishAce() }
        updateInterface()
    }

    private func applyAutoDamage() {
        guard autoPower > 0, damage < damageNeeded else { return }
        damage = min(damageNeeded, damage + autoPower)
        coins += autoPower * coinMultiplier * cardRewardMultiplier
        if damage == damageNeeded { finishAce() }
        updateInterface()
    }

    private func finishAce() {
        tornAces += 1
        lifetimeAces += 1
        coins += (25 + tearBonus * 10) * coinMultiplier * cardRewardMultiplier
        UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
        if isBoss {
            coins += 250 * coinMultiplier
            eventLabel.text = "👑 БОСС ПОВЕРЖЕН! +250 монет"
        } else if isRare {
            eventLabel.text = "✨ РЕДКАЯ КАРТА! Награда x3"
        } else {
            eventLabel.text = "Туз разорван. Следующая карта уже ждёт!"
        }
        if lifetimeAces % 3 == 0 { showUpgradeChoices() }
        cardView.tearApart { [weak self] in
            guard let self = self else { return }
            self.damage = 0
            self.prepareNextCard()
            self.cardView.resetCard()
            self.updateInterface()
        }
    }

    private func showUpgradeChoices() {
        let all = [
            RunUpgrade(title: "💥 Сильный удар", detail: "+2 к силе клика", kind: 0),
            RunUpgrade(title: "🤖 Механический палец", detail: "+1 авто-надрыв/сек", kind: 1),
            RunUpgrade(title: "🍀 Охота за редкостями", detail: "+10% шанс редкой карты", kind: 2),
            RunUpgrade(title: "💰 Золотая пыль", detail: "+1 монета за силу клика", kind: 3)
        ]
        pendingChoices = Array(all.shuffled().prefix(3))
        choiceTitle.isHidden = false
        for index in 0..<3 {
            let option = pendingChoices[index]
            choiceButtons[index].setTitle("\(option.title)\n\(option.detail)", for: .normal)
            choiceButtons[index].isHidden = false
        }
    }

    @objc private func chooseUpgrade(_ sender: UIButton) {
        guard pendingChoices.indices.contains(sender.tag) else { return }
        let selected = pendingChoices[sender.tag]
        switch selected.kind {
        case 0: tapPower += 2
        case 1: autoPower += 1
        case 2: rareBonus = min(30, rareBonus + 10)
        default: tearBonus += 1
        }
        pendingChoices.removeAll()
        choiceTitle.isHidden = true
        choiceButtons.forEach { $0.isHidden = true }
        eventLabel.text = "Улучшение получено: \(selected.title)"
        updateInterface()
        saveProgress()
    }

    private var dayNumber: Int {
        let parts = Calendar.current.dateComponents([.year, .month, .day], from: Date())
        return (parts.year ?? 0) * 10000 + (parts.month ?? 0) * 100 + (parts.day ?? 0)
    }

    @objc private func claimDailyReward() {
        let lastClaim = defaults.integer(forKey: "shopDailyClaim")
        guard lastClaim != dayNumber else { return }
        coins += 250
        gems += 5
        defaults.set(dayNumber, forKey: "shopDailyClaim")
        eventLabel.text = "🎁 Награда получена: 250 монет и 5 кристаллов!"
        updateInterface()
    }

    @objc private func buyDailyOffer() {
        let offerIndex = dayNumber % 3
        let costs = [10, 15, 20]
        let rewards = [700, 1200, 1800]
        guard gems >= costs[offerIndex] else {
            eventLabel.text = "Не хватает кристаллов для предложения"
            return
        }
        gems -= costs[offerIndex]
        coins += rewards[offerIndex]
        eventLabel.text = "🛍️ Куплено предложение дня!"
        updateInterface()
    }

    @objc private func buySkin(_ sender: UIButton) {
        let skin = sender.tag
        if selectedSkin == skin {
            eventLabel.text = "Этот стиль уже выбран"
            return
        }
        let prices = [0, 20, 35]
        if skin == 0 || defaults.bool(forKey: "shopSkin\(skin)Owned") {
            selectedSkin = skin
        } else if gems >= prices[skin] {
            gems -= prices[skin]
            defaults.set(true, forKey: "shopSkin\(skin)Owned")
            selectedSkin = skin
        } else {
            eventLabel.text = "Не хватает кристаллов для этого стиля"
            return
        }
        updateCardAppearance()
        eventLabel.text = "🎨 Стиль карты изменён!"
        updateInterface()
    }

    private func updateCardAppearance() {
        let suits = ["♥", "♦", "♣", "♠"]
        let suit = suits.randomElement() ?? "♥"
        let colors: [UIColor] = [.systemRed, .systemTeal, .systemPurple]
        let name = isBoss ? "БОСС • КОРОЛЬ" : (isRare ? "РЕДКИЙ ТУЗ" : "ТУЗ")
        cardView.setCard(name: name, suit: suit, color: colors[selectedSkin])
    }

    @objc private func buyPower() {
        guard coins >= powerCost else { return }
        coins -= powerCost
        tapPower += 1
        updateInterface()
    }

    @objc private func buyAuto() {
        guard coins >= autoCost else { return }
        coins -= autoCost
        autoPower += 1
        updateInterface()
    }

    @objc private func performPrestige() {
        guard tornAces >= 10 else { return }
        prestige += 1
        coins = 0
        tornAces = 0
        tapPower = 1
        autoPower = 0
        tearBonus = 0
        rareBonus = 0
        damage = 0
        prepareNextCard()
        cardView.resetCard()
        updateInterface()
    }

    @objc private func buyBonus() {
        guard coins >= bonusCost else { return }
        coins -= bonusCost
        tearBonus += 1
        updateInterface()
    }

    // Quadratic prices grow steadily instead of exploding exponentially.
    private func balancedCost(base: Int, level: Int, coefficient: Int) -> Int {
        let safeLevel = min(10_000, max(0, level))
        return min(1_000_000_000, base + coefficient * safeLevel * safeLevel)
    }

    private var powerCost: Int { balancedCost(base: 25, level: tapPower - 1, coefficient: 8) }
    private var autoCost: Int { balancedCost(base: 60, level: autoPower, coefficient: 12) }
    private var bonusCost: Int { balancedCost(base: 40, level: tearBonus, coefficient: 10) }

    private func updateInterface() {
        coinsLabel.text = "🪙 Монеты: \(coins)"
        gemsLabel.text = "💎 Кристаллы: \(gems)"
        levelLabel.text = "Уровень \(tornAces / 5 + 1) • В забеге: \(tornAces) • Всего: \(lifetimeAces)"
        if isBoss {
            eventLabel.text = "👑 БОСС! Прочность x4 • Награда x5"
            eventLabel.textColor = .systemRed
        } else if isRare {
            eventLabel.text = "✨ РЕДКАЯ КАРТА! Награда x3"
            eventLabel.textColor = .systemPurple
        }
        progressView.setProgress(Float(damage) / Float(damageNeeded), animated: true)
        cardView.setDamage(damage: damage, total: damageNeeded)
        tearButton.setTitle("✂️ ПОРВАТЬ ТУЗ (+\(tapPower) силы)", for: .normal)
        let offerIndex = dayNumber % 3
        let offerNames = ["🧰 Малый набор: 700 монет", "🎒 Средний набор: 1200 монет", "👑 Большой набор: 1800 монет"]
        let offerCosts = [10, 15, 20]
        offerButton.setTitle("\(offerNames[offerIndex])\nЦена: \(offerCosts[offerIndex]) 💎", for: .normal)
        dailyRewardButton.setTitle(defaults.integer(forKey: "shopDailyClaim") == dayNumber ? "✅ НАГРАДА УЖЕ ПОЛУЧЕНА" : "🎁 БЕСПЛАТНО: 250 🪙 + 5 💎", for: .normal)
        dailyRewardButton.isEnabled = defaults.integer(forKey: "shopDailyClaim") != dayNumber
        let skinNames = ["🔴 Классический стиль • Бесплатно", "🌊 Неоновый стиль • 20 💎", "🟣 Космический стиль • 35 💎"]
        for index in 0..<3 {
            let owned = index == 0 || defaults.bool(forKey: "shopSkin\(index)Owned")
            skinButtons[index].setTitle("\(skinNames[index])\n\(selectedSkin == index ? "✓ Выбрано" : (owned ? "Выбрать" : "Купить"))", for: .normal)
            skinButtons[index].alpha = selectedSkin == index ? 1 : 0.85
        }
        powerButton.setTitle("💪 Сила клика: \(tapPower) → \(tapPower + 1)\nЦена: \(powerCost) монет", for: .normal)
        autoButton.setTitle("⚙️ Авто-надрыв: \(autoPower)/сек\nЦена: \(autoCost) монет", for: .normal)
        bonusButton.setTitle("🎁 Бонус за туз: +\(tearBonus * 10) монет\nУлучшить за: \(bonusCost) монет", for: .normal)
        prestigeButton.setTitle("♻️ ПРЕСТИЖ: \(prestige) • Доход x\(coinMultiplier)\nСбросить улучшения за 10 тузов", for: .normal)
        statsLabel.text = "Прочность: \(damage)/\(damageNeeded)\nСила: \(tapPower) • Авто: \(autoPower)/сек • Шанс редкой карты: \(min(45, 15 + rareBonus))%\nВсего порвано: \(lifetimeAces) • Престиж: \(prestige)"
        achievementLabel.text = achievementText()
        prestigeButton.alpha = tornAces >= 10 ? 1 : 0.55
        powerButton.alpha = coins >= powerCost ? 1 : 0.65
        autoButton.alpha = coins >= autoCost ? 1 : 0.65
        bonusButton.alpha = coins >= bonusCost ? 1 : 0.65
        saveProgress()
    }

    private func achievementText() -> String {
        if lifetimeAces >= 100 { return "🏆 Легенда колоды! 100 тузов!" }
        if lifetimeAces >= 50 { return "🥇 Мастер разрыва! 50 тузов!" }
        if lifetimeAces >= 25 { return "🔥 Без остановки! 25 тузов!" }
        if lifetimeAces >= 10 { return "⭐ Коллекционер! 10 тузов!" }
        if lifetimeAces >= 5 { return "🎯 Первое достижение: 5 тузов!" }
        return "Цель: порви 5 тузов и получи достижение!"
    }

    @objc private func saveProgress() {
        defaults.set(coins, forKey: "coins")
        defaults.set(gems, forKey: "shopGems")
        defaults.set(selectedSkin, forKey: "shopSelectedSkin")
        defaults.set(tornAces, forKey: "tornAces")
        defaults.set(lifetimeAces, forKey: "lifetimeAces")
        defaults.set(prestige, forKey: "prestige")
        defaults.set(tapPower, forKey: "tapPower")
        defaults.set(autoPower, forKey: "autoPower")
        defaults.set(tearBonus, forKey: "tearBonus")
        defaults.set(rareBonus, forKey: "rareBonus")
        defaults.set(damage, forKey: "damage")
    }

    private func loadProgress() {
        coins = defaults.integer(forKey: "coins")
        gems = defaults.integer(forKey: "shopGems")
        selectedSkin = min(2, max(0, defaults.integer(forKey: "shopSelectedSkin")))
        tornAces = defaults.integer(forKey: "tornAces")
        lifetimeAces = defaults.integer(forKey: "lifetimeAces")
        prestige = defaults.integer(forKey: "prestige")
        tapPower = max(1, defaults.integer(forKey: "tapPower"))
        autoPower = defaults.integer(forKey: "autoPower")
        tearBonus = defaults.integer(forKey: "tearBonus")
        rareBonus = defaults.integer(forKey: "rareBonus")
        damage = max(0, defaults.integer(forKey: "damage"))
    }
}

private final class AceCardView: UIView {
    private let card = UIView()
    private let nameLabel = UILabel()
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

        nameLabel.font = .systemFont(ofSize: 13, weight: .black)
        nameLabel.textAlignment = .center
        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(nameLabel)

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
            nameLabel.topAnchor.constraint(equalTo: card.topAnchor, constant: 8),
            nameLabel.centerXAnchor.constraint(equalTo: card.centerXAnchor),
            aceLabel.topAnchor.constraint(equalTo: card.topAnchor, constant: 25),
            aceLabel.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 16),
            suitLabel.centerXAnchor.constraint(equalTo: card.centerXAnchor),
            suitLabel.centerYAnchor.constraint(equalTo: card.centerYAnchor, constant: 15)
        ])
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    func setCard(name: String, suit: String, color: UIColor) {
        nameLabel.text = name
        nameLabel.textColor = color
        aceLabel.textColor = color
        suitLabel.text = suit
        suitLabel.textColor = color
    }

    func setDamage(damage: Int, total: Int) {
        let alpha = CGFloat(damage) / CGFloat(max(1, total))
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
        }) { _ in completion() }
    }

    func resetCard() {
        UIView.animate(withDuration: 0.22) {
            self.card.transform = .identity
            self.card.alpha = 1
            self.crackLayer.opacity = 0
        }
    }
}
