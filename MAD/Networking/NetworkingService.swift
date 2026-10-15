//
//  NetworkingService.swift
//  MAD
//
//  Created by Fabian Gerö on 15.10.26.
//


import Foundation

final class NetworkingService {
    private let session = URLSession(configuration: .default)
    private let apiKey = "replace api key"

    func login(
        email: String,
        password: String,
        completionHandler: @escaping @MainActor (User?, NetworkingError?) -> Void
    ) {
        guard let url = URL(string: "https://identitytoolkit.googleapis.com/v1/accounts:signInWithPassword?key=\(apiKey)") else {
            DispatchQueue.main.async {
                completionHandler(nil, .unexpected("The login URL is invalid."))
            }
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body: [String: Any] = [
            "email": email,
            "password": password,
            "returnSecureToken": true
        ]

        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: body, options: [])
        } catch {
            let description = error.localizedDescription
            DispatchQueue.main.async {
                completionHandler(nil, .serializationFailed(description))
            }
            return
        }

        let task = session.dataTask(with: request) { data, response, error in
            let (user, networkingError) = NetworkingService.handleResponse(data: data, response: response, error: error)

            DispatchQueue.main.async {
                completionHandler(user, networkingError)
            }
        }

        task.resume()
    }

    nonisolated private static func handleResponse(data: Data?, response: URLResponse?, error: Error?) -> (User?, NetworkingError?) {
        if let error = error as NSError? {
            let offlineCodes = [
                NSURLErrorNotConnectedToInternet,
                NSURLErrorNetworkConnectionLost,
                NSURLErrorDataNotAllowed
            ]

            if error.domain == NSURLErrorDomain, offlineCodes.contains(error.code) {
                return (nil, .offline(error.localizedDescription))
            }

            return (nil, .unexpected(error.localizedDescription))
        }

        guard let httpResponse = response as? HTTPURLResponse, let data else {
            return (nil, .invalidResponseFormat)
        }

        guard (200..<300).contains(httpResponse.statusCode) else {
            return (nil, networkingError(from: data, statusCode: httpResponse.statusCode))
        }

        guard let user = try? JSONDecoder().decode(User.self, from: data) else {
            return (nil, .invalidResponseFormat)
        }

        return (user, nil)
    }

    nonisolated private static func networkingError(from data: Data, statusCode: Int) -> NetworkingError {
        guard let responseError = try? JSONDecoder().decode(ResponseError.self, from: data) else {
            return .serverError(statusCode: statusCode, message: nil)
        }

        let message = responseError.error.message
        let errorCode = message.components(separatedBy: " : ").first ?? message

        switch errorCode {
        case "INVALID_EMAIL":
            return .invalidEmail
        case "EMAIL_NOT_FOUND":
            return .emailNotFound
        case "INVALID_PASSWORD":
            return .wrongPassword
        case "INVALID_LOGIN_CREDENTIALS":
            return .invalidCredentials
        default:
            return .serverError(statusCode: statusCode, message: message)
        }
    }
}
