//
//  RequestProtocol+Response.swift
//  NetworkUtilsKit
//
//  Created by Michael Coqueret on 22/10/2021.
//  Copyright © 2021 RGMC. All rights reserved.
//

import Foundation
import OSLog

#if canImport(UtilsKitCore)
import UtilsKitCore
#endif

#if canImport(UtilsKit)
import UtilsKit
#endif

// MARK: Response
extension RequestProtocol {
    /**
     Send request and return response or error, with progress value
     */
    public func response() async throws -> NetworkResponse {
            if let cacheKey = self.cacheKey {
				switch cacheKey.type {
                case .returnCacheDataElseLoad:
                    if let data = NetworkCache.shared.get(cacheKey) {
						Logger.cache.notice("\(cacheKey.key)")
                        return (statusCode: 200, data: data)
                    }
                    
                case .returnCacheDataDontLoad:
                    if let data = NetworkCache.shared.get(cacheKey) {
						Logger.cache.notice("\(cacheKey.key)")
                        return (statusCode: 200, data: data)
                    } else {
						Logger.cache.fault("\(cacheKey.key) - \(RequestError.emptyCache.localizedDescription)")
                        throw RequestError.emptyCache
                    }
                    
                default:
                    break
                }
            }
            
		do {
			let response = try await RequestManager.shared.request(self)
			if let cacheKey = self.cacheKey {
				NetworkCache.shared.set(response.data, for: cacheKey)
			}
			return response
		} catch {
			if let cacheKey = self.cacheKey, let data = NetworkCache.shared.get(cacheKey) {
				Logger.cache.notice("\(cacheKey.key)")
				return (statusCode: (error as? RequestError)?.statusCode,
						data: data)
			} else {
				throw error
			}
		}
	}
    
    /**
     Get the decoded response of type `T` with progress
     */
    public func response<T: Decodable>(_ type: T.Type) async throws -> T {
        let response = try await self.response()
        
        guard
            let data = response.data
        else {
            throw ResponseError.data
        }
        
        do {
            let objects = try T.decode(from: data)
            return objects
        } catch {
			Logger.decode.fault("\(self.description)")
            throw error
        }
    }
    
    // MARK: Send
    /**
     Send request and return  error if failed
     */
    public func send() async throws {
        _ = try await self.response()
    }
}
