//
//  ResponseError.swift
//  NetworkUtilsKit
//
//  Created by Michael Coqueret on 14/01/2021.
//  Copyright © 2021 RGMC. All rights reserved.
//

import UtilsKit

// MARK: - Error
public enum ResponseError: Error, LocalizedError {
    case unknow
    case decodable
    case data
    case json
    case network(response: HTTPURLResponse?)
    case noMock
    
    public var errorDescription: String? {
        switch self {
        case .unknow: return "Response error"
        case .decodable: return "Decode error"
        case .data: return "Data error"
        case .json: return "JSON error"
        case .network(let response):
            guard let statusCode = response?.statusCode else { return nil }
            return "\(statusCode): \(HTTPURLResponse.localizedString(forStatusCode: statusCode))"
        case .noMock: return "No mock file found"
        }
    }
}
