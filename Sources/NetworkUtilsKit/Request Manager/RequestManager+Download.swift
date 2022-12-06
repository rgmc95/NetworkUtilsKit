//
//  RequestManager+Download.swift
//  UtilsKit
//
//  Created by RGMC on 16/07/2019.
//  Copyright © 2019 RGMC. All rights reserved.
//
import Foundation
import UtilsKitCore

#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

// MARK: - Network download management
private class NetworkDownloadManagement: NSObject, URLSessionDownloadDelegate {
    
    let destination: URL
    let identifier: String?
    let completion: ((Result<Int, Error>) -> Void)?
    let progress: ((Float) -> Void)?
    
    init(destination: URL, identifier: String?, completion: ((Result<Int, Error>) -> Void)?, progress: ((Float) -> Void)?) {
        self.destination = destination
        self.identifier = identifier
        self.completion = { result -> Void in
            DispatchQueue.main.async {
                completion?(result)
            }
        }
        self.progress = { value in
            DispatchQueue.main.async {
                progress?(value)
            }
        }
    }
    
    // MARK: URLSessionDownloadDelegate
    func urlSession(_ session: URLSession,
                    downloadTask: URLSessionDownloadTask,
                    didFinishDownloadingTo location: URL) {
        
        guard let response = downloadTask.response as? HTTPURLResponse else {
            
            self.completion?(.failure(downloadTask.error ?? ResponseError.unknow))
            
            return
        }
        
        if response.statusCode >= 200 && response.statusCode < 300 {
            
            log(NetworkLogType.download, identifier)
            
            do {
                try FileManager.default.moveItem(at: location, to: destination)
                self.completion?(.success(response.statusCode))
            } catch {
                self.completion?(.failure(error))
            }
            return
        } else {
            let error = ResponseError.network(response: response, data: nil)
            log(NetworkLogType.error, identifier, error: error)
            
            self.completion?(.failure(error))
            
            return
        }
    }
    
    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        if error == nil { return }
        guard let response = task.response as? HTTPURLResponse else {
            self.completion?(.failure(task.error ?? ResponseError.unknow))
            return
        }
        
        let requestError = ResponseError.network(response: response, data: nil)
        
        log(NetworkLogType.error, identifier, error: requestError)
        
        self.completion?(.failure(requestError))
        
        return
    }
    
    func urlSession(_ session: URLSession,
                    downloadTask: URLSessionDownloadTask,
                    didWriteData bytesWritten: Int64,
                    totalBytesWritten: Int64,
                    totalBytesExpectedToWrite: Int64) {
        
        let progressValue = Float(totalBytesWritten) / Float(totalBytesExpectedToWrite)
        self.progress?(progressValue)
    }
}

// MARK: - Download
extension RequestManager {
    
    private func downloadFile(destinationURL: URL,
                              scheme: String,
                              host: String,
                              path: String,
                              port: Int?,
                              method: RequestMethod = .get,
                              parameters: ParametersArray? = nil,
                              encoding: Encoding = .url,
                              headers: Headers? = nil,
                              authentification: AuthentificationProtocol? = nil,
                              identifier: String? = nil,
                              forceDownload: Bool? = false,
                              cachePolicy: URLRequest.CachePolicy = .reloadIgnoringLocalCacheData,
                              completion: ((Result<Int, Error>) -> Void)? = nil,
                              progress: ((Float) -> Void)? = nil) {
        
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
                                            authentification: authentification,
                                            cachePolicy: cachePolicy)
        } catch {
            completion?(.failure(error))
            return
        }
        
        self.downloadFileWithRequest(request: request,
                                     destinationURL: destinationURL,
                                     identifier: identifier,
                                     forceDownload: forceDownload,
                                     completion: completion,
                                     progress: progress)
    }
    
    private func downloadFileWithRequest(request: URLRequest,
                                         destinationURL: URL,
                                         identifier: String? = nil,
                                         forceDownload: Bool? = false,
                                         completion: ((Result<Int, Error>) -> Void)? = nil,
                                         progress: ((Float) -> Void)? = nil) {
        
        var request: URLRequest = request // mutable request
        let requestId: String = identifier ?? request.url?.absoluteString ?? ""
        
        if FileManager.default.fileExists(atPath: destinationURL.path) {
            if forceDownload == true {
                //Remove file before download it again
                try? FileManager.default.removeItem(atPath: destinationURL.path)
            } else {
                //return success, file already exists
                completion?(.success(200))
                return
            }
        }
        
        let delegate = NetworkDownloadManagement(destination: destinationURL,
                                                 identifier: requestId,
                                                 completion: completion,
                                                 progress: progress)
        
        // downloadConfiguration is default (delegate Queue is Background by default)
        let session = URLSession(configuration: self.downloadConfiguration, delegate: delegate, delegateQueue: nil)
        if let timeoutInterval = self.downloadTimeoutInterval {
            request.timeoutInterval = timeoutInterval
        }
        
        log(NetworkLogType.download, requestId)
        
        session.downloadTask(with: request).resume()
    }
    
    /**
     Download url with request and gives the progress
     - parameter destinationURL : URL where the file will be copied
     - parameter request: Request
     - parameter forceDownload : download the file event if it already exists and delete previous existing. Return existing otherwise
     - parameter result: Download Result
     - parameter progress: Download progress
     */
    public func download(destinationURL: URL,
                         request: RequestProtocol,
                         forceDownload: Bool? = false,
                         progress: ((Float) -> Void)? = nil) async throws -> Int {
        try await withCheckedThrowingContinuation { continuation in
            self.downloadFile(destinationURL: destinationURL,
                              scheme: request.scheme,
                              host: request.host,
                              path: request.path,
                              port: request.port,
                              method: request.method,
                              parameters: request.parametersArray,
                              encoding: request.encoding,
                              headers: request.headers,
                              authentification: request.authentification,
                              identifier: request.identifier,
                              forceDownload: forceDownload,
                              cachePolicy: request.cachePolicy,
                              completion: { continuation.resume(with: $0) },
                              progress: progress)
        }
    }
    
    /**
     Download url with request and gives the progress
     - parameter sourceURL : URL of the file to download
     - parameter destinationURL : URL where the file will be copied
     - parameter forceDownload : download the file event if it already exists and delete previous existing. Return existing otherwise
     - parameter result: Download Result
     - parameter progress: Download progress
     */
    public func download(sourceURL: URL,
                         destinationURL: URL,
                         forceDownload: Bool? = false,
                         progress: ((Float) -> Void)? = nil) async throws -> Int {
        
        try await withCheckedThrowingContinuation { continuation in
            self.downloadFileWithRequest(request: URLRequest(url: sourceURL),
                                         destinationURL: destinationURL,
                                         forceDownload: forceDownload,
                                         completion: { continuation.resume(with: $0) },
                                         progress: progress)
        }
    }
}
