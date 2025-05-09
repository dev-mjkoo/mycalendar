// MARK: - UI 구성 요소 선언
// 날짜 숫자를 보여줄 UILabel
// 이벤트 타이틀을 보여줄 stackView (최대 4개까지)
// 이벤트가 5개 이상일 경우 "외 N개"를 보여주는 UILabel

// MARK: - 초기화
// 기본 날짜 라벨 설정 (폰트, 정렬 등)
// 이벤트들을 세로로 쌓기 위한 UIStackView 설정

// 최대 4개의 이벤트 뷰(dot + title)를 미리 만들어 배열에 저장
// 생성한 dot, title은 각각 horizontal 스택에 담아 미리 stackView에 추가

// "외 N개" 표시용 라벨을 생성하고 stackView에 추가 (기본은 숨김 처리)

// 전체를 감싸는 vertical 스택 구성 (날짜 라벨 + 이벤트 스택)
// contentView에 추가하고 오토레이아웃 설정

// MARK: - 셀 구성 메서드 configure(...)
// 날짜 텍스트 설정
// isToday / isSelected 여부에 따라 셀 스타일 적용 (배경색, 텍스트 컬러 등)

// 최대 4개까지 이벤트를 표시
// - 각각의 dot 색상은 해당 이벤트의 캘린더 색상으로 설정
// - 타이틀은 이벤트 제목
// - 표시할 이벤트 수만큼만 .isHidden = false

// 만약 이벤트가 5개 이상이면 overflowLabel을 보여줌 ("외 N개")
// 아니면 숨김 처리

// MARK: - prepareForReuse()
// 셀 재사용 시 모든 라벨 초기화
// 이벤트 라벨들 및 overflowLabel을 숨김 처리하여 재사용에 대비

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
        eventStack.spacing = 1
        eventStack.alignment = .leading
        eventStack.distribution = .fillProportionally
        eventStack.translatesAutoresizingMaskIntoConstraints = false

        // 최대 4개의 이벤트 뷰 미리 구성
        for _ in 0..<4 {
            let dot = UIView()
            dot.translatesAutoresizingMaskIntoConstraints = false
            dot.widthAnchor.constraint(equalToConstant: 6).isActive = true
            dot.heightAnchor.constraint(equalToConstant: 6).isActive = true
            dot.layer.cornerRadius = 3
            dot.clipsToBounds = true

            let title = UILabel()
            title.font = .systemFont(ofSize: 10)
            title.textColor = .darkGray

            let stack = UIStackView(arrangedSubviews: [dot, title])
            stack.axis = .horizontal
            stack.spacing = 4
            stack.alignment = .center
            stack.isHidden = true

            eventStack.addArrangedSubview(stack)
            eventViews.append((dot: dot, title: title))
        }

        // 오버플로 텍스트 추가 ("외 N개")
        overflowLabel.font = .systemFont(ofSize: 10)
        overflowLabel.textColor = .gray
        overflowLabel.isHidden = true
        eventStack.addArrangedSubview(overflowLabel)

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

    func configure(day: String, isToday: Bool, isSelected: Bool, events: [EKEvent]?) {
        label.text = day

        let eventCount = events?.count ?? 0
        let visibleCount = 4

        // 이벤트 내용 표시
        for (i, viewPair) in eventViews.enumerated() {
            if let events = events, i < min(eventCount, visibleCount) {
                let event = events[i]
                viewPair.dot.backgroundColor = UIColor(cgColor: event.calendar.cgColor)
                viewPair.title.text = event.title ?? ""
                eventStack.arrangedSubviews[i].isHidden = false
            } else {
                eventStack.arrangedSubviews[i].isHidden = true
            }
        }

        // 오버플로우 텍스트 처리
        if eventCount > visibleCount {
            let overflow = eventCount - visibleCount
            overflowLabel.text = "외 \(overflow)개"
            overflowLabel.isHidden = false
        } else {
            overflowLabel.isHidden = true
        }

        // 셀 스타일
        if isSelected {
            contentView.backgroundColor = UIColor.systemGreen.withAlphaComponent(0.3)
            label.textColor = .systemGreen
            contentView.layer.cornerRadius = 8
            contentView.layer.masksToBounds = true
        } else if isToday {
            contentView.backgroundColor = UIColor.systemBlue.withAlphaComponent(0.2)
            label.textColor = .systemBlue
            contentView.layer.cornerRadius = 8
            contentView.layer.masksToBounds = true
        } else {
            contentView.backgroundColor = .clear
            label.textColor = .label
            contentView.layer.cornerRadius = 0
        }
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        label.text = ""
        for view in eventStack.arrangedSubviews {
            view.isHidden = true
        }
        overflowLabel.text = nil
        overflowLabel.isHidden = true
    }
}
