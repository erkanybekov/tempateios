//
//  FavoritesView.swift
//  templateios
//
//  Created by Erlan Kanybekov on 5/21/25.
//
import SwiftUI

// Placeholder view for favorites tab
struct FavoritesView: View {
    var body: some View {
        NavigationView {
            VStack {
                Image(systemName: "star")
                    .font(.system(size: 70))
                    .foregroundColor(AppTheme.Colors.secondary)
                    .padding()
                
                Text("Favorites")
                    .font(AppTheme.Typography.title)
                    .padding()
                
                Text("Coming soon...")
                    .font(AppTheme.Typography.subheadline)
                    .foregroundColor(AppTheme.Colors.secondaryText)
            }
            .navigationTitle("Favorites")
        }
    }
}
