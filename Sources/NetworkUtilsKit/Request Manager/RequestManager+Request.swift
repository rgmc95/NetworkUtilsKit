//
//  RequestManager+Request.swift
//  UtilsKit
//
//  Created by RGMC on 16/07/2019.
//  Copyright © 2019 RGMC. All rights reserved.
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

extension URLSession {
	
	nonisolated func data(with request: URLRequest, description: String) async throws -> (Data?, URLResponse?) {
		try await withUnsafeThrowingContinuation { continuation in
			Task {
				let task = self.dataTask(with: request) { data, response, error in
					Task {
						await RequestManager.shared.set(task: nil, for: description)
						if let error = error { continuation.resume(throwing: error); return }
						continuation.resume(returning: (data, response))
					}
				}
				await RequestManager.shared.set(task: task, for: description)
				task.resume()
			}
		}
	}
}

// MARK: - Request
extension RequestManager {
	
	//swiftlint:disable closure_body_length
	//swiftlint:disable function_body_length
	private func request(scheme: String,
						 host: String,
						 path: String,
						 port: Int?,
						 warningTime: Double,
						 method: RequestMethod = .get,
						 urlParameters: [String: String]?,
						 parameters: Parameters?,
						 files: [RequestFile]?,
						 headers: Headers?,
						 authentification: AuthentificationProtocol?,
						 timeout: TimeInterval?,
						 description: String,
						 retryAuthentification: Bool,
						 cachePolicy: URLRequest.CachePolicy = .reloadIgnoringLocalCacheData) async throws -> NetworkResponse {
		
		// Request
		var request: URLRequest = try await self.buildRequest(scheme: scheme,
															  host: host,
															  path: path,
															  port: port,
															  method: method,
															  urlParameters: urlParameters,
															  parameters: parameters,
															  files: files,
															  headers: headers,
															  authentification: authentification,
															  timeout: timeout,
															  cachePolicy: cachePolicy)
		
		request.timeoutInterval = timeout ?? self.requestTimeoutInterval
		
		Logger.requestSend.notice("\(description)")
		
		// Date
		let startDate = Date()
		let session = URLSession(configuration: self.requestConfiguration)
		session.configuration.timeoutIntervalForRequest = timeout ?? self.requestTimeoutInterval
		
		do {
			// Call
			let (data, response) = try await session.data(with: request, description: description)
			
			// Time
			let time = Date().timeIntervalSince(startDate)
			let requestId = "\(description) - \(String(format: "%0.3f", time))s"
			
			// Response
			guard let response = response as? HTTPURLResponse else { throw ResponseError.unknow }
			
			if response.statusCode >= 200 && response.statusCode < 300 {
				if time > warningTime {
					Logger.requestSuccess.warning("\(requestId)")
				} else {
					Logger.requestSuccess.info("\(requestId)")
				}
				return (response.statusCode, data)
			} else if response.statusCode == 401 && retryAuthentification {
				let error = self.returnError(requestId: requestId,
											 response: response,
											 data: data)
				
				var refreshArray: [AuthentificationRefreshableProtocol] = []
				
				if let refreshAuthent = authentification as? AuthentificationRefreshableProtocol {
					refreshArray = [refreshAuthent]
				} else if let authentificationArray = (authentification as? [AuthentificationProtocol])?
					.compactMap({ $0 as? AuthentificationRefreshableProtocol }) {
					refreshArray = authentificationArray
				}
				
				if refreshArray.isEmpty {
					throw error
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
											  urlParameters: urlParameters,
											  parameters: parameters,
											  files: files,
											  headers: headers,
											  authentification: authentification,
											  timeout: timeout,
											  description: description,
											  retryAuthentification: false,
											  cachePolicy: cachePolicy)
			} else {
				throw self.returnError(requestId: requestId,
									   response: response,
									   data: data)
			}
		} catch {
			Logger.requestFail.fault("\(description) - \(error.localizedDescription)")
			throw error
		}
	}
	
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
		Logger.requestFail.fault("\(requestId) - \(error.localizedDescription)")
		return error
	}
	
	/**
	 Send request
	 - parameter request: Request
	 - parameter result: Request Result
	 */
	public func request(_ request: RequestProtocol) async throws -> NetworkResponse {
		try await self.request(scheme: request.scheme,
							   host: request.host,
							   path: request.path,
							   port: request.port,
							   warningTime: request.warningTime,
							   method: request.method,
							   urlParameters: request.urlParameters,
							   parameters: request.parameters,
							   files: request.files,
							   headers: request.headers,
							   authentification: request.authentification,
							   timeout: request.timeoutInterval,
							   description: request.description,
							   retryAuthentification: request.canRefreshToken,
							   cachePolicy: request.cachePolicy)
	}
}
