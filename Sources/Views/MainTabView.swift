import SwiftUI

struct MainTabView: View {
    var body: some View {
        TabView {
            NavigationStack { CompanyListView() }
                .tabItem { Label("企业列表", systemImage: "list.bullet") }
            NavigationStack { StatisticsView() }
                .tabItem { Label("统计", systemImage: "chart.pie") }
            NavigationStack { SettingsView() }
                .tabItem { Label("设置", systemImage: "gearshape") }
        }
        .tint(Color(red: 0.10, green: 0.45, blue: 0.85))
    }
}
