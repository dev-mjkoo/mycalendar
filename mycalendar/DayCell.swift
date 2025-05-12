import UIKit

class DayCell: UICollectionViewCell {
    private let label = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)
        label.textAlignment = .center
        label.font = UIFont.systemFont(ofSize: 16)
        contentView.addSubview(label)
        label.frame = contentView.bounds
        label.autoresizingMask = [.flexibleWidth, .flexibleHeight]
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(day: String, isToday: Bool = false, isSelected: Bool = false) {
        label.text = day
        label.textColor = isToday ? .systemRed : .label
        contentView.backgroundColor = isSelected ? UIColor.systemGray5 : .clear
    }
}
