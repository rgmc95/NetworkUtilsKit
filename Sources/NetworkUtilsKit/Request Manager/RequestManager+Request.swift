//
//  RequestManager+Request.swift
//  UtilsKit
//
//  Created by RGMC on 16/07/2019.
//  Copyright © 2019 RGMC. All rights reserved.
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

extension URLSession {
	
	func data(with request: URLRequest, description: String) async throws -> (Data?, URLResponse?) {
		try await withUnsafeThrowingContinuation { continuation in
			let task = self.dataTask(with: request) { data, response, error in
				RequestManager.shared.tasks.removeValue(forKey: description)
				if let error = error { continuation.resume(throwing: error); return }
				continuation.resume(returning: (data, response))
			}
			RequestManager.shared.tasks[description] = task
			task.resume()
		}
	}
}

// MARK: - Request
extension RequestManager {
	
	//swiftlint:disable closure_body_length
	//swiftlint:disable function_body_length
	private func request(
		scheme: String,
		host: String,
		path: String,
		port: Int?,
		warningTime: Double = 2,
		method: RequestMethod = .get,
		parameters: ParametersArray? = nil,
		fileList: [String: URL]? = nil,
		encoding: Encoding = .url,
		headers: Headers? = nil,
		authentification: AuthentificationProtocol? = nil,
		description: String,
		retryAuthentification: Bool = true,
		cachePolicy: URLRequest.CachePolicy = .reloadIgnoringLocalCacheData,
		progressBlock: ((Double) -> Void)? = nil) async throws -> NetworkResponse {
			
			var request: URLRequest = try self.buildRequest(scheme: scheme,
															host: host,
															path: path,
															port: port,
															method: method,
															parameters: parameters,
															fileList: fileList,
															encoding: encoding,
															headers: headers,
															authentification: authentification,
															cachePolicy: cachePolicy)
			
			request.timeoutInterval = self.requestTimeoutInterval ?? request.timeoutInterval
			
			log(NetworkLogType.sending, description)
			
			let startDate = Date()
			let session = URLSession(configuration: self.requestConfiguration)
			
			let (data, response) = try await session.data(with: request, description: description)
			
			let time = Date().timeIntervalSince(startDate)
			let requestId = "\(description) - \(String(format: "%0.3f", time))s"
			
			guard let response = response as? HTTPURLResponse else { throw ResponseError.unknow }
			
			if response.statusCode >= 200 && response.statusCode < 300 {
				if time > warningTime {
					log(NetworkLogType.successWarning, requestId)
				} else {
					log(NetworkLogType.success, requestId)
				}
				return (response.statusCode, data)
			} else if response.statusCode == 401 && retryAuthentification {
				var refreshArray: [AuthentificationRefreshableProtocol] = []
				
				if let refreshAuthent = authentification as? AuthentificationRefreshableProtocol {
					refreshArray = [refreshAuthent]
				} else if let authentificationArray = (authentification as? [AuthentificationProtocol])?
					.compactMap({ $0 as? AuthentificationRefreshableProtocol }) {
					refreshArray = authentificationArray
				}
				
				if refreshArray.isEmpty {
					throw self.returnError(requestId: requestId,
										   response: response,
										   data: data)
				}
				
				try await self.refresh(authentification: refreshArray,
									   requestId: requestId,
									   request: request)
				
				return try await self.request(scheme: scheme,
											  host: host,
											  path: path,
											  port: port,
											  warningTime: warningTime,
											  method: method,
											  parameters: parameters,
											  fileList: fileList,
											  encoding: encoding,
											  headers: headers,
											  authentification: authentification,
											  description: description,
											  retryAuthentification: false,
											  cachePolicy: cachePolicy,
											  progressBlock: progressBlock)
			} else {
				throw self.returnError(requestId: requestId,
									   response: response,
									   data: data)
			}
		}
	
	@Sendable
	private func refresh(authentification: [AuthentificationRefreshableProtocol],
						 requestId: String,
						 request: URLRequest) async throws {
		guard let first = authentification.first else {
			return
		}
		
		try await first.refresh(from: request)
		try await refresh(authentification: Array(authentification.dropFirst()),
						  requestId: requestId,
						  request: request)
	}
	
	private func returnError(requestId: String,
							 response: HTTPURLResponse,
							 data: Data?) -> Error  {
		let error = ResponseError.network(response: response, data: data)
		log(NetworkLogType.error, requestId, error: error)
		return error
	}
	
	/**
	 Send request
	 - parameter request: Request
	 - parameter result: Request Result
	 */
	public func request(_ request: RequestProtocol,
						progressBlock: ((Double) -> Void)? = nil) async throws -> NetworkResponse {
		try await self.request(scheme: request.scheme,
							   host: request.host,
							   path: request.path,
							   port: request.port,
							   warningTime: request.warningTime,
							   method: request.method,
							   parameters: request.parametersArray,
							   fileList: request.fileList,
							   encoding: request.encoding,
							   headers: request.headers,
							   authentification: request.authentification,
							   description: request.description,
							   retryAuthentification: request.canRefreshToken,
							   cachePolicy: request.cachePolicy,
							   progressBlock: progressBlock)
	}
}
