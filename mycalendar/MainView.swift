import SwiftUI

struct MainView: View {
    @State private var currentDate = Date()
    
    var body: some View {
        NavigationView {
            VStack {
                // 여기에 메인 캘린더 뷰가 들어갈 예정
                Text("캘린더가 여기에 표시됩니다")
                    .font(.title)
            }
            .navigationTitle("캘린더")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    NavigationLink(destination: SettingsView()) {
                        Image(systemName: "gear")
                    }
                }
            }
        }
    }
}

struct MainView_Previews: PreviewProvider {
    static var previews: some View {
        MainView()
    }
} 