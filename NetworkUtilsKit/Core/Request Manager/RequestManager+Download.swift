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
    let progress: ((Float) -> Void)?

    init(destination: URL, identifier: String?, completion: ((Result<Int, Error>) -> Void)?, progress: ((Float) -> Void)?) {
        self.destination = destination
        self.identifier = identifier
        self.completion = completion
        self.progress = progress
    }

    // MARK : URLSessionDownloadDelegate
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
        let progressValue = Float(totalBytesWritten)/Float(totalBytesExpectedToWrite)
        progress?(progressValue)
    }
}

// MARK: - Download
extension RequestManager {
    
    private func downloadFile(destinationURL: URL,
                              forceDownload: Bool? = false,
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
                              progress: ((Float) -> Void)? = nil) {
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
            
            self.downloadFileWithRequest(request: request, destinationURL: destinationURL, queue: queue, identifier: identifier, forceDownload: forceDownload, completion: completion, progress: progress)
        }
    }

    private func downloadFileWithRequest(request : URLRequest,
                                         destinationURL: URL,
                                         queue: DispatchQueue = DispatchQueue.main,
                                         identifier: String? = nil,
                                         forceDownload: Bool? = false,
                                         completion: ((Result<Int, Error>) -> Void)? = nil,
                                         progress: ((Float) -> Void)? = nil) {
        queue.async {
            var request = request // mutable request
            let requestId: String = identifier ?? request.url?.absoluteString ?? ""

            if FileManager.default.fileExists(atPath: destinationURL.path) {
                if forceDownload == true {
                    //Remove file before download it again
                    try? FileManager.default.removeItem(atPath: destinationURL.path)
                } else {
                    //return success, file already exists
                    completion?(.success(200))
                }
            }

            let delegate = NetworkDownloadManagement(destination: destinationURL, identifier: requestId, completion: completion, progress: progress)
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
     - parameter destinationURL : URL where the file will be copied
     - parameter request: Request
     - parameter forceDownload : download the file event if it already exists and delete previous existing. Return existing otherwise
     - parameter result: Download Result
     - parameter progress: Download progress
     */
    public func download(destinationURL: URL,
                         request: RequestProtocol,
                         forceDownload: Bool? = false,
                         result: ((Result<Int, Error>) -> Void)? = nil,
                         progress: ((Float) -> Void)? = nil) {
        self.downloadFile(destinationURL: destinationURL,
                          forceDownload: forceDownload,
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
                         result: ((Result<Int, Error>) -> Void)? = nil,
                         progress: ((Float) -> Void)? = nil) {

        var request = URLRequest(url: sourceURL)
        self.downloadFileWithRequest(request: request,
                                     destinationURL: destinationURL,
                                     forceDownload: forceDownload,
                                     completion: result,
                                     progress: progress)

    }
}
