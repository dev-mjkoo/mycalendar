//
//  EventEditView.swift
//  mycalendar
//
//  Created by 구민준 on 5/23/25.
//

import SwiftUI
import EventKit
import EventKitUI

struct EventEditView: UIViewControllerRepresentable {
    @Environment(\.presentationMode) var presentationMode

    func makeCoordinator() -> Coordinator {
        return Coordinator(parent: self)
    }

    func makeUIViewController(context: Context) -> EKEventEditViewController {
        let eventStore = EKEventStore()
        let event = EKEvent(eventStore: eventStore)
        event.startDate = Date()
        event.endDate = event.startDate.addingTimeInterval(60 * 60) // 1시간 이벤트

        let vc = EKEventEditViewController()
        vc.eventStore = eventStore
        vc.event = event
        vc.editViewDelegate = context.coordinator
        return vc
    }

    func updateUIViewController(_ uiViewController: EKEventEditViewController, context: Context) {}

    class Coordinator: NSObject, EKEventEditViewDelegate {
        let parent: EventEditView

        init(parent: EventEditView) {
            self.parent = parent
        }

        func eventEditViewController(_ controller: EKEventEditViewController, didCompleteWith action: EKEventEditViewAction) {
            controller.dismiss(animated: true) {
                self.parent.presentationMode.wrappedValue.dismiss()
            }
        }
    }
}
