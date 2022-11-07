//
//  URL+RequestHelper.swift
//  NetworkUtilsKit
//
//  Created by David Douard on 19/01/2021.
//

import Foundation
import UtilsKit

extension URL {
    
    internal var mimeType: String {
        self.contentType(for: self.pathExtension)
    }
    
    private func contentType(for pathExtension: String) -> String {
        guard
            let uti = UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension,
                                                            pathExtension as CFString,
                                                            nil)?.takeRetainedValue()
        else {
            return "application/octet-stream"
        }
        
        let contentTypeCString = UTTypeCopyPreferredTagWithClass(uti, kUTTagClassMIMEType)?.takeRetainedValue()
        
        guard
            let contentType = contentTypeCString as String?
        else {
            return "application/octet-stream"
        }
        return contentType
    }
    
    /**
     Get the content of a file at URL
     - returns: data of the retrieved file or nil.
     */
    public func contentData() -> Data? {
        do {
            return try Data(contentsOf: self)
        } catch {
            log(.file, "Getting content of document at url \(self)", error: error)
            return nil
        }
    }
}
