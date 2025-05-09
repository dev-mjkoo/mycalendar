import SwiftUI

struct MainView: View {
    @State private var currentDate = Date()
    
    var body: some View {
        NavigationView {
            VStack {
                        UIKitCalendarView()
                            .edgesIgnoringSafeArea(.all)
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
