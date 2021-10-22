//
//  RequestProtocol+ResponseAsync.swift
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
	@available(iOS 15, *)
	public func response(progressBlock: ((Double) -> Void)? = nil ) async throws -> NetworkResponse {
		try await withCheckedThrowingContinuation { continuation in
			self._response { response in
				switch response {
				case .success(let value): continuation.resume(returning: value)
				case .failure(let error): continuation.resume(throwing: error)
				}
			} progressBlock: {
				progressBlock?($0)
			}
		}
	}

	/**
	 Send request and return response or error
	 */
	@available(iOS 15, *)
	public func response() async throws -> NetworkResponse {
		try await self.response(progressBlock: nil)
	}

	/**
	 Get the decoded response of type `T` with progress
	 */
	@available(iOS 15, *)
	public func response<T: Decodable>(_ type: T.Type,
									   progressBlock: ((Double) -> Void)? = nil ) async throws -> T {
		try await withCheckedThrowingContinuation { continuation in
			self._response(type,
						   completion: { response in
				switch response {
				case .success(let value): continuation.resume(returning: value)
				case .failure(let error): continuation.resume(throwing: error)
				}
			},
						   progressBlock: progressBlock)
		}
	}

	/**
	 Get the decoded response of type `T`
	 */
	@available(iOS 15, *)
	public func response<T: Decodable>(_ type: T.Type) async throws -> T {
		try await self.response(type, progressBlock: nil)
	}

	// MARK: Send
	/**
	 Send request and return  error if failed
	 */
	@available(iOS 15, *)
	@discardableResult
	public func send(progressBlock: ((Double) -> Void)? = nil) async throws -> Result<Void, Error> {
		try await withCheckedThrowingContinuation { continuation in
			self._send { response in
				switch response {
				case .success: continuation.resume(returning: response)
				case .failure(let error): continuation.resume(throwing: error)
				}
			} progressBlock: {
				progressBlock?($0)
			}
		}
	}
}
