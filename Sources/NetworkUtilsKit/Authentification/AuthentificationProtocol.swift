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
public protocol AuthentificationProtocol: Sendable {
    
    /// Auth headeres
    var headers: Headers { get async }
    
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
		get async {
			var headers: Headers = [:]
			
			for new in self {
				let value: Headers = await new.headers
				headers = headers.merging(value) { current, _ in current }
			}
			
			return headers
		}
    }
	
	public var urlQueryItems: [URLQueryItem] {
		self.flatMap { $0.urlQueryItems }
	}
}

extension AuthentificationProtocol {
	
	nonisolated func refreshIfNeeded(from request: URLRequest?) async {
		if let authent = self as? AuthentificationRefreshableProtocol, await !authent.isValid {
			try? await authent.refresh(from: request)
		}
		
		if let authents = (self as? [AuthentificationProtocol])?.compactMap({ $0 as? AuthentificationRefreshableProtocol }) {
			for authent in authents where await !authent.isValid {
				try? await authent.refresh(from: request)
			}
		}
	}
}
