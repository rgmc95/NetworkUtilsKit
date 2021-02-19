//
//  AuthentificationProtocol.swift
//  UtilsKit
//
//  Created by RGMC on 18/10/2018.
//  Copyright © 2018 RGMC. All rights reserved.
//

import Foundation

/**
 This protocol is used to authenticate a request with the chosen headers, body parameters or/and url query parameters
 */
public protocol AuthentificationProtocol {
    
    /// Auth headeres
    var headers: Headers { get }
    
    /// Auth params
    var bodyParameters: Parameters { get }
    
    /// Auth query params
    var urlQueryItems: [URLQueryItem] { get }
}

extension AuthentificationProtocol {
    
    /// Auth headeres
    public var headers: Headers { [:] }
    
    /// Auth params
    public var bodyParameters: Parameters { [:] }
    
    /// Auth query params
    public var urlQueryItems: [URLQueryItem] { [] }
}

extension Array: AuthentificationProtocol where Element == AuthentificationProtocol {
    
    public var headers: Headers {
        self.reduce(into: [:]) { headers, new in
            let value: Headers = new.headers
            _ = headers.merging(value) { current, _ in current }
        }
    }
    
    public var bodyParameters: Parameters {
        self.reduce(into: [:]) { params, new in
            let value: Parameters = new.bodyParameters
            _ = params.merging(value) { current, _ in current }
        }
    }
    
    public var urlQueryItems: [URLQueryItem] {
        self.flatMap { $0.urlQueryItems }
    }
}
