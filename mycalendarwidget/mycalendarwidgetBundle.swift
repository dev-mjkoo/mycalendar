//
//  mycalendarwidgetBundle.swift
//  mycalendarwidget
//
//  Created by 구민준 on 4/25/25.
//

import WidgetKit
import SwiftUI
import ActivityKit

@main
struct mycalendarwidgetBundle: WidgetBundle {
    var body: some Widget {
        mycalendarwidget()
        mycalendarwidgetLiveActivity()
    }
}
