//
//  File.swift
//  
//
//  Created by Paul Schmiedmayer on 12/23/20.
//

import Vapor
import SwiftLintFramework

extension BitbucketEvent {
    private var reportURL: URI {
        "\(context.baseURL)/insights/latest/projects/\(project.key)/repos/\(repository.key)/commits/\(pullRequest.commitHash)/reports/\(context.slug)"
    }
    
    private var annotationsURL: URI {
        "\(reportURL)/annotations"
    }
    
    func send(_ violations: [StyleViolation], on request: Request) throws -> EventLoopFuture<Void> {
        try deleteAllAnnotations(on: request)
            .flatMap { () -> EventLoopFuture<Void> in
                do {
                    return try updateInsightsReport(basedOn: violations, on: request)
                } catch {
                    return request.eventLoop.makeFailedFuture(error)
                }
            }
            .flatMap { () -> EventLoopFuture<Void> in
                do {
                    return try postAllAnnotations(basedOn: violations, on: request)
                } catch {
                    return request.eventLoop.makeFailedFuture(error)
                }
            }
            .flatMapAlways { result in
                do {
                    if case let .failure(error) = result {
                        request.logger.error("Could not send data to Bitbucket: \(error)")
                    }
                    return try cleanup(on: request)
                } catch {
                    request.logger.error("Could not Cleanup the working directory at \(sourceCodeDirectory)")
                    return request.eventLoop.makeSucceededFuture(Void())
                }
            }
    }
    
    private func deleteAllAnnotations(on request: Request) throws -> EventLoopFuture<Void> {
        return request.client.delete(annotationsURL, headers: context.requestHeader)
            .flatMapThrowing { response in
                guard response.status == .noContent else {
                    request.logger.error("Could not delete the annotations from bitbucket")
                    throw Abort(.internalServerError, reason: "Could not delete the annotations from bitbucket")
                }
            }
    }
    
    private func postAllAnnotations(basedOn violations: [StyleViolation], on request: Request) throws -> EventLoopFuture<Void> {
        request.client.post(annotationsURL, headers: context.requestHeader) { clientRequest in
                try clientRequest.content.encode(
                    [
                        "annotations": violations.map { try Annotation($0, relativeTo: URL(fileURLWithPath: sourceCodeDirectory)) }
                    ]
                )
        }
            .flatMapThrowing { response in
                guard response.status == .noContent else {
                    request.logger.error("Could not post the annotations")
                    throw Abort(.internalServerError, reason: "Could not post the annotations")
                }
            }
    }
    
    private func updateInsightsReport(basedOn violations: [StyleViolation], on request: Request) throws -> EventLoopFuture<Void> {
        request.client.put(reportURL, headers: context.requestHeader) { clientRequest in
            try clientRequest.content.encode(InsightsReport(violations))
        }
            .flatMapThrowing { response in
                guard response.status == .ok else {
                    request.logger.error("Could not update the insights report")
                    throw Abort(.internalServerError, reason: "Could not update the insights report")
                }
            }
    }
}
