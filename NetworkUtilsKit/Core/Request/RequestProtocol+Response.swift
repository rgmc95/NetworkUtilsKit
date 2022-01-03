//
//  RequestProtocol+Response.swift
//  NetworkUtilsKit
//
//  Created by Michael Coqueret on 22/10/2021.
//  Copyright © 2021 RGMC. All rights reserved.
//

import Foundation
import UtilsKit

// MARK: Response
extension RequestProtocol {
    /**
     Send request and return response or error, with progress value
     */
    public func response(progressBlock: ((Double) -> Void)? = nil ) async throws -> NetworkResponse {
        try await withCheckedThrowingContinuation { continuation in
            
            if let cacheKey = self.cacheKey {
                
                switch self.cachePolicy {
                case .returnCacheDataElseLoad:
                    if let data = NetworkCache.shared.get(cacheKey) {
                        log(NetworkLogType.cache, cacheKey.key)
                        continuation.resume(returning: (statusCode: 200, data: data))
                        return
                    }
                    
                case .returnCacheDataDontLoad:
                    if let data = NetworkCache.shared.get(cacheKey) {
                        log(NetworkLogType.cache, cacheKey.key)
                        continuation.resume(returning: (statusCode: 200, data: data))
                    } else {
                        log(NetworkLogType.cache, cacheKey.key, error: RequestError.emptyCache)
                        continuation.resume(throwing: RequestError.emptyCache)
                    }
                    return
                    
                default:
                    break
                }
            }
            
            RequestManager.shared.request(self,
                                          result: { result in
                switch result {
                case .success(let response):
                    if let cacheKey = self.cacheKey {
                        NetworkCache.shared.set(response.data, for: cacheKey)
                    }
                    continuation.resume(returning: response)
                    
                case .failure(let error):
                    if let cacheKey = self.cacheKey, let data = NetworkCache.shared.get(cacheKey) {
                        continuation.resume(returning: (statusCode: (error as? RequestError)?.statusCode,
                                                        data: data))
                    } else {
                        continuation.resume(throwing: error)
                    }
                }
            }, progressBlock: progressBlock)
        }
    }
    
    /**
     Get the decoded response of type `T` with progress
     */
    public func response<T: Decodable>(_ type: T.Type,
                                       progressBlock: ((Double) -> Void)? = nil) async throws -> T {
        let response = try await self.response(progressBlock: progressBlock)
        
        guard
            let data = response.data
        else {
            throw ResponseError.data
        }
        
        do {
            let objects = try T.decode(from: data)
            return objects
        } catch {
            log(NetworkLogType.error, error.localizedDescription, error: nil)
            throw error
        }
    }
    
    // MARK: Send
    /**
     Send request and return  error if failed
     */
    public func send(progressBlock: ((Double) -> Void)? = nil ) async throws {
        _ = try await self.response(progressBlock: progressBlock)
    }
}
