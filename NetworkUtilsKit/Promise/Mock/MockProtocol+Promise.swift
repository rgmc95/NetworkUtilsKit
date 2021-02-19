//
//  MockProtocol+Promise.swift
//  NetworkUtilsKit
//
//  Created by Michael Coqueret on 19/02/2021.
//

import PromiseKit

extension MockProtocol {
    
    /**
        Send request and return response or error
     */
    public func mock() -> Promise<Data?> {
        Promise { resolver in
            self.mock { results in
                switch results {
                case .success(let response): resolver.fulfill(response.data)
                case .failure(let error): resolver.reject(error)
                }
            }
        }
    }
    
    /**
        Send request and return response or error
     */
    public func mock<T: Decodable>(_ type: T.Type) -> Promise<T> {
        Promise { resolver in
            self.mock(type) { results in
                switch results {
                case .success(let response): resolver.fulfill(response)
                case .failure(let error): resolver.reject(error)
                }
            }
        }
    }
}
