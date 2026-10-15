//
//  NetworkingError.swift
//  MAD
//
//  Created by Fabian Gerö on 15.10.26.
//


import Foundation

nonisolated enum NetworkingError: Error {
    case serializationFailed(String)
    case invalidEmail
    case emailNotFound
    case wrongPassword
    case invalidCredentials
    case offline(String)
    case invalidResponseFormat
    case serverError(statusCode: Int, message: String?)
    case unexpected(String)
}