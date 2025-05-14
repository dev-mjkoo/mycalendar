import UIKit

class DayCell: UICollectionViewCell {
    private let label = UILabel()
    private let container = UIStackView()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
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
    }
}
