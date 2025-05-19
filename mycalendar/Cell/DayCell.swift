import UIKit

class DayCell: UICollectionViewCell {
    private let label = UILabel()
    private let container = UIStackView()
    private let topSeparator = UIView()
    private let circleView = UIView() // ✅ 배경 원 추가
    private var isTodayDate: Bool = false
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
        setupTopSeparator()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override var isSelected: Bool {
        didSet {
            updateSelectionAppearance()
        }
    }
    
    private func updateSelectionAppearance() {
        if label.text?.isEmpty ?? true {
            circleView.backgroundColor = .clear
            label.textColor = .clear
        } else if isTodayDate {
            circleView.backgroundColor = .systemRed
            label.textColor = .white
        } else if isSelected {
            circleView.backgroundColor = .systemGray
            label.textColor = .white
        } else {
            circleView.backgroundColor = .clear
            label.textColor = .label
        }
    }
    
    private func setupTopSeparator() {
        topSeparator.translatesAutoresizingMaskIntoConstraints = false
        topSeparator.backgroundColor = UIColor.systemGray4.withAlphaComponent(0.6)
        contentView.addSubview(topSeparator)
        
        NSLayoutConstraint.activate([
            topSeparator.topAnchor.constraint(equalTo: contentView.topAnchor, constant: CalendarLayout.eventBlockHeight + 4),
            topSeparator.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            topSeparator.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            topSeparator.heightAnchor.constraint(equalToConstant: 0.5)
        ])
    }
    
    private func setupViews() {
        container.axis = .vertical
        container.alignment = .center
        container.distribution = .fill
        container.isLayoutMarginsRelativeArrangement = true
        container.layoutMargins = UIEdgeInsets(top: 0, left: 0, bottom: 24, right: 0)
        container.translatesAutoresizingMaskIntoConstraints = false // ✅ 중요!!
        
        contentView.addSubview(container)
        
        // ✅ Auto Layout constraints 사용
        NSLayoutConstraint.activate([
            container.topAnchor.constraint(equalTo: contentView.topAnchor),
            container.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            container.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            container.trailingAnchor.constraint(equalTo: contentView.trailingAnchor)
        ])
        
        // ✅ 원 배경 설정
        circleView.translatesAutoresizingMaskIntoConstraints = false
        circleView.backgroundColor = .clear
        circleView.layer.cornerRadius = 16
        circleView.clipsToBounds = true
        
        NSLayoutConstraint.activate([
            circleView.widthAnchor.constraint(equalToConstant: 32),
            circleView.heightAnchor.constraint(equalToConstant: 32)
        ])
        
        // ✅ 텍스트 라벨
        label.translatesAutoresizingMaskIntoConstraints = false
        label.textAlignment = .center
        label.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
        
        // ✅ 뷰 계층 구성
        let circleContainer = UIView()
        circleContainer.translatesAutoresizingMaskIntoConstraints = false
        circleContainer.addSubview(circleView)
        circleContainer.addSubview(label)
        
        NSLayoutConstraint.activate([
            circleView.centerXAnchor.constraint(equalTo: circleContainer.centerXAnchor),
            circleView.centerYAnchor.constraint(equalTo: circleContainer.centerYAnchor),
            label.centerXAnchor.constraint(equalTo: circleContainer.centerXAnchor),
            label.centerYAnchor.constraint(equalTo: circleContainer.centerYAnchor),
        ])
        
        container.addArrangedSubview(circleContainer)
    }
    
    func configure(day: String, isToday: Bool = false, isSelected: Bool = false) {
        label.text = day
        isTodayDate = isToday // ✅ 저장
        topSeparator.isHidden = day.isEmpty
        
        if day.isEmpty {
            circleView.backgroundColor = .clear
            label.textColor = .clear
        } else if isToday {
            circleView.backgroundColor = .systemRed
            label.textColor = .white
        } else if isSelected {
            circleView.backgroundColor = .systemGray
            label.textColor = .white
        } else {
            circleView.backgroundColor = .clear
            label.textColor = .label
        }
        
        contentView.backgroundColor = .clear
    }
}
