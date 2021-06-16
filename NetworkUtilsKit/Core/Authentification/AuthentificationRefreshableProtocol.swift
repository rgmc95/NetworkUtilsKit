//
//  AuthentificationRefreshableProtocol.swift
//  NetworkUtilsKit
//
//  Created by Michael Coqueret on 15/06/2021.
//  Copyright © 2021 RGMC. All rights reserved.
//

import Foundation

public protocol AuthentificationRefreshableProtocol: AuthentificationProtocol {
	
	func refresh(from request: URLRequest, completion: @escaping (Result<Void, Error>) -> Void)
}
