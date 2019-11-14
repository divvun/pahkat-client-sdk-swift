import Foundation

public struct PahkatClientError: Error {
    public let message: String
}

internal func assertNoError() throws {
    if pahkat_client_err != nil {
        let error = String(cString: pahkat_client_err!)
        pahkat_client_err_free()
        throw PahkatClientError(message: error)
    }
}
