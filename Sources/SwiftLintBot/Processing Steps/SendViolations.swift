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
            .flatMapThrowing {
                try updateInsightsReport(basedOn: violations, on: request)
            }
            .flatMapThrowing {
                try postAllAnnotations(basedOn: violations, on: request)
            }
            .flatMapThrowing {
                try cleanup(on: request)
            }
    }
    
    private func deleteAllAnnotations(on request: Request) throws -> EventLoopFuture<Void> {
        var headers = context.requestHeader
        headers.replaceOrAdd(name: "X-Atlassian-Token", value: "no-check")
        return request.client.delete(annotationsURL, headers: headers)
            .mapThrowing { response in
                guard response.status == .noContent else {
                    app.logger.error("Could not delete the annotations from bitbucket")
                    throw Abort(.internalServerError, reason: "Could not delete the annotations from bitbucket")
                }
            }
    }
    
    private func postAllAnnotations(basedOn violations: [StyleViolation], on request: Request) throws -> EventLoopFuture<Void> {
        request.client.post(annotationsURL, headers: context.requestHeader) { clientRequest in
                try clientRequest.content.encode(
                    [
                        "annotations": violations.map { try Annotation($0) }
                    ]
                )
        }
            .mapThrowing { response in
                guard response.status == .noContent else {
                    app.logger.error("Could not post the annotations")
                    throw Abort(.internalServerError, reason: "Could not post the annotations")
                }
            }
    }
    
    private func updateInsightsReport(basedOn violations: [StyleViolation], on request: Request) throws -> EventLoopFuture<Void> {
        request.client.put(reportURL, headers: context.requestHeader) { clientRequest in
                try clientRequest.content.encode(InsightsReport(violations))
        }
            .mapThrowing { response in
                guard response.status == .ok else {
                    app.logger.error("Could not update the insights report")
                    throw Abort(.internalServerError, reason: "Could not update the insights report")
                }
            }
    }
}
