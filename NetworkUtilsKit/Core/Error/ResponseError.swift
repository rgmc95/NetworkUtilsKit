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
    case decodable(type: String?,
                   message: String? = nil)
    case data
    case json
    case network(response: HTTPURLResponse?)
    case noMock
    
    public var errorDescription: String? {
        switch self {
        case .unknow:
            return "Response error"
            
        case .decodable (let type, let message):
            return "Decode error for type \(type ?? "") \(message ?? "")"
            
        case .data:
            return "Data error"
            
        case .json:
            return "JSON error"
            
        case .network(let response):
            guard let statusCode = response?.statusCode else { return "Unkown Error" }
            return "\(statusCode): \(HTTPURLResponse.localizedString(forStatusCode: statusCode))"
            
        case .noMock:
            return "No mock file found"
        }
    }

    public var code: Int {
        switch self {
        case .unknow:
            return -1

        case .decodable:
            return -2

        case .data:
            return -3

        case .json:
            return -4

        case .network(let response):
            return response?.statusCode ?? -5 

        case .noMock:
            return -6
        }
    }
}
