//
//  File 2.swift
//  
//
//  Created by Paul Schmiedmayer on 12/21/20.
//

import Vapor


struct Context {
    let bitbucket: String
    let baseURL: String
    let token: String
    let reportSlug: String
    
    
    var requestHeader: HTTPHeaders {
        var headers = HTTPHeaders()
        headers.add(name: .authorization, value: "Bearer \(context.token)")
        return headers
    }
    
    
    init() throws {
        guard let bitbucket = Environment.get("BITBUCKET") else {
            throw Abort(.internalServerError,
                        reason: "Could not find a \"BITBUCKET\" environment variable to specify the Bitbucket instance.")
        }
        self.bitbucket = bitbucket
        app.logger.info("The SwiftLint Bot will use https://\(bitbucket)")
        
        self.baseURL = "https://\(bitbucket)/rest/api/latest"

        guard let token = Environment.get("BITBUCKETSECRET") else {
            throw Abort(.internalServerError,
                        reason: "Could not find a \"BITBUCKETSECRET\" environment variable to specify an Bitbucket access token.")
        }
        self.token = token
        self.reportSlug = Environment.get("BITBUCKETREPORTSLUG") ?? "com.schmiedmayer.swiftlintbot"
        app.logger.info("The SwiftLint Bot will use the \"\(self.reportSlug)\" report slug name.")
    }
}
