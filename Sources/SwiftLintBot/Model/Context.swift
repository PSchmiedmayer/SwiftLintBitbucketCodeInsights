//
//  File 2.swift
//  
//
//  Created by Paul Schmiedmayer on 12/21/20.
//

import Vapor
import Files
import ShellOut
import ArgumentParser

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
    var defaultConfiguration: Files.File? = nil
    
    
    var baseURL: String {
        "https://\(bitbucket)/rest"
    }
    
    var requestHeader: HTTPHeaders {
        var headers = HTTPHeaders()
        headers.add(name: .authorization, value: "Bearer \(context.secret)")
        return headers
    }
    
    
    private static func readConfigurationFile(_ string: String) throws -> Files.File? {
        let potentialConfigurationFile: Files.File
        
        if string == "default",
           let potentialConfigurationFilePath = Bundle.module.url(forResource: "swiftlint", withExtension: "yml")?.path {
            potentialConfigurationFile = try File(path: potentialConfigurationFilePath)
        } else if let potentialCustomConfigurationFile = try? File(path: string) {
            potentialConfigurationFile = potentialCustomConfigurationFile
        } else {
            return nil
        }
        
        if potentialConfigurationFile.nameExcludingExtension.lowercased() == "swiftlint" {
            let defaultSwiftLintConfigurationURL = URL(fileURLWithPath: potentialConfigurationFile.path)
                .deletingLastPathComponent()
                .appendingPathComponent(".swiftlint.yml")
                .path
            
            try shellOut(to: "rm -f \"\(defaultSwiftLintConfigurationURL)\"")
            try potentialConfigurationFile.rename(to: ".swiftlint", keepExtension: true)
        }
        
        return potentialConfigurationFile
    }
}
