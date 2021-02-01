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
        fileList: [String: URL]? = nil,
        encoding: Encoding = .url,
        headers: Headers? = nil,
        authentification: AuthentificationProtocol? = nil,
        queue: DispatchQueue = DispatchQueue.main,
        description: String? = nil,
        completion: ((Result<NetworkResponse, Error>) -> Void)? = nil,
        progressBlock: ((Double) -> Void)? = nil) {
        
        queue.async {
            do {
                var request: URLRequest = try self.buildRequest(scheme: scheme,
                                                                host: host,
                                                                path: path,
                                                                port: port,
                                                                method: method,
                                                                parameters: parameters,
                                                                fileList: fileList,
                                                                encoding: encoding,
                                                                headers: headers,
                                                                authentification: authentification)
                
                let requestId: String = description ?? request.url?.absoluteString ?? ""
                request.timeoutInterval = self.requestTimeoutInterval ?? request.timeoutInterval
                
                log(NetworkLogType.sending, requestId)
                let task = URLSession(configuration: self.requestConfiguration).dataTask(with: request) { data, response, error in
                    queue.async {
                        self.observation?.invalidate()
                        guard let response = response as? HTTPURLResponse else {
                            completion?(.failure(error ?? ResponseError.unknow))
                            return
                        }

                        log(NetworkLogType.sending, String(data: data ?? Data(), encoding: .utf8))
                        
                        if response.statusCode >= 200 && response.statusCode < 300 {
                            log(NetworkLogType.success, requestId)
                            completion?(.success((response.statusCode, data)))
                            return
                        } else {
                            let error = ResponseError.network(response: response)
                            log(NetworkLogType.error, requestId, error: error)
                            completion?(.failure(error))
                            return
                        }
                    }
                }

                if #available(iOS 11.0, *), let progressBlock: ((Double) -> Void) = progressBlock {
                    // Don't forget to invalidate the observation when you don't need it anymore.
                    self.observation = task.progress.observe(\.fractionCompleted) { progress, _ in
                        log(NetworkLogType.sending, "Progress : \(progress.fractionCompleted)", error: nil)
                        DispatchQueue.main.async {
                            progressBlock(progress.fractionCompleted)
                        }
                    }
                }

                task.resume()
            } catch {
                self.observation?.invalidate()
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
                        result: ((Result<NetworkResponse, Error>) -> Void)? = nil,
                        progressBlock: ((Double) -> Void)? = nil) {
        
        self.request(scheme: request.scheme,
                     host: request.host,
                     path: request.path,
                     port: request.port,
                     method: request.method,
                     parameters: request.parameters,
                     fileList: request.fileList,
                     encoding: request.encoding,
                     headers: request.headers,
                     authentification: request.authentification,
                     queue: request.queue,
                     description: request.description,
                     completion: result,
                     progressBlock: progressBlock)
    }
}
