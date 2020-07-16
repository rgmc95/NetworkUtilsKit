//
//  ResponseProtocol.swift
//  UtilsKit
//
//  Created by RGMC on 24/10/2018.
//  Copyright © 2018 RGMC. All rights reserved.
//

import UIKit
import UtilsKit

// MARK: - Error
public enum ResponseError: Error, LocalizedError {
    case unknow
    case decodable
    case data
    case json
    case network(response: HTTPURLResponse?)
    
    public var errorDescription: String? {
        switch self {
        case .unknow: return "Response error"
        case .decodable: return "Decode error"
        case .data: return "Data error"
        case .json: return "JSON error"
        case .network(let response):
            guard let statusCode = response?.statusCode else { return nil }
            return "\(statusCode): \(HTTPURLResponse.localizedString(forStatusCode: statusCode))"
        }
    }
}

// MARK: - Decodable response

/**
 Protocol used to get a decoded response of `RequestProtocol`
 */
public protocol ResponseProtocol {
    
    /// Response type
    associatedtype ResponseType
    
    /**
        Get the decoded response of type `ResponseType`
     */
    func response(completion: ((Result<ResponseType, Error>) -> Void)?)
}

extension RequestProtocol where Self: ResponseProtocol, Self.ResponseType: Decodable {
    
    /**
        Get the decoded response of `Decodable` type based
     */
    public func response(completion: ((Result<ResponseType, Error>) -> Void)? = nil) {
        self.responseData { result in
            switch result {
            case .success(let response):
                guard let data = response.data else { completion?(.failure(ResponseError.data)); return }
                guard let objects = ResponseType.decode(from: data) else { completion?(.failure(ResponseError.decodable)); return }
                completion?(.success(objects))
            case .failure(let error): completion?(.failure(error))
            }
        }
    }
}

//extension RequestProtocol where Self: ResponseProtocol, Self.ResponseType: CoreDataUpdatable {
//
//    /**
//        Get the decoded response of `CoreDataUpdatable` type based
//     */
//    public func response(completion: ((Result<ResponseType, Error>) -> Void)? = nil) {
//        self.responseData { result in
//            switch result {
//            case .success(let response):
//                guard let data = response.data else { completion?(.failure(ResponseError.data)); return }
//                guard let json = try? JSONSerialization.jsonObject(with: data, options: []) else { completion?(.failure(ResponseError.json)); return }
//                guard let objects = ResponseType.update(with: json) else { completion?(.failure(ResponseError.decodable)); return }
//                completion?(.success(objects))
//            case .failure(let error): completion?(.failure(error))
//            }
//        }
//    }
//}
