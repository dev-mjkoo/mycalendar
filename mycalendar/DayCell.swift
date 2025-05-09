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

class DayCell: UICollectionViewCell {
    private let label = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)
        label.frame = contentView.bounds
        label.textAlignment = .center
        label.font = UIFont.systemFont(ofSize: 16)
        contentView.addSubview(label)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(day: String, isToday: Bool, isSelected: Bool) {
        label.text = day

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
