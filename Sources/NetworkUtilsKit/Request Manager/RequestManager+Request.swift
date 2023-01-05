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
        queue: DispatchQueue = DispatchQueue.main,
        description: String? = nil,
        retryAuthentification: Bool = true,
        cachePolicy: URLRequest.CachePolicy = .reloadIgnoringLocalCacheData,
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
                                                                    authentification: authentification,
                                                                    cachePolicy: cachePolicy)
                    
                    var requestId: String = description ?? request.url?.absoluteString ?? ""
                    request.timeoutInterval = self.requestTimeoutInterval ?? request.timeoutInterval
                    
                    log(NetworkLogType.sending, requestId)
                    
                    let startDate = Date()
                    let task = URLSession(configuration: self.requestConfiguration)
                        .dataTask(with: request) { [weak self] data, response, error in
                            let time = Date().timeIntervalSince(startDate)
                            requestId += " - \(String(format: "%0.3f", time))s"
                            
                            queue.async {
#if canImport(CoreServices)
                                self?.observation?.invalidate()
#endif
                                guard let response = response as? HTTPURLResponse else {
                                    completion?(.failure(error ?? ResponseError.unknow))
                                    return
                                }
                                
                                if response.statusCode >= 200 && response.statusCode < 300 {
                                    if time > warningTime {
                                        log(NetworkLogType.successWarning, requestId)
                                    } else {
                                        log(NetworkLogType.success, requestId)
                                    }
                                    
                                    completion?(.success((response.statusCode, data)))
                                    return
                                } else if response.statusCode == 401 && retryAuthentification {
                                    var refreshArray: [AuthentificationRefreshableProtocol] = []
                                    
                                    if let refreshAuthent = authentification as? AuthentificationRefreshableProtocol {
                                        refreshArray = [refreshAuthent]
                                    } else if let authentificationArray = (authentification as? [AuthentificationProtocol])?
                                        .compactMap({ $0 as? AuthentificationRefreshableProtocol }) {
                                        refreshArray = authentificationArray
                                    }
                                    
                                    if !refreshArray.isEmpty {
                                        self?.refresh(authentification: refreshArray,
                                                      requestId: requestId,
                                                      request: request) { result in
                                            switch result {
                                            case .success:
                                                self?.request(scheme: scheme,
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
                                                              queue: queue,
                                                              description: description,
                                                              retryAuthentification: false,
                                                              cachePolicy: cachePolicy,
                                                              completion: completion,
                                                              progressBlock: progressBlock)
                                                
                                            case .failure:
                                                self?.returnError(requestId: requestId,
                                                                  response: response,
                                                                  data: data,
                                                                  completion: completion)
                                            }
                                        }
                                    } else {
                                        self?.returnError(requestId: requestId,
                                                          response: response,
                                                          data: data,
                                                          completion: completion)
                                    }
                                    return
                                } else {
                                    self?.returnError(requestId: requestId,
                                                      response: response,
                                                      data: data,
                                                      completion: completion)
                                    return
                                }
                            }
                        }
                    
#if canImport(CoreServices)
                    if let progressBlock: ((Double) -> Void) = progressBlock {
                        // Don't forget to invalidate the observation when you don't need it anymore.
                        self.observation = task.progress.observe(\.fractionCompleted) { progress, _ in
                            DispatchQueue.main.async {
                                progressBlock(progress.fractionCompleted)
                            }
                        }
                    }
#endif
                    
                    task.resume()
                } catch {
#if canImport(CoreServices)
                    self.observation?.invalidate()
#endif
                    completion?(.failure(error))
                    return
                }
            }
        }
    
    @Sendable
    private func refresh(authentification: [AuthentificationRefreshableProtocol],
                         requestId: String,
                         request: URLRequest,
                         completion: @escaping (Result<Void, Error>) -> Void) {
        guard let first = authentification.first else {
            completion(.success(()))
            return
        }
        
        Task {
            do {
                try await first.refresh(from: request)
                refresh(authentification: Array(authentification.dropFirst()),
                        requestId: requestId,
                        request: request,
                        completion: completion)
            } catch {
                completion(.failure(error))
            }
        }
    }
    
    private func returnError(requestId: String,
                             response: HTTPURLResponse,
                             data: Data?,
                             completion: ((Result<NetworkResponse, Error>) -> Void)?) {
        let error = ResponseError.network(response: response, data: data)
        log(NetworkLogType.error, requestId, error: error)
        completion?(.failure(error))
    }
    
    /**
     Send request
     - parameter request: Request
     - parameter result: Request Result
     */
    public func request(_ request: RequestProtocol,
                        progressBlock: ((Double) -> Void)? = nil) async throws -> NetworkResponse {
        try await withCheckedThrowingContinuation { continuation in
            self.request(scheme: request.scheme,
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
                         queue: request.queue,
                         description: request.description,
                         retryAuthentification: request.canRefreshToken,
                         cachePolicy: request.cachePolicy,
                         completion: { continuation.resume(with: $0) },
                         progressBlock: progressBlock)
        }
    }
}
