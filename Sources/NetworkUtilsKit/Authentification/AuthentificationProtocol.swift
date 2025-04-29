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
    
    /// Auth query params
    var urlQueryItems: [URLQueryItem] { get }
}

extension AuthentificationProtocol {
    
    /// Auth headeres
    public var headers: Headers { [:] }
        
    /// Auth query params
    public var urlQueryItems: [URLQueryItem] { [] }
}

extension Array: AuthentificationProtocol where Element == AuthentificationProtocol {
    
    public var headers: Headers {
        self.reduce(into: [:]) { headers, new in
            let value: Headers = new.headers
			headers = headers.merging(value) { current, _ in current }
        }
    }
	
	public var urlQueryItems: [URLQueryItem] {
		self.flatMap { $0.urlQueryItems }
	}
}

extension AuthentificationProtocol {
	
	func refreshIfNeeded(from request: URLRequest?) async {
		if let authent = self as? AuthentificationRefreshableProtocol, !authent.isValid {
			try? await authent.refresh(from: request)
		}
		
		if let authents = (self as? [AuthentificationProtocol])?.compactMap({ $0 as? AuthentificationRefreshableProtocol }) {
			for authent in authents where !authent.isValid {
				try? await authent.refresh(from: request)
			}
		}
	}
}
