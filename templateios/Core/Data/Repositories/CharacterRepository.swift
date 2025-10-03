import Foundation

protocol CharacterRepositoryProtocol {
    func getCharacters(page: Int) async throws -> CharactersResponse
    func getCharacter(id: Int) async throws -> Character
}

class CharacterRepository: CharacterRepositoryProtocol {
    private let api: RickAndMortyAPIProtocol
    
    init(api: RickAndMortyAPIProtocol) {
        self.api = api
    }
    
    func getCharacters(page: Int) async throws -> CharactersResponse {
        return try await api.getCharacters(page: page)
    }
    
    func getCharacter(id: Int) async throws -> Character {
        return try await api.getCharacter(id: id)
    }
} 