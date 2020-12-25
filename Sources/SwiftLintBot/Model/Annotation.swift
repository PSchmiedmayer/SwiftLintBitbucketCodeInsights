//
//  File.swift
//  
//
//  Created by Paul Schmiedmayer on 12/23/20.
//

import SwiftLintFramework
import Vapor


struct Annotation: Content {
    enum Severity: String, Codable {
        case low = "LOW"
        case medium = "MEDIUM"
        case high = "HIGH"
        
        init(_ severity: ViolationSeverity) {
            switch severity {
            case .warning:
                self = .medium
            case .error:
                self = .high
            }
        }
    }
    
    enum AnnotationType: String, Codable {
        case vulnerability = "VULNERABILITY"
        case codesmell = "CODE_SMELL"
        case bug = "BUG"
    }
    
    let path: String?
    let line: Int?
    let message: String
    let severity: Severity
}

extension Annotation {
    init(_ styleViolation: StyleViolation, relativeTo sourceCodeDirectory: URL) throws {
        self.path = URL(fileURLWithPath: styleViolation.location.file ?? "").relativePath(to: sourceCodeDirectory)
        self.line = styleViolation.location.line
        self.message = "\(styleViolation.ruleName) Violation: \(styleViolation.reason) [\(styleViolation.ruleIdentifier)]"
        self.severity = Severity(styleViolation.severity)
    }
}
