//
//  MockProtocol.swift
//  NetworkUtilsKit
//
//  Created by Michael Coqueret on 21/01/2021.
//  Copyright © 2021 RGMC. All rights reserved.
//

import Foundation
import UtilsKit

/// This protocol represents a mocked request to execute
public protocol MockProtocol: RequestProtocol {
    
    /// Mock file if needed
    var mockFileURL: URL? { get }
}

extension RequestProtocol where Self: MockProtocol {
    
    // MARK: Response
    /**
     Send request and return response or error, with progress value
     */
    public func response(fromMock: Bool,
                         completion: ((Result<NetworkResponse, Error>) -> Void)? = nil,
                         progressBlock: ((Double) -> Void)? = nil ) {
        if fromMock {
            self.mock(completion: completion)
        } else {
            self.response(completion: completion, progressBlock: progressBlock)
        }
    }
    
    /**
     Send request and return response or error
     */
    public func response(fromMock: Bool,
                         completion: ((Result<NetworkResponse, Error>) -> Void)? = nil) {
        if fromMock {
            self.mock(completion: completion)
        } else {
            self.response(completion: completion)
        }
    }
    
    /**
     Get the decoded response of type `T` with progress
     */
    public func response<T: Decodable>(_ type: T.Type,
                                       fromMock: Bool,
                                       completion: ((Result<T, Error>) -> Void)? = nil,
                                       progressBlock: ((Double) -> Void)? = nil ) {
        if fromMock {
            self.mock(type, completion: completion)
        } else {
            self.response(type, completion: completion, progressBlock: progressBlock)
        }
    }
    
    /**
     Get the decoded response of type `T`
     */
    public func response<T: Decodable>(_ type: T.Type,
                                       fromMock: Bool,
                                       completion: ((Result<T, Error>) -> Void)? = nil) {
        if fromMock {
            self.mock(type, completion: completion)
        } else {
            self.response(type, completion: completion)
        }
    }
    
    // MARK: Mock
    /**
     Send request and return mocked response or error
     */
    public func mock(completion: ((Result<NetworkResponse, Error>) -> Void)? = nil) {
        guard let mockPath = self.mockFileURL else {
            log(NetworkLogType.mock, self.description, error: ResponseError.noMock)
            completion?(.failure(ResponseError.noMock))
            return
        }
        
        do {
            let data = try Data(contentsOf: mockPath, options: .mappedIfSafe)
            log(NetworkLogType.mock, self.description)
            completion?(.success((200, data)))
        } catch {
            log(NetworkLogType.mock, self.description, error: error)
            completion?(.failure(error))
        }
    }
    
    /**
     Get the mocked decoded response of type `T`with progress
     */
    public func mock<T: Decodable>(_ type: T.Type,
                                   completion: ((Result<T, Error>) -> Void)? = nil) {
        self.mock { result in
            switch result {
            case .success(let response):
                guard let data = response.data else { completion?(.failure(ResponseError.data)); return }
                
                let objects = T.decode(from: data)
                if let objects: T = objects {
                    completion?(.success(objects))
                } else {
                    let responseError = ResponseError.decodable(type: "\(T.self)")
                    log(NetworkLogType.error, responseError.errorDescription, error: nil)
                    completion?(.failure(responseError))
                }
            case .failure(let error): completion?(.failure(error))
            }
        }
    }
}
