import UIKit
import EventKit

class DayCell: UICollectionViewCell {
    private let label = UILabel()
    private let eventStack = UIStackView()
    private var eventViews: [(dot: UIView, title: UILabel)] = []
    private let overflowLabel = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)

        label.textAlignment = .center
        label.font = UIFont.systemFont(ofSize: 16)

        eventStack.axis = .vertical
        eventStack.spacing = 2
        eventStack.alignment = .fill // ✅ 변경
        eventStack.distribution = .fill
        eventStack.translatesAutoresizingMaskIntoConstraints = false

        for _ in 0..<4 {
            let dot = UIView()
            dot.translatesAutoresizingMaskIntoConstraints = false
            dot.backgroundColor = .systemBlue
            dot.widthAnchor.constraint(equalToConstant: 6).isActive = true
            dot.heightAnchor.constraint(equalToConstant: 6).isActive = true
            dot.layer.cornerRadius = 3
            dot.clipsToBounds = true

            let title = UILabel()
            title.font = .systemFont(ofSize: 10)
            title.textColor = .darkGray
            title.setContentHuggingPriority(.defaultLow, for: .horizontal)
            title.setContentCompressionResistancePriority(.required, for: .horizontal)

            // 👉 dot의 수직 가운데 정렬을 위해 별도 컨테이너
            let dotContainer = UIView()
            dotContainer.translatesAutoresizingMaskIntoConstraints = false
            dotContainer.addSubview(dot)
            NSLayoutConstraint.activate([
                dot.centerYAnchor.constraint(equalTo: dotContainer.centerYAnchor),
                dot.leadingAnchor.constraint(equalTo: dotContainer.leadingAnchor),
                dot.trailingAnchor.constraint(equalTo: dotContainer.trailingAnchor),
                dot.topAnchor.constraint(greaterThanOrEqualTo: dotContainer.topAnchor),
                dot.bottomAnchor.constraint(lessThanOrEqualTo: dotContainer.bottomAnchor)
            ])

            let stack = UIStackView(arrangedSubviews: [dotContainer, title])
            stack.axis = .horizontal
            stack.alignment = .center
            stack.spacing = 4
            stack.isHidden = true

            eventStack.addArrangedSubview(stack)
            eventViews.append((dot: dot, title: title))
        }

        overflowLabel.font = .systemFont(ofSize: 10)
        overflowLabel.textColor = .gray
        overflowLabel.numberOfLines = 1
        overflowLabel.isHidden = true
        overflowLabel.setContentHuggingPriority(.defaultHigh, for: .vertical)
        overflowLabel.setContentCompressionResistancePriority(.required, for: .vertical)
        eventStack.addArrangedSubview(overflowLabel)

        label.setContentHuggingPriority(.required, for: .vertical)
        eventStack.setContentHuggingPriority(.defaultLow, for: .vertical)

        let container = UIStackView(arrangedSubviews: [label, eventStack])
        container.axis = .vertical
        container.spacing = 4
        container.translatesAutoresizingMaskIntoConstraints = false

        contentView.addSubview(container)
        NSLayoutConstraint.activate([
            container.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 4),
            container.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 4),
            container.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -4),
            container.bottomAnchor.constraint(lessThanOrEqualTo: contentView.bottomAnchor, constant: -4)
        ])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(day: String, isToday: Bool = false, isSelected: Bool = false, events: [EKEvent]? = nil) {
        label.text = day
        label.textColor = isToday ? .systemRed : .label
        contentView.backgroundColor = isSelected ? UIColor.systemGray5 : .clear

        // 모든 이벤트 뷰 숨김 초기화
        for view in eventStack.arrangedSubviews {
            view.isHidden = true
        }

        guard let events = events, !events.isEmpty else {
            return
        }

        for (i, event) in events.prefix(4).enumerated() {
            eventViews[i].dot.backgroundColor = UIColor(cgColor: event.calendar.cgColor) ?? .systemBlue
            eventViews[i].title.text = event.title
            eventStack.arrangedSubviews[i].isHidden = false
        }

        let extra = events.count - 4
        if extra > 0 {
            overflowLabel.text = "외 \(extra)개"
            overflowLabel.isHidden = false
        }
    }
}
