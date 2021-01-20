//
//  URLRequest+FormData.swift
//  NetworkUtilsKit
//
//  Created by David Douard on 20/01/2021.
//

import Foundation

extension URLRequest {

    class MultipartFormData {
        var request: URLRequest
        private lazy var boundary: String = {
           return String(format: "%08X%08X", arc4random(), arc4random())
        }()

        init(request: URLRequest) {
            self.request = request
        }

        func append(value: String, name: String) {
            request.httpBody?.append("--\(boundary)\r\n".data())
            request.httpBody?.append("Content-Disposition: form-data; name=\"\(name)\"\r\n\r\n".data())
            request.httpBody?.append("\(value)\r\n".data())
        }

        func append(filePath: String, name: String) throws {
            let url = URL(fileURLWithPath: filePath)
            try append(fileUrl: url, name: name)
        }

        func append(fileUrl: URL, name: String) throws {
            let fileName = fileUrl.lastPathComponent
            let mimeType = fileUrl.mimeType
            try append(fileUrl: fileUrl, name: name, fileName: fileName, mimeType: mimeType)
        }

        func append(fileUrl: URL, name: String, fileName: String, mimeType: String) throws {
            let data = try Data(contentsOf: fileUrl)
            append(file: data, name: name, fileName: fileName, mimeType: mimeType)
        }

        func append(file: Data, name: String, fileName: String, mimeType: String) {
            request.httpBody?.append("--\(boundary)\r\n".data())
            request.httpBody?.append("Content-Disposition: form-data; name=\"\(name)\";".data())
            request.httpBody?.append("filename=\"\(fileName)\"\r\n".data())
            request.httpBody?.append("Content-Type: \(mimeType)\r\n\r\n".data())
            request.httpBody?.append(file)
            request.httpBody?.append("\r\n".data())
        }

        fileprivate func finalize() {
            request.httpBody?.append("--\(boundary)--\r\n".data())
            request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        }
    }

    mutating func buildFormDataBody(constructingBlock: @escaping (_ formData: MultipartFormData) -> Void) {
        self.httpBody = Data()
        let formData = MultipartFormData(request: self)
        constructingBlock(formData)
        formData.finalize()
        self = formData.request
    }
}

fileprivate extension String {
    func data() -> Data {
        return self.data(using: .utf8) ?? Data()
    }
}
