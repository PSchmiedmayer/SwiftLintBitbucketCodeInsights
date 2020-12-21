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
        .flatMapThrowing { bitbucketEvent -> EventLoopFuture<String> in
            app.logger.info("Parsed webhook request: \(bitbucketEvent.type)")
            return try bitbucketEvent.downloadSourceCode(on: request)
                .map {
                    "Downloaded the source code"
                }
        }
}

try app.run()
