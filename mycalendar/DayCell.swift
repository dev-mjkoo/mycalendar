//
//  DayCell.swift
//  mycalendar
//
//  Created by 구민준 on 5/9/25.
//
//[DayCell 클릭]
//     ↓
//MonthCell.didSelectItemAt
//     ↓
//onDateSelected?(date)
//     ↓
//CalendarViewController.selectedDate = date
//     ↓
//UIKitCalendarView → SwiftUI @Binding selectedDate 업데이트
//

import UIKit
import EventKit

class DayCell: UICollectionViewCell {
    private let label = UILabel()
    private let eventStack = UIStackView()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        label.frame = contentView.bounds
        label.textAlignment = .center
        label.font = UIFont.systemFont(ofSize: 16)
        contentView.addSubview(label)
        
        eventStack.axis = .vertical
        eventStack.spacing = 1
        eventStack.alignment = .leading
        eventStack.distribution = .fillProportionally
        
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
        
        // 이벤트 스택 초기화
        eventStack.arrangedSubviews.forEach { $0.removeFromSuperview() }
        
        if let events = events {
            for event in events.prefix(2) { // 최대 2개까지만
                let eventLabel = UILabel()
                eventLabel.text = "• \(event.title ?? "")"
                eventLabel.font = UIFont.systemFont(ofSize: 10)
                eventLabel.textColor = .darkGray
                eventStack.addArrangedSubview(eventLabel)
            }
        }
        
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
}
