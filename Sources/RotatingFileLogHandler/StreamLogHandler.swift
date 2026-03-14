//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift Logging API open source project
//
// Copyright (c) 2018-2019 Apple Inc. and the Swift Logging API project authors
// Licensed under Apache License v2.0
//
// See LICENSE.txt for license information
// See CONTRIBUTORS.txt for the list of Swift Logging API project authors
//
// SPDX-License-Identifier: Apache-2.0
//
// This copy originated from the 1.10.1 version, with the intention of reusing
// the code by gaining access to the internal init() function.
//
// The only modification have been the deletion of public static factory functions.
//
//===----------------------------------------------------------------------===//

import Logging

#if canImport(Darwin)
import Darwin
#elseif os(Windows)
import CRT
#elseif canImport(Glibc)
@preconcurrency import Glibc
#elseif canImport(Android)
@preconcurrency import Android
#elseif canImport(Musl)
import Musl
#elseif canImport(WASILibc)
import WASILibc
#else
#error("Unsupported runtime")
#endif

/// Stream log handler presents log messages to STDERR or STDOUT.
///
/// This is a simple implementation of `LogHandler` that directs
/// `Logger` output to either `stderr` or `stdout` via the factory methods.
///
/// Metadata is merged in the following order:
/// 1. Metadata set on the log handler itself is used as the base metadata.
/// 2. The handler's ``metadataProvider`` is invoked, overriding any existing keys.
/// 3. The per-log-statement metadata is merged, overriding any previously set keys.
struct StreamLogHandler: LogHandler {
    internal typealias _SendableTextOutputStream = TextOutputStream & Sendable

    private let stream: any _SendableTextOutputStream
    private let label: String

    /// Get the log level configured for this `Logger`.
    ///
    /// > Note: Changing the log level threshold for a logger only affects the instance of the `Logger` where you change it.
    /// > It is acceptable for logging backends to have some form of global log level override
    /// > that affects multiple or even all loggers. This means a change in `logLevel` to one `Logger` might in
    /// > certain cases have no effect.
    public var logLevel: Logger.Level = .info

    /// The metadata provider.
    public var metadataProvider: Logger.MetadataProvider?

    private var prettyMetadata: String?
    /// Get or set the entire metadata storage as a dictionary.
    public var metadata = Logger.Metadata() {
        didSet {
            self.prettyMetadata = self.prettify(self.metadata)
        }
    }

    /// Add, change, or remove a logging metadata item.
    ///
    /// > Note: Changing the logging metadata only affects the instance of the `Logger` where you change it.
    public subscript(metadataKey metadataKey: String) -> Logger.Metadata.Value? {
        get {
            self.metadata[metadataKey]
        }
        set {
            self.metadata[metadataKey] = newValue
        }
    }

    // internal for testing only
    internal init(label: String, stream: any _SendableTextOutputStream) {
        self.init(label: label, stream: stream, metadataProvider: LoggingSystem.metadataProvider)
    }

    // internal for testing only
    internal init(label: String, stream: any _SendableTextOutputStream, metadataProvider: Logger.MetadataProvider?) {
        self.label = label
        self.stream = stream
        self.metadataProvider = metadataProvider
    }

    /// Log a message using the log level and source that you provide.
    ///
    /// - parameters:
    ///    - level: The log level to log the `message`.
    ///    - message: The message to be logged. The `message` parameter supports any string interpolation literal.
    ///    - explicitMetadata: One-off metadata to attach to this log message.
    ///    - source: The source this log message originates from. The value defaults
    ///              to the module that emits the log message.
    ///    - file: The file this log message originates from. There's usually no need to pass it explicitly, as it
    ///            defaults to `#fileID`.
    ///    - function: The function this log message originates from. There's usually no need to pass it explicitly, as
    ///                it defaults to `#function`.
    ///    - line: The line this log message originates from. There's usually no need to pass it explicitly, as it
    ///            defaults to `#line`.
    public func log(
        level: Logger.Level,
        message: Logger.Message,
        metadata explicitMetadata: Logger.Metadata?,
        source: String,
        file: String,
        function: String,
        line: UInt
    ) {
        let effectiveMetadata = StreamLogHandler.prepareMetadata(
            base: self.metadata,
            provider: self.metadataProvider,
            explicit: explicitMetadata
        )

        let prettyMetadata: String?
        if let effectiveMetadata = effectiveMetadata {
            prettyMetadata = self.prettify(effectiveMetadata)
        } else {
            prettyMetadata = self.prettyMetadata
        }

        var stream = self.stream
        stream.write(
            "\(self.timestamp()) \(level)\(self.label.isEmpty ? "" : " ")\(self.label):\(prettyMetadata.map { " \($0)" } ?? "") [\(source)] \(message)\n"
        )
    }

    internal static func prepareMetadata(
        base: Logger.Metadata,
        provider: Logger.MetadataProvider?,
        explicit: Logger.Metadata?
    ) -> Logger.Metadata? {
        var metadata = base

        let provided = provider?.get() ?? [:]

        guard !provided.isEmpty || !((explicit ?? [:]).isEmpty) else {
            // all per-log-statement values are empty
            return nil
        }

        if !provided.isEmpty {
            metadata.merge(provided, uniquingKeysWith: { _, provided in provided })
        }

        if let explicit = explicit, !explicit.isEmpty {
            metadata.merge(explicit, uniquingKeysWith: { _, explicit in explicit })
        }

        return metadata
    }

    private func prettify(_ metadata: Logger.Metadata) -> String? {
        if metadata.isEmpty {
            return nil
        } else {
            return metadata.lazy.sorted(by: { $0.key < $1.key }).map { "\($0)=\($1)" }.joined(separator: " ")
        }
    }

    private func timestamp() -> String {
        var buffer = [Int8](repeating: 0, count: 255)
        #if os(Windows)
        var timestamp = __time64_t()
        _ = _time64(&timestamp)

        var localTime = tm()
        _ = _localtime64_s(&localTime, &timestamp)

        _ = strftime(&buffer, buffer.count, "%Y-%m-%dT%H:%M:%S%z", &localTime)
        #else
        var timestamp = time(nil)
        guard let localTime = localtime(&timestamp) else {
            return "<unknown>"
        }
        strftime(&buffer, buffer.count, "%Y-%m-%dT%H:%M:%S%z", localTime)
        #endif
        return buffer.withUnsafeBufferPointer {
            $0.withMemoryRebound(to: CChar.self) {
                String(cString: $0.baseAddress!)
            }
        }
    }
}
