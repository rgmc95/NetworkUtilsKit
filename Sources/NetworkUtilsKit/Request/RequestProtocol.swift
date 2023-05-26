//
//  RequestProtocol.swift
//  UtilsKit
//
//  Created by RGMC on 18/10/2018.
//  Copyright © 2018 RGMC. All rights reserved.
//

import Foundation

#if canImport(UtilsKitCore)
import UtilsKitCore
#endif

#if canImport(UtilsKit)
import UtilsKit
#endif

#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

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
    
    /// Request warning time response
    var warningTime: TimeInterval { get }
    
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
    var cacheKey: CacheKey? { get }
    
    /// Request cache Policy
    var cachePolicy: NSURLRequest.CachePolicy { get }
    
    /// Token refreachable
    var canRefreshToken: Bool { get }
}

extension RequestProtocol {
    
    /// Resquest string representable
    public var description: String {
        "\(self.method.rawValue) - \(self.scheme)://\(self.host)\(self.path)"
    }
    
    var parametersArray: ParametersArray? {
        self.parameters?
            .compactMap { (key: String, value: Any) in
                (key, value)
            }
            .sorted { $0.0 < $1.0 }
    }
    
    public var request: URLRequest? {
        try? RequestManager.shared.buildRequest(scheme: self.scheme,
                                                host: self.host,
                                                path: self.path,
                                                port: self.port,
                                                method: self.method,
                                                parameters: self.parametersArray,
                                                fileList: self.fileList,
                                                encoding: self.encoding,
                                                headers: self.headers,
                                                authentification: self.authentification,
                                                cachePolicy: self.cachePolicy)
    }
    
    public var requestWithoutAuthentification: URLRequest? {
        try? RequestManager.shared.buildRequest(scheme: self.scheme,
                                                host: self.host,
                                                path: self.path,
                                                port: self.port,
                                                method: self.method,
                                                parameters: self.parametersArray,
                                                fileList: self.fileList,
                                                encoding: self.encoding,
                                                headers: self.headers,
                                                authentification: nil,
                                                cachePolicy: self.cachePolicy)
    }
	
	public func cancel() {
		let description = self.description
		
		DispatchQueue.main.async {
			guard let request = RequestManager.shared.tasks[description] else { return }
			log(NetworkLogType.cancel, description)
			request.cancel()
		}
	}
}

// MARK: Default values
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
    public var cacheKey: CacheKey? { nil }
    
    /** Request cache Policy. Default value is ".reloadIgnoringLocalCacheData" wich means you'll get an error if server respond "304 not modified"
     If you rather get a 200 and cached response instead of error 304 :  you should use ".useProtocolCachePolicy" which is the default Apple policy
     */
    public var cachePolicy: NSURLRequest.CachePolicy { .reloadIgnoringLocalCacheData }
    
    /// Token refreachable
    public var canRefreshToken: Bool { true }
    
    /// Request warning time response if needed
    public var warningTime: TimeInterval { 2 }
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
