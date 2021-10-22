//
//  RequestProtocol+ResponseCompletion.swift
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
	@available(iOS, deprecated: 15, message: "Use async func instead")
	public func response(completion: ((Result<NetworkResponse, Error>) -> Void)? = nil,
						 progressBlock: ((Double) -> Void)? = nil ) {
		self._response(completion: completion, progressBlock: progressBlock)
	}
	
	/**
	 Send request and return response or error
	 */
	@available(iOS, deprecated: 15, message: "Use async func instead")
	public func response(completion: ((Result<NetworkResponse, Error>) -> Void)? = nil) {
		self.response(completion: completion, progressBlock: nil)
	}
	
	/**
	 Get the decoded response of type `T` with progress
	 */
	@available(iOS, deprecated: 15, message: "Use async func instead")
	public func response<T: Decodable>(_ type: T.Type,
									   completion: ((Result<T, Error>) -> Void)? = nil,
									   progressBlock: ((Double) -> Void)? = nil ) {
		self._response(type, completion: completion, progressBlock: progressBlock)
	}
	
	/**
	 Get the decoded response of type `T`
	 */
	@available(iOS, deprecated: 15, message: "Use async func instead")
	public func response<T: Decodable>(_ type: T.Type,
									   completion: ((Result<T, Error>) -> Void)? = nil) {
		self.response(type, completion: completion, progressBlock: nil)
	}
	
	// MARK: Send
	/**
	 Send request and return  error if failed
	 */
	@available(iOS, deprecated: 15, message: "Use async func instead")
	public func send(completion: ((Result<Void, Error>) -> Void)? = nil,
					 progressBlock: ((Double) -> Void)? = nil ) {
		self._send(completion: completion, progressBlock: progressBlock)
	}
}
