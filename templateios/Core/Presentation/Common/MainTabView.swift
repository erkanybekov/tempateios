import SwiftUI

struct MainTabView: View {
    @State private var selectedTab = 0
    private let diContainer = DIContainer.shared
    
    var body: some View {
        TabView(selection: $selectedTab) {
            CharactersListView(viewModel: diContainer.resolveCharactersViewModel())
                .tabItem {
                    Label("Characters", systemImage: "person.3")
                }
                .tag(0)
            
            LocationsView()
                .tabItem {
                    Label("Locations", systemImage: "map")
                }
                .tag(1)
            
            EpisodesView()
                .tabItem {
                    Label("Episodes", systemImage: "tv")
                }
                .tag(2)
            
            FavoritesView()
                .tabItem {
                    Label("Favorites", systemImage: "star")
                }
                .tag(3)
        }
        .accentColor(AppTheme.Colors.secondary)  // Use Rick and Morty green color for selected tab
        .onAppear {
            // Set tab bar appearance
            let appearance = UITabBarAppearance()
            appearance.configureWithOpaqueBackground()
            
            // To avoid appearance changes when scrolling
            UITabBar.appearance().scrollEdgeAppearance = appearance
            
            // Add a subtle shadow to the tab bar
            appearance.shadowColor = .gray
            appearance.shadowImage = UIImage()
            
            // Set the tab bar style
            UITabBar.appearance().standardAppearance = appearance
        }
    }
}



