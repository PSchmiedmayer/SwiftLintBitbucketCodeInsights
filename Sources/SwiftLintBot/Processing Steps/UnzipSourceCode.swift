//
//  File.swift
//  
//
//  Created by Paul Schmiedmayer on 12/23/20.
//

import Vapor
import ShellOut

extension BitbucketEvent {
    func unzipSourceCode(on request: Request) throws -> EventLoopFuture<Void> {
        try shellOut(to: "rm -rf \(sourceCodeDirectory)")
        
        defer {
            request.logger.debug("Cleaning up the zip file at \(sourceCodeDirectory).zip")
            do {
                try shellOut(to: "rm \(sourceCodeDirectory).zip")
            } catch {
                request.logger.error("Could not clean up the .zip at \(sourceCodeDirectory).zip")
            }
        }
        
        try shellOut(
            to: "unzip",
            arguments: [
                "-o",
                "-q",
                "-d \(sourceCodeDirectory)",
                "\(sourceCodeDirectory)"
            ]
        )
        
        return try specifySwiftLintConfiguration(on: request)
    }
}
