# ================================
# Build image
# ================================
FROM swift:latest as build

# Install OS updates and, if needed, sqlite3
RUN export DEBIAN_FRONTEND=noninteractive DEBCONF_NONINTERACTIVE_SEEN=true \
    && apt-get -q update \
    && apt-get -q dist-upgrade -y \
    && rm -rf /var/lib/apt/lists/*

# Set up a build area
WORKDIR /build

# First just resolve dependencies.
# This creates a cached layer that can be reused
# as long as your Package.swift/Package.resolved
# files do not change.
COPY ./Package.* ./
RUN swift package resolve

# Copy entire repo into container
COPY . .

# Build everything, with optimizations and test discovery
RUN swift build --enable-test-discovery -c release

# Switch to the staging area
WORKDIR /staging

# Copy main executable to staging area
RUN cp "$(swift build --package-path /build -c release --show-bin-path)/swiftlintbot" ./

# Copy resouces from the resources directory if the directories exist
# Ensure that by default, neither the directory nor any of its contents are writable.
RUN mv "$(swift build --package-path /build -c release --show-bin-path)/swiftlintbot_SwiftLintBot.resources" ./ && chmod -R a-w ./swiftlintbot_SwiftLintBot.resources

# Switch to the the libraries area
WORKDIR /libraries

# Copy the SourceKit library
RUN cp /usr/lib/libsourcekitdInProc.so ./

# ================================
# Run image
# ================================
FROM swift:slim

# Make sure all system packages are up to date.
RUN export DEBIAN_FRONTEND=noninteractive DEBCONF_NONINTERACTIVE_SEEN=true && \
    apt-get -q update && apt-get -q dist-upgrade -y && apt-get -q install unzip && rm -r /var/lib/apt/lists/*

# Create a swiftlint user and group with /app as its home directory
RUN useradd --user-group --create-home --system --skel /dev/null --home-dir /app swiftlint

# Switch to the new home directory
WORKDIR /app

# Copy built executable and any staged resources from builder
COPY --from=build --chown=swiftlint:swiftlint /staging /app

# Copy Swift runtime libraries
COPY --from=build --chown=swiftlint:swiftlint /libraries /usr/lib/

# Ensure all further commands run as the swiftlint user
USER swiftlint:swiftlint

# Let Docker bind to port 8080
EXPOSE 8080

# Start the Vapor service when the image is run, default to listening on 8080 in production environment
ENTRYPOINT ["./swiftlintbot"]
