//
//  SpecifySwiftLintConfiguration.swift
//  
//
//  Created by Paul Schmiedmayer on 12/21/20.
//

import ShellOut
import Vapor


extension BitbucketEvent {
    func specifySwiftLintConfiguration(on request: Request) throws -> EventLoopFuture<Void> {
        let fileURLs = try FileManager.default.contentsOfDirectory(at: URL(fileURLWithPath: sourceCodeDirectory), includingPropertiesForKeys: nil)
        guard !fileURLs.contains(where: { $0.lastPathComponent == ".swiftlint.yml" }) else {
            request.logger.info("Found a .swiftlint.yml file that will be used.")
            return try executeSwiftLint(on: request)
        }
        
        guard let defaultSwiftLintConfiguration = context.configuration else {
            request.logger.info("No .swiftlint.yml file was found")
            return try executeSwiftLint(on: request)
        }
        
        request.logger.info("No .swiftlint.yml file was found. Replacing it with a default file.")
        try shellOut(to: "cp \"\(defaultSwiftLintConfiguration.path)\" \"\(sourceCodeDirectory)/.swiftlint.yml\"")
        
        return try executeSwiftLint(on: request)
    }
}
