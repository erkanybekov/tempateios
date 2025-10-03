import SwiftUI
import Kingfisher

struct CharacterDetailView: View {
    let character: Character
    @State private var isFavorite: Bool = false
    
    var body: some View {
        ScrollView {
            VStack(alignment: .center, spacing: 16) {
                // Character image
                KFImage(URL(string: character.image))
                    .resizable()
                    .placeholder {
                        ProgressView()
                    }
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 200, height: 200)
                    .cornerRadius(16)
                    .shadow(radius: 5)
                    .padding(.top)
                
                // Character name
                Text(character.name)
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)
                
                // Status indicator
                HStack {
                    Circle()
                        .fill(statusColor)
                        .frame(width: 12, height: 12)
                    
                    Text(character.status.rawValue)
                        .font(.headline)
                }
                .padding(.vertical, 4)
                
                // Species and gender
                InfoRow(title: "Species", value: character.species)
                InfoRow(title: "Gender", value: character.gender.rawValue)
                
                if !character.type.isEmpty {
                    InfoRow(title: "Type", value: character.type)
                }
                
                Divider()
                
                // Origin
                VStack(alignment: .leading, spacing: 8) {
                    Text("Origin")
                        .font(.headline)
                        .padding(.leading)
                    
                    InfoCard(title: character.origin.name)
                }
                
                // Current location
                VStack(alignment: .leading, spacing: 8) {
                    Text("Last Known Location")
                        .font(.headline)
                        .padding(.leading)
                    
                    InfoCard(title: character.location.name)
                }
                
                // Episodes
                VStack(alignment: .leading, spacing: 8) {
                    Text("Featured in \(character.episode.count) episodes")
                        .font(.headline)
                        .padding(.leading)
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(1...min(character.episode.count, 10), id: \.self) { index in
                                EpisodeBadge(number: index)
                            }
                            
                            if character.episode.count > 10 {
                                Text("+\(character.episode.count - 10) more")
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 8)
                                    .background(Color.gray.opacity(0.2))
                                    .cornerRadius(20)
                            }
                        }
                        .padding(.horizontal)
                    }
                }
                
                Spacer()
            }
            .padding()
        }
        .navigationBarTitle("", displayMode: .inline)
        .navigationBarItems(trailing: Button(action: {
            isFavorite.toggle()
        }) {
            Image(systemName: isFavorite ? "star.fill" : "star")
                .foregroundColor(isFavorite ? .yellow : .gray)
        })
    }
    
    private var statusColor: Color {
        switch character.status {
        case .alive:
            return .green
        case .dead:
            return .red
        case .unknown:
            return .gray
        }
    }
}

struct InfoRow: View {
    let title: String
    let value: String
    
    var body: some View {
        HStack {
            Text(title + ":")
                .font(.headline)
                .foregroundColor(.secondary)
            
            Text(value)
                .font(.body)
            
            Spacer()
        }
        .padding(.horizontal)
        .padding(.vertical, 4)
    }
}

struct InfoCard: View {
    let title: String
    
    var body: some View {
        Text(title)
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(.secondarySystemBackground))
            .cornerRadius(10)
            .padding(.horizontal)
    }
}

struct EpisodeBadge: View {
    let number: Int
    
    var body: some View {
        Text("E\(number)")
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color.green.opacity(0.2))
            .foregroundColor(.green)
            .cornerRadius(20)
    }
} 