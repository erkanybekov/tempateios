import Foundation
import Alamofire

enum APIError: Error {
    case requestFailed(Error)
    case invalidResponse
    case decodingFailed(Error)
    case serverError(Int)
    case noInternetConnection
    case unknown
}

protocol APIClientProtocol {
    func request<T: Decodable>(endpoint: APIEndpoint, responseType: T.Type) async throws -> T
}

class APIClient: APIClientProtocol {
    private let session: Session
    
    init(session: Session = .default) {
        self.session = session
    }
    
    func request<T: Decodable>(endpoint: APIEndpoint, responseType: T.Type) async throws -> T {
        return try await withCheckedThrowingContinuation { continuation in
            session.request(
                endpoint.url,
                method: endpoint.method,
                parameters: endpoint.parameters,
                encoding: endpoint.encoding,
                headers: endpoint.headers
            )
            .validate()
            .responseDecodable(of: responseType) { response in
                switch response.result {
                case .success(let value):
                    continuation.resume(returning: value)
                case .failure(let error):
                    if let statusCode = response.response?.statusCode {
                        continuation.resume(throwing: APIError.serverError(statusCode))
                    } else if let underlyingError = error.underlyingError as NSError?, underlyingError.domain == NSURLErrorDomain {
                        continuation.resume(throwing: APIError.noInternetConnection)
                    } else if let decodingError = error.underlyingError as? DecodingError {
                        continuation.resume(throwing: APIError.decodingFailed(decodingError))
                    } else {
                        continuation.resume(throwing: APIError.requestFailed(error))
                    }
                }
            }
        }
    }
} 
