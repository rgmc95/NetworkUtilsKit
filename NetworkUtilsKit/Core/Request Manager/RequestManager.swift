//
//  RequestManager.swift
//  UtilsKit
//
//  Created by RGMC on 18/10/2018.
//  Copyright © 2018 RGMC. All rights reserved.
//

import Foundation

/// Request headers
public typealias Headers = [String: String]

/// Request parameters
public typealias Parameters = [String: Any]

/// Network reponse: staus code and data
public typealias NetworkResponse = (statusCode: Int?, data: Data?)

/// Manage all requests
public class RequestManager {
    
    // MARK: - Singleton
    /// The shared singleton RequestManager object
    public static let shared = RequestManager()
    
    // MARK: - Variables
    /// Request configuration
    public var requestConfiguration: URLSessionConfiguration
    
    /// Interval before request time out
    public var requestTimeoutInterval: TimeInterval?
    
    /// Downlaod request configuration
    public var downloadConfiguration: URLSessionConfiguration
    
    /// Interval before request time out
    public var downloadTimeoutInterval: TimeInterval?
    
    // MARK: - Init
    private init() {
        self.requestConfiguration = URLSessionConfiguration.default
        self.downloadConfiguration = URLSessionConfiguration.default
    }
}

// MARK: - Utils
extension RequestManager {
    
    private func getUrlComponents(scheme: String,
                                  host: String,
                                  path: String,
                                  port: Int?,
                                  parameters: Parameters? = nil,
                                  encoding: Encoding = .url,
                                  authentification: AuthentificationProtocol? = nil) -> URLComponents {
        var components = URLComponents()
        var finalUrlParameters: [URLQueryItem] = []
        
        components.scheme = scheme
        components.host = host
        components.path = path
        components.port = port
        
        // Authentification
        authentification?.parameters.forEach {
            switch authentification?.encoding {
            case .url:
                finalUrlParameters.append(URLQueryItem(name: $0.key, value: $0.value))
            case .body: break
            case .header: break
            case .none: break
            }
        }
        
        // Parameters
        switch encoding {
        case .url:
            parameters?.forEach({
                finalUrlParameters.append(URLQueryItem(name: $0.key, value: "\($0.value)"))
            })
        case .json: break
        }
        
        if !finalUrlParameters.isEmpty {
            components.queryItems = finalUrlParameters
        }
        
        return components
    }
    
    private func getBodyParameters(parameters: Parameters?,
                                   encoding: Encoding,
                                   authentification: AuthentificationProtocol?) -> Parameters {
        var finalBodyParameters: Parameters = [:]
        
        // Authentification
        authentification?.parameters.forEach {
            switch authentification?.encoding {
            case .body:
                finalBodyParameters[$0.key] = $0.value
            case .header: break
            case .url: break
            case .none: break
            }
        }
        
        // Parameters
        switch encoding {
        case .json:
            parameters?.forEach({
                finalBodyParameters[$0.key] = $0.value
            })
        case .url: break
        }
        
        return finalBodyParameters
    }
    
    private func getHeaders(headers: Headers?,
                            authentification: AuthentificationProtocol?) -> Headers {
        var finalHeaders: Headers = headers ?? [:]
        
        // Authentification
        if let authentification: AuthentificationProtocol = authentification {
            authentification.parameters.forEach {
                switch authentification.encoding {
                case .header:
                    finalHeaders[$0.key] = $0.value
                case .body: break
                case .url: break
                }
            }
        }
        
        return finalHeaders
    }
    
    internal func buildRequest(scheme: String,
                               host: String,
                               path: String,
                               port: Int?,
                               method: RequestMethod,
                               parameters: Parameters? = nil,
                               encoding: Encoding = .url,
                               headers: Headers? = nil,
                               authentification: AuthentificationProtocol? = nil) throws -> URLRequest {
        // URL components
        let components = self.getUrlComponents(scheme: scheme,
                                               host: host,
                                               path: path,
                                               port: port,
                                               parameters: parameters,
                                               encoding: encoding,
                                               authentification: authentification)
        
        guard let url = components.url else { throw RequestError.url }
        
        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue
        
        // Final headers
        let finalHeaders = self.getHeaders(headers: headers,
                                           authentification: authentification)
        finalHeaders.forEach { request.setValue($0.value, forHTTPHeaderField: $0.key) }
        if encoding == .json {
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        }
        
        // Final body parameters
        let finalBodyParameters = self.getBodyParameters(parameters: parameters,
                                                         encoding: encoding,
                                                         authentification: authentification)
        if !finalBodyParameters.isEmpty {
            if JSONSerialization.isValidJSONObject(finalBodyParameters) {
                request.httpBody = try JSONSerialization.data(withJSONObject: finalBodyParameters, options: [])
            } else {
                throw RequestError.json
            }
        }
        
        return request
    }
}
