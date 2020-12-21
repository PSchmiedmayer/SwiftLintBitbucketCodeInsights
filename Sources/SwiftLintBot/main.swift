import Vapor
import ShellOut

var env = try Environment.detect()
try LoggingSystem.bootstrap(from: &env)

let app = Application(env)
defer {
    app.shutdown()
}

let context = try Context()


app.post() { request in
    try BitbucketEvent
        .create(from: request)
        .flatMapThrowing { bitbucketEvent -> EventLoopFuture<BitbucketEvent> in
            app.logger.info("Parsed webhook request: \(bitbucketEvent.type)")
            return try bitbucketEvent.downloadSourceCode(on: request)
                .transform(to: bitbucketEvent)
        }
        .flatMapThrowing { bitbucketEvent -> EventLoopFuture<BitbucketEvent> in
            return try bitbucketEvent.specifySwiftLintConfiguration(on: request)
                .transform(to: bitbucketEvent)
        }
        .flatMapThrowing { bitbucketEvent -> EventLoopFuture<BitbucketEvent> in
            return try bitbucketEvent.cleanup(on: request)
                .transform(to: bitbucketEvent)
        }
        .transform(to: "Done ✅")
}

try app.run()
