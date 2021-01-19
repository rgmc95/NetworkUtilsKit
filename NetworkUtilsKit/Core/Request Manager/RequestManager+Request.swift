//
//  RequestManager+Request.swift
//  UtilsKit
//
//  Created by RGMC on 16/07/2019.
//  Copyright © 2019 RGMC. All rights reserved.
//

import Foundation
import UtilsKit

// MARK: - Request
extension RequestManager {
    
    private func request(
        scheme: String,
        host: String,
        path: String,
        port: Int?,
        method: RequestMethod = .get,
        parameters: Parameters? = nil,
        fileArray: [URL]? = nil,
        encoding: Encoding = .url,
        headers: Headers? = nil,
        authentification: AuthentificationProtocol? = nil,
        queue: DispatchQueue = DispatchQueue.main,
        identifier: String? = nil,
        completion: ((Result<NetworkResponse, Error>) -> Void)? = nil) {
        
        queue.async {
            do {
                var request: URLRequest = try self.buildRequest(scheme: scheme,
                                                                host: host,
                                                                path: path,
                                                                port: port,
                                                                method: method,
                                                                parameters: parameters,
                                                                fileArray: fileArray,
                                                                encoding: encoding,
                                                                headers: headers,
                                                                authentification: authentification)
                
                let requestId: String = identifier ?? request.url?.absoluteString ?? ""
                request.timeoutInterval = self.requestTimeoutInterval ?? request.timeoutInterval
                
                log(NetworkLogType.sending(method.rawValue), requestId)

                URLSession(configuration: self.requestConfiguration).dataTask(with: request) { data, response, _ in
                    queue.async {
                        guard let response = response as? HTTPURLResponse else {
                            completion?(.failure(ResponseError.unknow))
                            return
                        }
                        
                        if response.statusCode >= 200 && response.statusCode < 300 {
                            log(NetworkLogType.success(method.rawValue), requestId)
                            completion?(.success((response.statusCode, data)))
                            return
                        } else {
                            let error = ResponseError.network(response: response)
                            log(NetworkLogType.error(method.rawValue), requestId, error: error)
                            completion?(.failure(error))
                            return
                        }
                    }
                }
                .resume()
            } catch {
                completion?(.failure(error))
                return
            }
        }
    }
    
    /**
     Send request
     - parameter request: Request
     - parameter result: Request Result
     */
    public func request(_ request: RequestProtocol,
                        result: ((Result<NetworkResponse, Error>) -> Void)? = nil) {
        self.request(scheme: request.scheme,
                     host: request.host,
                     path: request.path,
                     port: request.port,
                     method: request.method,
                     parameters: request.parameters,
                     fileArray: request.fileArray,
                     encoding: request.encoding,
                     headers: request.headers,
                     authentification: request.authentification,
                     queue: request.queue,
                     identifier: request.identifier,
                     completion: result)
    }
}
