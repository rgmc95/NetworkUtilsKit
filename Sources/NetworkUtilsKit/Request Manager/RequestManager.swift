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
public typealias Parameters = [String: Any]
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
    public var requestTimeoutInterval: TimeInterval?
    
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
                                  parameters: ParametersArray? = nil,
                                  encoding: Encoding = .url,
                                  authentification: AuthentificationProtocol? = nil) -> URLComponents {
        var components = URLComponents()
        var finalUrlParameters: [URLQueryItem] = []
        
        components.scheme = scheme
        components.host = host
        components.path = path
        components.port = port
        
        // Parameters
        switch encoding {
        case .url:
            parameters?.forEach({
                finalUrlParameters.append(URLQueryItem(name: $0.key, value: "\($0.value)"))
            })
            
        default:
            break
        }
        
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
    
    private func getJSONBodyData(parameters: ParametersArray?,
                                 authentification: AuthentificationProtocol?) -> Data? {
        
        var finalBodyParameters: Parameters = authentification?.bodyParameters ?? [:]
        
        // Parameters
        parameters?.forEach {
            finalBodyParameters[$0.key] = $0.value
        }
        
        var dataBody: Data?
        
        if !finalBodyParameters.isEmpty {
            if JSONSerialization.isValidJSONObject(finalBodyParameters) {
                do {
                    dataBody = try JSONSerialization.data(withJSONObject: finalBodyParameters, options: [])
                } catch {
					Logger.data.fault("JSON is invalid - \(error.localizedDescription)")
                }
            } else {
				Logger.data.fault("JSON is invalid - \(RequestError.json.localizedDescription)")
            }
        }
        
        return dataBody
    }
	
	private func getFormEncodedBodyData(parameters: ParametersArray?,
										authentification: AuthentificationProtocol?) -> Data? {
		
		var finalBodyParameters: Parameters = authentification?.bodyParameters ?? [:]
		
		// Parameters
		parameters?.forEach {
			finalBodyParameters[$0.key] = $0.value
		}
		
		var dataBody: Data?
		
		if !finalBodyParameters.isEmpty {
			if JSONSerialization.isValidJSONObject(finalBodyParameters) {
				var requestBody = URLComponents()
				requestBody.queryItems = finalBodyParameters.map { URLQueryItem(name: $0.key, value: "\($0.value)") }
				dataBody = requestBody.query?.data(using: .utf8)
			} else {
				Logger.data.fault("JSON is invalid - \(RequestError.json.localizedDescription)")
			}
		}
		
		return dataBody
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
							   parameters: ParametersArray? = nil,
							   files: [RequestFile]? = nil,
							   encoding: Encoding = .url,
							   headers: Headers? = nil,
							   authentification: AuthentificationProtocol? = nil,
                               cachePolicy: URLRequest.CachePolicy = .reloadIgnoringLocalCacheData) throws -> URLRequest {
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
        request.cachePolicy = cachePolicy // .reloadIgnoringLocalCacheData allow reponse 304 instead of 200.
        
        // Final headers
        let finalHeaders = self.getHeaders(headers: headers, authentification: authentification)
        finalHeaders.forEach { request.setValue($0.value, forHTTPHeaderField: $0.key) }
        
        
        switch encoding {
        case .json:
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = self.getJSONBodyData(parameters: parameters,
                                                    authentification: authentification)
            
		case .formURLEncoded:
			request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
			request.httpBody = self.getFormEncodedBodyData(parameters: parameters,
														   authentification: authentification)
			
        case .formData:
			var multipart = MultipartRequest()
			
			for parameter in parameters ?? [] {
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
            
        default: break
        }
        return request
    }
}
