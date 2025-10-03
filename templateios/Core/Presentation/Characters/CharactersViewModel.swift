import Foundation
import Combine

enum CharactersViewState {
    case initial
    case loading
    case loaded([Character])
    case loadingMore([Character])
    case error(Error)
}

protocol PaginationControllerProtocol {
    func loadNextPageIfNeeded(currentIndex: Int)
    func reset()
}

class PaginationController: PaginationControllerProtocol {
    private let threshold: Int
    private let pageSize: Int
    private let loadAction: (Int) -> Void
    private var isLoading = false
    private var hasMorePages = true
    private var currentPage = 1
    
    init(threshold: Int = 5, pageSize: Int = 20, loadAction: @escaping (Int) -> Void) {
        self.threshold = threshold
        self.pageSize = pageSize
        self.loadAction = loadAction
    }
    
    func loadNextPageIfNeeded(currentIndex: Int) {
        guard !isLoading, hasMorePages else { return }
        let thresholdIndex = (currentPage * pageSize) - threshold
        if currentIndex >= thresholdIndex {
            isLoading = true
            loadAction(currentPage + 1)
        }
    }
    
    func reset() {
        currentPage = 1
        isLoading = false
        hasMorePages = true
    }
}

class CharactersViewModel: ObservableObject {
    @Published private(set) var state: CharactersViewState = .initial
    
    private let getCharactersUseCase: GetCharactersUseCaseProtocol
    private var currentPage = 1
    private var totalPages = 1
    private var characters: [Character] = []
    
    init(getCharactersUseCase: GetCharactersUseCaseProtocol) {
        self.getCharactersUseCase = getCharactersUseCase
    }
    
    @MainActor
    func loadCharacters() async {
        guard case .initial = state else { return }
        
        state = .loading
        
        do {
            let response = try await getCharactersUseCase.execute(page: currentPage)
            characters = response.results
            totalPages = response.info.pages
            state = .loaded(characters)
        } catch {
            state = .error(error)
        }
    }
    
    @MainActor
    func loadMoreCharactersIfNeeded(character: Character) async {
        guard !characters.isEmpty else { return }
        
        let thresholdIndex = characters.index(characters.endIndex, offsetBy: -5)
        if characters.firstIndex(where: { $0.id == character.id }) == thresholdIndex, currentPage < totalPages {
            await loadMoreCharacters()
        }
    }
    
    @MainActor
    private func loadMoreCharacters() async {
        guard case .loaded = state, currentPage < totalPages else { return }
        
        state = .loadingMore(characters)
        currentPage += 1
        
        do {
            let response = try await getCharactersUseCase.execute(page: currentPage)
            characters.append(contentsOf: response.results)
            state = .loaded(characters)
        } catch {
            state = .error(error)
            currentPage -= 1
        }
    }
} 