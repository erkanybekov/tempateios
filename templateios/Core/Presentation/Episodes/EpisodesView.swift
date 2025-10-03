//
//  EpisodesView.swift
//  templateios
//
//  Created by Erlan Kanybekov on 5/21/25.
//

import SwiftUI
// Placeholder view for episodes tab
struct EpisodesView: View {
    @State private var list = [
        "Hello",
        "World",
        "SwiftUI",
        "Kotlin",
        "Swift",
        "Dart"
    ]
    var body: some View {
        NavigationView {
            List {
                ForEach(list, id: \.self) { text in
                    NavigationLink(destination: MyView(text: text)) {
                        Text(text)
                    }
                                        
                }
            }
            .navigationTitle("List")
            //            VStack {
            //                Image(systemName: "tv")
            //                    .font(.system(size: 70))
            //                    .foregroundColor(AppTheme.Colors.secondary)
            //                    .padding()
            //                
            //                Text("Episodes")
            //                    .font(AppTheme.Typography.title)
            //                    .padding()
            //                
            //                Text("Coming soon...")
            //                    .font(AppTheme.Typography.subheadline)
            //                    .foregroundColor(AppTheme.Colors.secondaryText)
            //            }
        }
    }
}

#Preview {
    EpisodesView()
}

struct MyView: View {
    let text:String
    var body: some View {
        VStack {
            Text(text)
        }
    }
}
