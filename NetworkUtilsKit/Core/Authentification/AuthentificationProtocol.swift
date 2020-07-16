//
//  AuthentificationProtocol.swift
//  UtilsKit
//
//  Created by RGMC on 18/10/2018.
//  Copyright © 2018 RGMC. All rights reserved.
//

import Foundation

/**
 Authentification encoding
 */
public enum AuthentificationEncoding {
    
    /// Encode parameters in request header
    case header
    
    /// Encode parameters in body
    case body
    
    /// Encode parameters in URL
    case url
}

/**
 This protocol is used to authenticate a request with the chosen encoding and parameters
 */
public protocol AuthentificationProtocol {
    
    /// The parameters to encode
    var parameters: [String: String] { get }
    
    /// The type of the encoding
    var encoding: AuthentificationEncoding { get }
}
