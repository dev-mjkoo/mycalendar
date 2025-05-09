//
//  mycalendarApp.swift
//  mycalendar
//
//  Created by 구민준 on 4/25/25.
//

//이제 구현이 완료되었습니다. 동작 방식을 설명드리면:
//앱이 처음 실행되고 캘린더 동기화를 켜면:
//현재 달(4월)의 이벤트만 가져옵니다.
//syncedMonths에 "2024-04" 추가
//5월로 스와이프하면:
//currentMonth가 변경되어 onChange 이벤트 발생
//onMonthChange()가 호출되어 syncWithCalendar() 실행
//5월이 syncedMonths에 없으므로 5월 데이터만 가져옴
//syncedMonths에 "2024-05" 추가
//다시 4월로 돌아와도:
//"2024-04"가 이미 syncedMonths에 있으므로 데이터를 다시 가져오지 않음
//이렇게 하면 각 달의 데이터를 한 번만 가져오게 되어 효율적으로 동작합니다. 테스트해보시겠습니까?

import SwiftUI
import SwiftData
import ActivityKit

@main
struct mycalendarApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(sharedModelContainer)
    }
}

