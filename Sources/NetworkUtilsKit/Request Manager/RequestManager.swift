//
//  RequestManager.swift
//  UtilsKit
//
//  Created by RGMC on 18/10/2018.
//  Copyright © 2018 RGMC. All rights reserved.
//

import Foundation
import OSLog

#if canImport(UtilsKitCore)
import UtilsKitCore
#endif

#if canImport(UtilsKit)
import UtilsKit
#endif

#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

/// Request headers
public typealias Headers = [String: String]

/** Request parameters
 
 - Warning:
 Override AutentificationProtocol parameters if exists
 */
typealias ParametersArray = [(key: String, value: Any)]

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
    public var requestTimeoutInterval: TimeInterval = 60
    
    /// Downlaod request configuration
    public var downloadConfiguration: URLSessionConfiguration
    
    /// Interval before request time out
    public var downloadTimeoutInterval: TimeInterval?
	
	@MainActor
	public var tasks: [String: URLSessionDataTask] = [:]
    
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
                                  parameters: [String: String]? = nil,
                                  authentification: AuthentificationProtocol? = nil) -> URLComponents {
        var components = URLComponents()
        
        components.scheme = scheme
        components.host = host
        components.path = path
        components.port = port
        
		var finalUrlParameters = parameters?.map {
			URLQueryItem(name: $0.key, value: $0.value)
		} ?? []
        
        // Authen Params
        authentification?.urlQueryItems.forEach { query in
            if !finalUrlParameters.contains(where: { $0.name == query.name }) {
                finalUrlParameters.append(query)
            }
        }
        
        
        if !finalUrlParameters.isEmpty {
            components.queryItems = finalUrlParameters
        }
        
        return components
    }
	
	private func getFormEncodedBodyData(parameters: [String: Any]?,
										authentification: AuthentificationProtocol?) -> Data? {
		guard let parameters, !parameters.isEmpty else { return nil }
		
		if JSONSerialization.isValidJSONObject(parameters) {
			var requestBody = URLComponents()
			requestBody.queryItems = parameters.map { URLQueryItem(name: $0.key, value: "\($0.value)") }
			return requestBody.query?.data(using: .utf8)
		} else {
			Logger.data.fault("JSON is invalid - \(RequestError.json.localizedDescription)")
			return nil
		}
	}
	
	private func getHeaders(headers: Headers?,
                            authentification: AuthentificationProtocol?) -> Headers {
        var finalHeaders: Headers = authentification?.headers ?? [:]
        
        // Headers
        headers?.forEach {
            finalHeaders[$0.key] = $0.value
        }
        
        return finalHeaders
    }
    
    internal func buildRequest(scheme: String,
                               host: String,
                               path: String,
							   port: Int?,
							   method: RequestMethod,
							   urlParameters: [String: String]?,
							   parameters: Parameters?,
							   files: [RequestFile]?,
							   headers: Headers?,
							   authentification: AuthentificationProtocol?,
							   timeout: TimeInterval?,
                               cachePolicy: URLRequest.CachePolicy = .reloadIgnoringLocalCacheData) throws -> URLRequest {
        // URL components
        let components = self.getUrlComponents(scheme: scheme,
                                               host: host,
                                               path: path,
                                               port: port,
											   parameters: urlParameters,
                                               authentification: authentification)
        
        guard let url = components.url else { throw RequestError.url }
        
        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue
		request.timeoutInterval = timeout ?? self.requestTimeoutInterval
        request.cachePolicy = cachePolicy // .reloadIgnoringLocalCacheData allow reponse 304 instead of 200.
        
        // Final headers
        let finalHeaders = self.getHeaders(headers: headers, authentification: authentification)
        finalHeaders.forEach { request.setValue($0.value, forHTTPHeaderField: $0.key) }
        
		switch parameters {
		case .encodable(let value):
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = try JSONEncoder().encode(value)
            
		case .formURLEncoded(let values):
			request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
			request.httpBody = self.getFormEncodedBodyData(parameters: values, authentification: authentification)
			
        case .formData(let value):
			var multipart = MultipartRequest()
			
			for parameter in value {
				multipart.add(key: parameter.key, value: "\(parameter.value)")
			}
			
			for file in files ?? [] {
				multipart.add(
					key: file.key,
					fileName: file.name,
					fileMimeType: file.type,
					fileData: file.data
				)
			}
			
			request.setValue(multipart.httpContentTypeHeadeValue,
							 forHTTPHeaderField: "Content-Type")
			
			request.httpBody = multipart.httpBody
			
		case .other(let type, let data):
			request.setValue(type.value, forHTTPHeaderField: type.key)
			request.httpBody = data
			
		case .none: break
		}
		return request
	}
}
