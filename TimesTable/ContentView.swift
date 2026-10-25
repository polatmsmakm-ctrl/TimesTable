import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            DrillView()
                .tabItem { Label("تدريب", systemImage: "bolt.fill") }
            MapView()
                .tabItem { Label("الخريطة", systemImage: "square.grid.3x3.fill") }
            TricksView()
                .tabItem { Label("الحيل", systemImage: "lightbulb.fill") }
            LogView()
                .tabItem { Label("السجل", systemImage: "chart.bar.fill") }
        }
        .tint(Theme.gold)
    }
}
