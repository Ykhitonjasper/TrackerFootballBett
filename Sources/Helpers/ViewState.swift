import Foundation

enum ViewState<T> {
    case idle
    case loading
    case loaded(T)
    case empty
    case error(String)

    var isLoading: Bool {
        if case .loading = self { return true }
        return false
    }

    var errorMessage: String? {
        if case .error(let message) = self { return message }
        return nil
    }
}

struct BettingError: LocalizedError, Identifiable {
    let id = UUID()
    let message: String

    var errorDescription: String? { message }

    static let invalidStake = BettingError(message: "Enter a valid stake amount.")
    static let insufficientFunds = BettingError(message: "Insufficient balance for this stake.")
    static let matchClosed = BettingError(message: "This market is no longer open.")
    static let profileMissing = BettingError(message: "User profile not found.")
    static let saveFailed = BettingError(message: "Could not save your bet. Try again.")
}
