//
//  RequestProtocol.swift
//  UtilsKit
//
//  Created by RGMC on 18/10/2018.
//  Copyright © 2018 RGMC. All rights reserved.
//

import Foundation
import UtilsKit

/// This protocol represents a full request to execute
public protocol RequestProtocol: CustomStringConvertible {
    
    /// Request scheme
    var scheme: String { get }
    
    /// Request host
    var host: String { get }
    
    /// Request path
    var path: String { get }
    
    /// Request port
    var port: Int? { get }
    
    /// Request method
    var method: RequestMethod { get }
    
    /// Request headers if needed
    var headers: Headers? { get }
    
    /// Request parameters if needed
    var parameters: Parameters? { get }
    
    /// Request URL of local files in an array if needed
    var fileList: [String: URL]? { get }
    
    /// Request encoding
    var encoding: Encoding { get }
    
    /// Request authentification if needed
    var authentification: AuthentificationProtocol? { get }
    
    /// Cache key if needed
    var cacheKey: String? { get }
    
    /// Request queue
    var queue: DispatchQueue { get }
    
    /// Request identifier
    var identifier: String? { get }

    /// Request cache Policy
    var cachePolicy: NSURLRequest.CachePolicy { get }
}

extension RequestProtocol {
    
    /// Resquest string representable
    public var description: String {
        "\(self.method.rawValue) - \(self.identifier ?? "\("\(self.scheme)://\(self.host)\(self.path)")")"
    }
}

/// default values
extension RequestProtocol {
    
    /// Request port if needed
    public var port: Int? { nil }
    
    /// Request headers if needed
    public var headers: Headers? { nil }
    
    /// Request parameters if needed
    public var parameters: Parameters? { nil }
    
    /// Request URL of local files in an array if needed
    public var fileList: [String: URL]? { nil }
    
    /// Request encoding
    public var encoding: Encoding { .url }
    
    /// Request authentification if needed
    public var authentification: AuthentificationProtocol? { nil }
    
    /// Cache key if needed
    public var cacheKey: String? { nil }
    
    /// Request queue. Main by default
    public var queue: DispatchQueue { DispatchQueue.main }
    
    /// Request identifier
    public var identifier: String? { nil }

    /** Request cache Policy. Default value is ".reloadIgnoringLocalCacheData" wich means you'll get an error if server respond "304 not modified"
     If you rather get a 200 and cached response instead of error 304 :  you should use ".useProtocolCachePolicy" which is the default Apple policy
     */
    public var cachePolicy: NSURLRequest.CachePolicy { .reloadIgnoringLocalCacheData }
    
    // MARK: Response
    /**
     Send request and return response or error, with progress value
     */
    public func response(completion: ((Result<NetworkResponse, Error>) -> Void)? = nil,
                         progressBlock: ((Double) -> Void)? = nil ) {
        
        RequestManager.shared.request(self,
                                      result: { result in
                                        switch result {
                                        case .success(let response):
                                            if let cacheKey = self.cacheKey {
                                                NetworkCache.shared.set(response.data, for: cacheKey)
                                            }
                                            completion?(result)
                                            
                                        case .failure(let error):
                                            if let cacheKey = self.cacheKey, let data = NetworkCache.shared.get(cacheKey) {
                                                completion?(.success((statusCode: (error as? RequestError)?.statusCode, data: data)))
                                            } else {
                                                completion?(result)
                                            }
                                        }
                                      }, progressBlock: progressBlock)
    }
    
    /**
     Send request and return response or error
     */
    public func response(completion: ((Result<NetworkResponse, Error>) -> Void)? = nil) {
        self.response(completion: completion, progressBlock: nil)
    }
    
    /**
     Get the decoded response of type `T` with progress
     */
    public func response<T: Decodable>(_ type: T.Type,
                                       completion: ((Result<T, Error>) -> Void)? = nil,
                                       progressBlock: ((Double) -> Void)? = nil ) {
        self.response(completion: { result in
            switch result {
            case .success(let response):
                guard
                    let data = response.data
                else {
                    completion?(.failure(ResponseError.data))
                    return
                }

                let objects = try? T.decode(from: data) // decode object
                
                if let objects: T = objects {
                    completion?(.success(objects))
                } else {
                    let responseError = ResponseError.decodable(type: "\(T.self)")
                    log(NetworkLogType.error, responseError.errorDescription, error: nil)
                    completion?(.failure(responseError))
                }
                
            case .failure(let error):
                completion?(.failure(error))
            }
        }, progressBlock: progressBlock)
    }
    
    /**
     Get the decoded response of type `T`
     */
    public func response<T: Decodable>(_ type: T.Type,
                                       completion: ((Result<T, Error>) -> Void)? = nil) {
        self.response(type, completion: completion, progressBlock: nil)
    }
    
    // MARK: Send
    /**
     Send request and return  error if failed
     */
    public func send(completion: ((Result<Void, Error>) -> Void)? = nil,
                     progressBlock: ((Double) -> Void)? = nil ) {
        
        self.response { result in
            switch result {
            case .success: completion?(.success(()))
            case .failure(let error): completion?(.failure(error))
            }
        } progressBlock: { progress in
            progressBlock?(progress)
        }
    }
}

extension RequestProtocol {
    
    /**
     Clear request cache
     */
    public func clearCache() {
        guard let cacheKey = self.cacheKey else { return }
        NetworkCache.shared.delete(cacheKey)
    }
}
