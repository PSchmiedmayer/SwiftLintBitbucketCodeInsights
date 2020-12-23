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
        try shellOut(
            to: "unzip",
            arguments: [
                "-o",
                "-q",
                "-d \(sourceCodeDirectory)",
                "\(sourceCodeDirectory)"
            ]
        )
        
        app.logger.info("Cleaning up the zip file at \(sourceCodeDirectory).zip")
        try shellOut(to: "rm \(sourceCodeDirectory).zip")
        
        return try specifySwiftLintConfiguration(on: request)
    }
}
