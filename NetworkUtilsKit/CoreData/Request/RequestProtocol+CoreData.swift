//
//  ResponseProtocol.swift
//  NetworkUtilsKit
//
//  Created by Michael Coqueret on 03/09/2020.
//  Copyright © 2020 RGMC. All rights reserved.
//

import CoreDataUtilsKit


extension RequestProtocol where Self: ResponseProtocol, Self.ResponseType: CoreDataUpdatable {
    
    /**
     Get the decoded response of `CoreDataUpdatable` type based
     */
    public func response(completion: ((Swift.Result<ResponseType, Error>) -> Void)?) {
        self.responseData { result in
            switch result {
            case .success(let response):
                guard let data = response.data
                else { completion?(.failure(ResponseError.data)); return }
                
                guard let json = try? JSONSerialization.jsonObject(with: data, options: [])
                else { completion?(.failure(ResponseError.json)); return }
                
                guard let objects = ResponseType.update(with: json)
                else { completion?(.failure(ResponseError.decodable)); return }
                completion?(.success(objects))
            case .failure(let error): completion?(.failure(error))
            }
        }
    }
}
