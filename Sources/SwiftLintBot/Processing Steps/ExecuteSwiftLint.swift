//
//  File.swift
//  
//
//  Created by Paul Schmiedmayer on 12/21/20.
//

import Vapor
import SwiftLintFramework

extension BitbucketEvent {
    func executeSwiftLint(on request: Request) throws -> EventLoopFuture<Void> {
        let configuration = Configuration(configurationFiles: [sourceCodeDirectory + "/.swiftlint.yml"])
        
        var swiftFiles: [SwiftLintFile] = []
        let directoryEnumerator = FileManager.default.enumerator(atPath: sourceCodeDirectory)
        while let path = directoryEnumerator?.nextObject() as? String {
            if configuration.excludedPaths.contains(where: { path.hasPrefix($0) }) {
                continue
            }
            if path.hasSuffix("swift"), let swiftFile = SwiftLintFile(path: sourceCodeDirectory + "/" + path) {
                swiftFiles.append(swiftFile)
            }
        }
        
        request.logger.info("Start linting \(swiftFiles.count) Swift files.")
        var violations: [StyleViolation] = []
        for swiftFile in swiftFiles {
            let storage = RuleStorage()
            let styleViolations = Linter(file: swiftFile, configuration: configuration)
                .collect(into: storage)
                .styleViolations(using: storage)
            
            request.logger.debug("Found \(styleViolations.count) violations in \(swiftFile.path ?? "undefined Swift file")")
            
            violations.append(contentsOf: styleViolations)
        }
        
        request.logger.info("Found \(violations.count) violations")
        return try send(violations, on: request)
    }
}
