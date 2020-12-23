//
//  SpecifySwiftLintConfiguration.swift
//  
//
//  Created by Paul Schmiedmayer on 12/21/20.
//

import Vapor
import Files
import ShellOut


extension BitbucketEvent {
    func specifySwiftLintConfiguration(on request: Request) throws -> EventLoopFuture<Void> {
        let fileURLs = try FileManager.default.contentsOfDirectory(at: URL(fileURLWithPath: sourceCodeDirectory), includingPropertiesForKeys: nil)
        guard !fileURLs.contains(where: { $0.lastPathComponent == ".swiftlint.yml" }) else {
            app.logger.info("Found a .swiftlint.yml file that will be used.")
            return request.eventLoop.makeSucceededFuture(Void())
        }
        
        guard let defaultSwiftLintConfiguration = context.defaultSwiftLintConfiguration else {
            app.logger.info("No .swiftlint.yml file was found")
            return request.eventLoop.makeSucceededFuture(Void())
        }
        
        app.logger.info("No .swiftlint.yml file was found. Replacing it with a default file.")
        let sourceCodeFolder = try Folder(path: sourceCodeDirectory)
        try defaultSwiftLintConfiguration.copy(to: sourceCodeFolder)
        
        return try executeSwiftLint(on: request)
    }
}
