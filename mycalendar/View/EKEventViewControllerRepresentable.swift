//
//  EKEventViewControllerRepresentable.swift
//  mycalendar
//
//  Created by 구민준 on 5/26/25.
//

import SwiftUI
import EventKit
import EventKitUI

struct EKEventViewControllerRepresentable: UIViewControllerRepresentable {
    let event: EKEvent

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    func makeUIViewController(context: Context) -> UINavigationController {
        let eventVC = EKEventViewController()
        eventVC.event = event
        eventVC.allowsEditing = true
        eventVC.allowsCalendarPreview = true
        eventVC.delegate = context.coordinator

        let navController = UINavigationController(rootViewController: eventVC)
        return navController
    }

    func updateUIViewController(_ uiViewController: UINavigationController, context: Context) {}

    class Coordinator: NSObject, EKEventViewDelegate {
        func eventViewController(_ controller: EKEventViewController, didCompleteWith action: EKEventViewAction) {
            controller.dismiss(animated: true, completion: nil)
        }
    }
}
