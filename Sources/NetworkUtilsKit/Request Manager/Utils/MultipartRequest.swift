//
//  MultipartRequest.swift
//  KeychainSwift
//
//  Created by Michael Coqueret on 08/09/2023.
//

import Foundation

private extension Data {
	
	mutating func append(_ string: String,
						 encoding: String.Encoding = .utf8) {
		guard let data = string.data(using: encoding) else { return }
		self.append(data)
	}
}

struct MultipartRequest {
	
	let boundary: String
	
	private let separator: String = "\r\n"
	private var data: Data
	
	var httpContentTypeHeadeValue: String { "multipart/form-data; boundary=\(boundary)" }
	
	var httpBody: Data {
		var bodyData = self.data
		bodyData.append("--\(self.boundary)--")
		return bodyData
	}
	
	init(boundary: String = UUID().uuidString) {
		self.boundary = boundary
		self.data = .init()
	}
	
	private mutating func appendBoundarySeparator() {
		self.data.append("--\(self.boundary)\(self.separator)")
	}
	
	private mutating func appendSeparator() {
		self.data.append(self.separator)
	}
	
	private func disposition(_ key: String) -> String {
		"Content-Disposition: form-data; name=\"\(key)\""
	}
	
	mutating func add(key: String, value: String) {
		self.appendBoundarySeparator()
		self.data.append(self.disposition(key) + self.separator)
		self.appendSeparator()
		self.data.append(value + self.separator)
	}
	
	mutating func add(key: String,
					  fileName: String,
					  fileMimeType: String,
					  fileData: Data) {
		
		self.appendBoundarySeparator()
		self.data.append(self.disposition(key) + "; filename=\"\(fileName)\"" + self.separator)
		self.data.append("Content-Type: \(fileMimeType)" + self.separator + self.separator)
		self.data.append(fileData)
		self.appendSeparator()
	}
}
