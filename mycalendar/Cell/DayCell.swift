import UIKit

class DayCell: UICollectionViewCell {
    private let label = UILabel()
    private let container = UIStackView()
    private let topSeparator = UIView() // ✅ 구분선 추가


    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
        setupTopSeparator()

    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupTopSeparator() {
            topSeparator.translatesAutoresizingMaskIntoConstraints = false
            topSeparator.backgroundColor = UIColor.systemGray4.withAlphaComponent(0.6)
            contentView.addSubview(topSeparator)

        NSLayoutConstraint.activate([
            topSeparator.topAnchor.constraint(equalTo: contentView.topAnchor, constant: CalendarLayout.eventBlockHeight * 2),
            topSeparator.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            topSeparator.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            topSeparator.heightAnchor.constraint(equalToConstant: 0.5)
        ])
    }


    private func setupViews() {
        container.axis = .vertical
        container.alignment = .fill
        container.distribution = .fill
        container.isLayoutMarginsRelativeArrangement = true
        container.layoutMargins = UIEdgeInsets(top: 8, left: 0, bottom: 16, right: 0)  // ✅ 원하는 top padding

        contentView.addSubview(container)
        container.frame = contentView.bounds
        container.autoresizingMask = [.flexibleWidth, .flexibleHeight]

        label.textAlignment = .center
        label.font = UIFont.systemFont(ofSize: 16)

        container.addArrangedSubview(label)
    }

    func configure(day: String, isToday: Bool = false, isSelected: Bool = false) {
        label.text = day
        label.textColor = isToday ? .systemRed : .label
        contentView.backgroundColor = isSelected ? UIColor.systemGray5 : .clear
        
        
        // ✅ 비어 있는 셀(= 날짜 없는 셀)이면 구분선 숨김
        topSeparator.isHidden = day.isEmpty
    }
}
