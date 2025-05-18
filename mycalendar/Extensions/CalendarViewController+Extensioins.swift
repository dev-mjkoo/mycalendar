//
//  CalendarViewController+Extensioins.swift
//  mycalendar
//
//  Created by 구민준 on 5/18/25.
//
import UIKit
import EventKit

extension CalendarViewController: UICollectionViewDataSourcePrefetching {
    func collectionView(_ collectionView: UICollectionView, prefetchItemsAt indexPaths: [IndexPath]) {
        for indexPath in indexPaths {
            let month = visibleMonths[indexPath.item]
            let key = calendar.startOfMonth(for: month)

            guard eventsByMonth[key] == nil else { continue }

            EventKitManager.shared.fetchEvents(for: month) { events in
                DispatchQueue.main.async {
                    self.setEvents(for: month, events: events)
                }
            }
        }
    }
}

extension CalendarViewController: UIScrollViewDelegate {
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        onScroll?()
    }
}
