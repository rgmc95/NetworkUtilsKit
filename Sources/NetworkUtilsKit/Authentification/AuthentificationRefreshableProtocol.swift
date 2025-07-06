//
//  AuthentificationRefreshableProtocol.swift
//  NetworkUtilsKit
//
//  Created by Michael Coqueret on 15/06/2021.
//  Copyright © 2021 RGMC. All rights reserved.
//

import Foundation

#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

public protocol AuthentificationRefreshableProtocol: AuthentificationProtocol, Sendable {
	
	var isValid: Bool { get }
    
    func refresh(from request: URLRequest?) async throws
}
