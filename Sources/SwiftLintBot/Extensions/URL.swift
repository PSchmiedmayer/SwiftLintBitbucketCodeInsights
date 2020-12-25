//
//  URL.swift
//  
//
//  Created by Paul Schmiedmayer on 12/25/20.
//

import Foundation


extension URL {
    func relativePath(to reativeURL: URL) -> String {
        let ownComponents = self.standardized.pathComponents
        let reativeURLComponents = reativeURL.standardized.pathComponents

        // Find number of common path components:
        var commonComponents = 0
        while commonComponents < ownComponents.count && commonComponents < reativeURLComponents.count
                && ownComponents[commonComponents] == reativeURLComponents[commonComponents] {
            commonComponents += 1
        }
        
        return ownComponents[commonComponents...].joined(separator: "/")
    }
}
