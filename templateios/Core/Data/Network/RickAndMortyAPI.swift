import Foundation
import Alamofire

protocol RickAndMortyAPIProtocol {
    func getCharacters(page: Int) async throws -> CharactersResponse
    func getCharacter(id: Int) async throws -> Character
}

class RickAndMortyAPI: RickAndMortyAPIProtocol {
    private let apiClient: APIClientProtocol
    private let baseURL = "https://rickandmortyapi.com/api"
    
    init(apiClient: APIClientProtocol) {
        self.apiClient = apiClient
    }
    
    func getCharacters(page: Int) async throws -> CharactersResponse {
        let endpoint = APIEndpoint(
            url: "\(baseURL)/character",
            parameters: ["page": page]
        )
        
        return try await apiClient.request(endpoint: endpoint, responseType: CharactersResponse.self)
    }
    
    func getCharacter(id: Int) async throws -> Character {
        let endpoint = APIEndpoint(
            url: "\(baseURL)/character/\(id)"
        )
        
        return try await apiClient.request(endpoint: endpoint, responseType: Character.self)
    }
} 