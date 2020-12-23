//
//  File 2.swift
//  
//
//  Created by Paul Schmiedmayer on 12/21/20.
//

import Vapor
import Files
import ShellOut


struct Context {
    let bitbucket: String
    let baseURL: String
    let token: String
    let reportSlug: String
    let defaultSwiftLintConfiguration: Files.File?
    
    
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
        
        self.baseURL = "https://\(bitbucket)/rest"

        guard let token = Environment.get("BITBUCKETSECRET") else {
            throw Abort(.internalServerError,
                        reason: "Could not find a \"BITBUCKETSECRET\" environment variable to specify an Bitbucket access token.")
        }
        self.token = token
        let reportSlug = Environment.get("BITBUCKETREPORTSLUG") ?? "com.schmiedmayer.swiftlintbot"
        app.logger.info("The SwiftLint Bot will use the \"\(reportSlug)\" report slug name.")
        self.reportSlug = reportSlug
        
        if let useBuildInSwiftConfigurationFile = Environment.get("USEBUILDINSWIFTLINTCONFIGURATIONFILE"),
           Bool(useBuildInSwiftConfigurationFile) ?? false,
           let defaultSwiftLintConfigurationPath = Bundle.module.url(forResource: "swiftlint", withExtension: "yml")?.path {
            self.defaultSwiftLintConfiguration = try File(path: defaultSwiftLintConfigurationPath)
        } else if let customSwiftLintConfigurationPath = Environment.get("CUSTOMSWIFTLINTCONFIGURATIONFILE") {
            self.defaultSwiftLintConfiguration = try File(path: customSwiftLintConfigurationPath)
        } else {
            self.defaultSwiftLintConfiguration = nil
        }
        
        if let defaultSwiftLintConfiguration = self.defaultSwiftLintConfiguration,
           defaultSwiftLintConfiguration.nameExcludingExtension.lowercased() == "swiftlint" {
            let defaultSwiftLintConfigurationURL = URL(fileURLWithPath: defaultSwiftLintConfiguration.path)
                .deletingLastPathComponent()
                .appendingPathComponent(".swiftlint.yml")
                .path
            
            try shellOut(to: "rm -f \"\(defaultSwiftLintConfigurationURL)\"")
            try self.defaultSwiftLintConfiguration?.rename(to: ".swiftlint", keepExtension: true)
        }
    }
}
