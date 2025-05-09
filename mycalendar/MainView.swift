import SwiftUI

struct MainView: View {
    @State private var scrollToToday: Bool = false
    @State private var hasAppeared = false //최초 1회만 실행되도록 hasAppeared 플래그 추가
    @State private var currentMonthText: String = "캘린더"
    @State private var selectedDate: Date? = nil

    
    var body: some View {
        VStack(spacing: 0) {
            weekdayHeader
            UIKitCalendarView(
                        currentMonthText: $currentMonthText,
                        scrollToToday: $scrollToToday,
                        selectedDate: $selectedDate
                    )
            // todo : 나중에 여기서 하단 sheet를 띄워서 일별 상세 보여줘도되겟다..
            
//            if let selected = selectedDate {
//                Text("선택한 날짜: \(selected.formatted(date: .long, time: .omitted))")
//                    .padding()
//            }
        }
        .navigationTitle(currentMonthText)
        .toolbar {
            ToolbarItemGroup(placement: .navigationBarTrailing) {
                Button("오늘") {
                    scrollToToday.toggle()
                }

                NavigationLink(destination: SettingsView()) {
                    Image(systemName: "gear")
                }
            }
        }
        
        .onAppear {
            if !hasAppeared {
                hasAppeared = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    scrollToToday = true
                }
            }
        }
    }
    
    var weekdayHeader: some View {
        HStack {
            ForEach(["일", "월", "화", "수", "목", "금", "토"], id: \.self) { day in
                Text(day)
                    .foregroundColor(day == "일" ? .red : day == "토" ? .blue : .primary)
                    .frame(maxWidth: .infinity)
            }
        }
        .padding(.vertical, 4)
    }
    
    
    
    
    
}

struct MainView_Previews: PreviewProvider {
    static var previews: some View {
        MainView()
    }
}
