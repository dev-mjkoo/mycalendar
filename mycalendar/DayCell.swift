import UIKit
import EventKit

class DayCell: UICollectionViewCell {
    private let label = UILabel()
    private let eventStack = UIStackView()
    private var eventLabels: [UILabel] = []
    private let overflowLabel = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)

        label.textAlignment = .center
        label.font = UIFont.systemFont(ofSize: 16)

        eventStack.axis = .vertical
        eventStack.spacing = 2
        eventStack.alignment = .fill
        eventStack.distribution = .fill
        eventStack.translatesAutoresizingMaskIntoConstraints = false

        // ✅ dot 대신 글자에 배경색 + opacity
        for _ in 0..<2 {
            let title = UILabel()
            title.font = .systemFont(ofSize: 10)
            title.textColor = .label
            title.numberOfLines = 1
            title.textAlignment = .left
            title.layer.cornerRadius = 4
            title.clipsToBounds = true
            title.setContentHuggingPriority(.defaultLow, for: .horizontal)
            title.setContentCompressionResistancePriority(.required, for: .horizontal)
            title.isHidden = true
            eventStack.addArrangedSubview(title)
            eventLabels.append(title)
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

        for (i, event) in events.prefix(2).enumerated() {
            let label = eventLabels[i]
            label.text = " \(event.title ?? "") "
            let color = UIColor(cgColor: event.calendar.cgColor)
            label.textColor = color
            label.backgroundColor = color.withAlphaComponent(0.2)
            label.isHidden = false
        }

        let extra = events.count - 2
        if extra > 0 {
            overflowLabel.text = "외 \(extra)개"
            overflowLabel.isHidden = false
        }
    }
}
