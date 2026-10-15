//
//  ResponseError.swift
//  MAD
//
//  Created by Fabian Gerö on 15.10.26.
//


import Foundation

nonisolated struct ResponseError: Codable {
    let error: ErrorDetails

    struct ErrorDetails: Codable {
        let code: Int
        let message: String
        let errors: [ErrorItem]
    }

    struct ErrorItem: Codable {
        let message: String
        let domain: String
        let reason: String
    }
}