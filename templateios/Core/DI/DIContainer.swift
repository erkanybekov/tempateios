import Foundation
import Swinject

class DIContainer {
    static let shared = DIContainer()
    
    let container = Container()
    
    private init() {
        registerDependencies()
    }
    
    private func registerDependencies() {
        // Network
        container.register(APIClientProtocol.self) { _ in
            APIClient()
        }.inObjectScope(.container)
        
        container.register(RickAndMortyAPIProtocol.self) { resolver in
            RickAndMortyAPI(apiClient: resolver.resolve(APIClientProtocol.self)!)
        }.inObjectScope(.container)
        
        // Repositories
        container.register(CharacterRepositoryProtocol.self) { resolver in
            CharacterRepository(api: resolver.resolve(RickAndMortyAPIProtocol.self)!)
        }.inObjectScope(.container)
        
        // Use Cases
        container.register(GetCharactersUseCaseProtocol.self) { resolver in
            GetCharactersUseCase(repository: resolver.resolve(CharacterRepositoryProtocol.self)!)
        }.inObjectScope(.container)
        
        // View Models
        container.register(CharactersViewModel.self) { resolver in
            CharactersViewModel(getCharactersUseCase: resolver.resolve(GetCharactersUseCaseProtocol.self)!)
        }
    }
    
    func resolveCharactersViewModel() -> CharactersViewModel {
        return container.resolve(CharactersViewModel.self)!
    }
} 