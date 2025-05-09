//
//  DayCell.swift
//  mycalendar
//
//  Created by 구민준 on 5/9/25.
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

    func configure(day: String) {
        label.text = day
    }
}
