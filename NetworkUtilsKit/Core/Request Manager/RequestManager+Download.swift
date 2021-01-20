//
//  RequestManager+Download.swift
//  UtilsKit
//
//  Created by RGMC on 16/07/2019.
//  Copyright © 2019 RGMC. All rights reserved.
//

import Foundation
import UtilsKit

// MARK: - Network download management
private class NetworkDownloadManagement: NSObject, URLSessionDownloadDelegate {
    
    let destination: URL
    let identifier: String?
    let completion: ((Result<Int, Error>) -> Void)?
    let progress: ((URLSessionDownloadTask) -> Void)?
    
    init(destination: URL, identifier: String?, completion: ((Result<Int, Error>) -> Void)?, progress: ((URLSessionDownloadTask) -> Void)?) {
        self.destination = destination
        self.identifier = identifier
        self.completion = completion
        self.progress = progress
    }
    
    func urlSession(_ session: URLSession,
                    downloadTask: URLSessionDownloadTask,
                    didFinishDownloadingTo location: URL) {
        
        guard let response = downloadTask.response as? HTTPURLResponse else {
            completion?(.failure(ResponseError.unknow))
            return
        }
        
        if response.statusCode >= 200 && response.statusCode < 300 {
            
            log(NetworkLogType.download, identifier)
            
            do {
                try FileManager.default.moveItem(at: location, to: destination)
                completion?(.success(response.statusCode))
            } catch {
                completion?(.failure(error))
            }
            
            return
        } else {
            let error = ResponseError.network(response: response)
            log(NetworkLogType.error, identifier, error: error)
            completion?(.failure(error))
            return
        }
    }
    
    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        if error == nil { return }
        guard let response = task.response as? HTTPURLResponse else {
            completion?(.failure(ResponseError.unknow))
            return
        }
        
        let requestError = ResponseError.network(response: response)
        
        log(NetworkLogType.error, identifier, error: requestError)
        completion?(.failure(requestError))
        return
    }
    
    func urlSession(_ session: URLSession,
                    downloadTask: URLSessionDownloadTask,
                    didWriteData bytesWritten: Int64,
                    totalBytesWritten: Int64,
                    totalBytesExpectedToWrite: Int64) {
        progress?(downloadTask)
    }
}

// MARK: - Download
extension RequestManager {
    
    private func downloadRequest(at URL: URL,
                                 scheme: String,
                                 host: String,
                                 path: String,
                                 port: Int?,
                                 method: RequestMethod = .get,
                                 parameters: Parameters? = nil,
                                 encoding: Encoding = .url,
                                 headers: Headers? = nil,
                                 authentification: AuthentificationProtocol? = nil,
                                 queue: DispatchQueue = DispatchQueue.main,
                                 identifier: String? = nil,
                                 completion: ((Result<Int, Error>) -> Void)? = nil,
                                 progress: ((URLSessionDownloadTask) -> Void)? = nil) {
        queue.async {
            var request: URLRequest
            
            do {
                request = try self.buildRequest(scheme: scheme,
                                                host: host,
                                                path: path,
                                                port: port,
                                                method: method,
                                                parameters: parameters,
                                                encoding: encoding,
                                                headers: headers,
                                                authentification: authentification)
            } catch {
                completion?(.failure(error))
                return
            }
            
            let requestId: String = identifier ?? request.url?.absoluteString ?? ""
            
            let delegate = NetworkDownloadManagement(destination: URL, identifier: requestId, completion: completion, progress: progress)
            let session = URLSession(configuration: self.downloadConfiguration, delegate: delegate, delegateQueue: nil)
            
            if let timeoutInterval = self.downloadTimeoutInterval {
                request.timeoutInterval = timeoutInterval
            }
            
            log(NetworkLogType.download, requestId)
            
            session.downloadTask(with: request).resume()
        }
    }
    
    /**
     Download url with request and gives the progress
     - parameter URL : URL
     - parameter request: Request
     - parameter result: Download Result
     - parameter progress: Download progress
     */
    public func download(at URL: URL,
                         request: RequestProtocol,
                         result: ((Result<Int, Error>) -> Void)? = nil,
                         progress: ((URLSessionDownloadTask) -> Void)? = nil) {
        self.downloadRequest(at: URL,
                             scheme: request.scheme,
                             host: request.host,
                             path: request.path,
                             port: request.port,
                             method: request.method,
                             parameters: request.parameters,
                             encoding: request.encoding,
                             headers: request.headers,
                             authentification: request.authentification,
                             queue: request.queue,
                             identifier: request.identifier,
                             completion: result,
                             progress: progress)
    }
}
