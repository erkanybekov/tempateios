import Foundation

protocol GetCharactersUseCaseProtocol {
    func execute(page: Int) async throws -> CharactersResponse
}

class GetCharactersUseCase: GetCharactersUseCaseProtocol {
    private let repository: CharacterRepositoryProtocol
    
    init(repository: CharacterRepositoryProtocol) {
        self.repository = repository
    }
    
    func execute(page: Int) async throws -> CharactersResponse {
        return try await repository.getCharacters(page: page)
    }
} 