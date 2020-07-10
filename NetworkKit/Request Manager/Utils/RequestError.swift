//
//  RequestError.swift
//  UtilsKit
//
//  Created by RGMC on 17/07/2019.
//  Copyright © 2019 RGMC. All rights reserved.
//

import Foundation

// MARK: - Network error Enum
public enum RequestError: Error, LocalizedError {
    case url, json
    
    /// Request status code
    internal var statusCode: Int? {
        switch self {
        case .url, .json: return 400
        }
    }
    
    public var errorDescription: String? {
        switch self {
        case .url: return "Invalid URL"
        case .json: return "Invalid JSON"
        }
    }
}
