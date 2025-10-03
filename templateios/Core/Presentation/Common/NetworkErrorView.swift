import SwiftUI

struct NetworkErrorView: View {
    let error: Error
    let retryAction: () -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "wifi.slash")
                .font(.system(size: 50))
                .foregroundColor(.red)
            
            Text("Network Error")
                .font(.title)
            
            Text(errorMessage)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            Button("Try Again") {
                retryAction()
            }
            .padding()
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(8)
        }
        .padding()
    }
    
    private var errorMessage: String {
        switch error {
        case is APIError:
            let apiError = error as! APIError
            switch apiError {
            case .noInternetConnection:
                return "No internet connection. Please check your network settings and try again."
            case .serverError(let code):
                return "Server error occurred (Code: \(code)). Please try again later."
            case .decodingFailed:
                return "Failed to process the server response. Please try again."
            default:
                return "Something went wrong. Please try again."
            }
        default:
            return error.localizedDescription
        }
    }
} 