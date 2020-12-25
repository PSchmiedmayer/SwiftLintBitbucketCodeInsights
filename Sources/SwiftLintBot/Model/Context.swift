//
//  File 2.swift
//  
//
//  Created by Paul Schmiedmayer on 12/21/20.
//

import ArgumentParser
import ShellOut
import SwiftLintFramework
import Vapor


struct Context: ParsableCommand {
    @ArgumentParser.Option(help: "The Bitbucket instance that is used. E.g.: bitbucket.schmiedmayer.com.")
    var bitbucket: String
    
    @ArgumentParser.Option(help: "The Bitbucket secret used to authenticate with the Bitbucket instance.")
    var secret: String
    
    @ArgumentParser.Option(
        help: """
        The Bitbucket slug that should be used to identify this insighs tool.
        The default value is com.schmiedmayer.swiftlintbot
        """
    )
    var slug: String = "com.schmiedmayer.swiftlintbot"
    
    @ArgumentParser.Option(
        help: """
        The SwiftLint configuration file that should be used if there is no .swiftlint.yml file in the repository that should be evaluated.
        The default behaviour is to execute SwiftLint with no configuration.
        You can use `default` to use the swiftlint configuration file bundled with the SwiftLint Bitbucket Code Insights tool.
        """,
        transform: readConfigurationFile
    )
    var configuration: URL? = nil
    
    
    var baseURL: String {
        "https://\(bitbucket)/rest"
    }
    
    var requestHeader: HTTPHeaders {
        var headers = HTTPHeaders()
        headers.add(name: .authorization, value: "Bearer \(context.secret)")
        headers.add(name: "X-Atlassian-Token", value: "no-check")
        return headers
    }
    
    
    private static func readConfigurationFile(_ string: String) throws -> URL? {
        let potentialConfigurationFile: URL
        
        if string == "default",
           let potentialConfigurationFilePath = Bundle.module.url(forResource: "swiftlint", withExtension: "yml") {
            potentialConfigurationFile = potentialConfigurationFilePath
        } else {
            potentialConfigurationFile = URL(fileURLWithPath: string)
        }
        
        let relativePath = potentialConfigurationFile.relativePath(to: Bundle.module.bundleURL)
        app.logger.notice("Trying to load the default SwiftLint configuration at \(relativePath)")
        let _ = Configuration(configurationFiles: [potentialConfigurationFile.path])
        
        return potentialConfigurationFile
    }
}
