//
//  RequestProtocol+Promise.swift
//  NetworkKit
//
//  Created by Michael Coqueret on 10/07/2020.
//  Copyright © 2020 RGMC. All rights reserved.
//

import Foundation
import PromiseKit

extension RequestProtocol where Self: ResponseProtocol {
    
    /**
        Get the decoded response of `Decodable` type based
     */
    public func response() -> Promise<ResponseType> {
        Promise { resolver in
            self.response { results in
                switch results {
                case .success(let response):
                    resolver.fulfill(response)
                    
                case .failure(let error):
                    resolver.reject(error)
                }
            }
        }
    }
}

extension RequestProtocol {
    
    /**
        Send request and return response or error
     */
    public func responseData() -> Promise<Data?> {
        Promise { resolver in
            self.responseData { results in
                switch results {
                case .success(let response): resolver.fulfill(response.data)
                case .failure(let error): resolver.reject(error)
                }
            }
        }
    }
}
