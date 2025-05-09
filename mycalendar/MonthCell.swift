//
//  MonthCell.swift
//  mycalendar
//
//  Created by 구민준 on 5/9/25.
//

import UIKit

class MonthCell: UICollectionViewCell, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    private let titleLabel = UILabel()
    private var collectionView: UICollectionView!
    private var days: [Date] = []
    private var calendar = Calendar.current

    override init(frame: CGRect) {
        super.init(frame: frame)

        titleLabel.font = UIFont.boldSystemFont(ofSize: 20)
        titleLabel.textAlignment = .center
        titleLabel.translatesAutoresizingMaskIntoConstraints = false

        let layout = UICollectionViewFlowLayout()
        layout.minimumInteritemSpacing = 0
        layout.minimumLineSpacing = 0

        collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.register(DayCell.self, forCellWithReuseIdentifier: "DayCell")

        contentView.addSubview(titleLabel)
        contentView.addSubview(collectionView)

        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
            titleLabel.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),

            collectionView.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 8),
            collectionView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
        ])
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    func configure(with date: Date) {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        titleLabel.text = formatter.string(from: date)

        generateDays(for: date)
        collectionView.reloadData()
    }

    private func generateDays(for date: Date) {
        days = []

        let range = calendar.range(of: .day, in: .month, for: date)!
        let firstOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: date))!
        let weekdayOffset = calendar.component(.weekday, from: firstOfMonth) - calendar.firstWeekday

        // 공백 채우기
        for _ in 0..<((weekdayOffset + 7) % 7) {
            days.append(Date.distantPast)  // 빈 칸 표시용
        }

        for day in range {
            if let dayDate = calendar.date(byAdding: .day, value: day - 1, to: firstOfMonth) {
                days.append(dayDate)
            }
        }
    }

    // MARK: CollectionView DataSource

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return days.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "DayCell", for: indexPath) as! DayCell
        let date = days[indexPath.item]
        if date == Date.distantPast {
            cell.configure(day: "")
        } else {
            let day = calendar.component(.day, from: date)
            cell.configure(day: "\(day)")
        }
        return cell
    }

    // MARK: CollectionView Layout

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let width = collectionView.bounds.width / 7
        return CGSize(width: width, height: 40)
    }
}
