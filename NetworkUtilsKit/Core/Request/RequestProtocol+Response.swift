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
	func _response(completion: ((Result<NetworkResponse, Error>) -> Void)? = nil,
						   progressBlock: ((Double) -> Void)? = nil ) {
		
		if let cacheKey = self.cacheKey {
			
			switch self.cachePolicy {
			case .returnCacheDataElseLoad:
				if let data = NetworkCache.shared.get(cacheKey) {
					log(NetworkLogType.cache, cacheKey.key)
					completion?(.success((statusCode: 200, data: data)))
					return
				}
				
			case .returnCacheDataDontLoad:
				if let data = NetworkCache.shared.get(cacheKey) {
					log(NetworkLogType.cache, cacheKey.key)
					completion?(.success((statusCode: 200, data: data)))
				} else {
					log(NetworkLogType.cache, cacheKey.key, error: RequestError.emptyCache)
					completion?(.failure(RequestError.emptyCache))
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
				completion?(result)
				
			case .failure(let error):
				if let cacheKey = self.cacheKey, let data = NetworkCache.shared.get(cacheKey) {
					completion?(.success((statusCode: (error as? RequestError)?.statusCode,
										  data: data)))
				} else {
					completion?(result)
				}
			}
		}, progressBlock: progressBlock)
	}
	
	/**
	 Get the decoded response of type `T` with progress
	 */
	func _response<T: Decodable>(_ type: T.Type,
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
				
				do {
					let objects = try T.decode(from: data)
					completion?(.success(objects))
				} catch {
					log(NetworkLogType.error, error.localizedDescription, error: nil)
					completion?(.failure(error))
				}
				
			case .failure(let error):
				completion?(.failure(error))
			}
		}, progressBlock: progressBlock)
	}
	
	// MARK: Send
	/**
	 Send request and return  error if failed
	 */
	func _send(completion: ((Result<Void, Error>) -> Void)? = nil,
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
