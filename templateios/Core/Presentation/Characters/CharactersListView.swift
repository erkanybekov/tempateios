import SwiftUI
import Kingfisher

struct CharactersListView: View {
    @ObservedObject var viewModel: CharactersViewModel
    
    var body: some View {
        NavigationView {
            ZStack {
                switch viewModel.state {
                case .initial:
                    Color.clear.onAppear {
                        Task {
                            await viewModel.loadCharacters()
                        }
                    }
                case .loading:
                    ProgressView()
                        .scaleEffect(1.5)
                case .loaded(let characters), .loadingMore(let characters):
                    charactersList(characters)
                case .error(let error):
                    NetworkErrorView(error: error) {
                        Task {
                            await viewModel.loadCharacters()
                        }
                    }
                }
            }
            .navigationTitle("Rick & Morty")
        }
    }
    
    private func charactersList(_ characters: [Character]) -> some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                ForEach(characters) { character in
                    NavigationLink(destination: CharacterDetailView(character: character)) {
                        CharacterCell(character: character)
                            .onAppear {
                                Task {
                                    await viewModel.loadMoreCharactersIfNeeded(character: character)
                                }
                            }
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                
                if case .loadingMore = viewModel.state {
                    ProgressView()
                        .padding()
                }
            }
            .padding()
        }
    }
}

struct CharacterCell: View {
    let character: Character
    
    var body: some View {
        HStack(spacing: 16) {
            KFImage(URL(string: character.image))
                .resizable()
                .placeholder {
                    ProgressView()
                }
                .aspectRatio(contentMode: .fill)
                .frame(width: 80, height: 80)
                .cornerRadius(8)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(character.name)
                    .font(.headline)
                    .foregroundColor(.primary)
                
                HStack {
                    Circle()
                        .fill(statusColor)
                        .frame(width: 10, height: 10)
                    
                    Text(character.status.rawValue)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Text("\(character.species) - \(character.gender.rawValue)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Text("Last known location:")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text(character.location.name)
                    .font(.subheadline)
                    .foregroundColor(.primary)
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .foregroundColor(.gray)
                .padding(.trailing, 8)
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
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