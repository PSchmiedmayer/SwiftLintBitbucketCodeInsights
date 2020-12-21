//
//  DownloadSourceCode.swift
//  
//
//  Created by Paul Schmiedmayer on 12/21/20.
//

import Vapor
import ShellOut

extension BitbucketEvent {
    private var archiveRequetsURL: URI {
        "\(context.baseURL)/projects/\(project.key)/repos/\(repository.key)/archive?at=\(pullRequest.commitHash)&filename=\(pullRequest.commitHash).zip&format=zip"
    }
    
    func downloadSourceCode(on request: Request) throws -> EventLoopFuture<Void> {
        try shellOut(to: "mkdir -p \(self.workingDirectory)")
        
        return request.client
            .get(archiveRequetsURL, headers: context.requestHeader)
            .flatMapThrowing { response -> ByteBuffer? in
                guard response.status == .ok else {
                    app.logger.error("Could not download the .zip from \(archiveRequetsURL)")
                    throw Abort(.internalServerError, reason: "Could not download the .zip archieve from BitBucket")
                }
                
                app.logger.info("Recieved Zip Archive from Bitbucket (\(response.body?.readableBytes ?? 0) B)")
                return response.body
            }
            .unwrap(or: Abort(.badRequest, reason: "Could not parse the pull request body"))
            .map { byteBuffer in
                request.fileio.writeFile(byteBuffer, at: "\(workingDirectory)/\(pullRequest.commitHash).zip")
            }
            .flatMapThrowing { _ in
                try shellOut(
                    to: "unzip",
                    arguments: [
                        "-o",
                        "-q",
                        "-d \(sourceCodeDirectory)",
                        "\(sourceCodeDirectory)"
                    ]
                )
            }
            .mapThrowing {
                app.logger.info("Cleaning up the zip file at \(sourceCodeDirectory).zip")
                try shellOut(to: "rm \(sourceCodeDirectory).zip")
            }
    }
}