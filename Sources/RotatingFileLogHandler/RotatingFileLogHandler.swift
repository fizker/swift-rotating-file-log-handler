public import Logging
public import SystemPackage

/// A `LogHandler` implementation that writes log messages to rotating files on disk.
///
/// # Overview
/// The `RotatingFileLogHandler` manages log files within a specified folder, creating new files
/// once a configurable number of log lines is reached. This helps prevent individual log files
/// from growing too large. It buffers writes to improve performance and periodically flushes data
/// to disk based on a specified delay.
///
/// This handler integrates with SwiftLog by providing `LogHandler` instances configured with the
/// current log level and metadata. It is suitable for applications that require persistent,
/// file-based logging with automatic file rotation.
///
/// # Example
/// ```swift
/// let logHandler = try RotatingFileLogHandler(
///     folderPath: "/var/log/myapp",
///     filenamePrefix: "app-log",
/// )
/// var logger = Logger(label: "com.example.myapp", factory: { _ in
///     logHandler.handler(label: "com.example.myapp")
/// })
/// logger.info("Application started")
/// try logHandler.flush()
/// ```
public struct RotatingFileLogHandler: Sendable {
	/// The metadata associated with all log messages emitted by this handler.
	///
	/// This metadata is merged with metadata provided by individual log calls.
	/// Changing this value affects all subsequently created `LogHandler` instances.
	/// Defaults to an empty dictionary.
	public var metadata: Logger.Metadata

	/// The minimum severity level of log messages that this handler will emit.
	///
	/// Only messages at or above this level will be logged.
	/// Changing this value affects all subsequently created `LogHandler` instances.
	/// Defaults to `.info`.
	public var logLevel: Logger.Level

	let folderPath: FilePath
	let filenamePrefix: String
	let writer: BufferedWriter

	/// Creates a new `RotatingFileLogHandler` that writes log messages to files within the specified folder.
	///
	/// - Parameters:
	///   - logLevel: The minimum severity level of messages to log. Defaults to `.info`.
	///   - metadata: Initial metadata to attach to all log messages. Defaults to empty.
	///   - folderPath: The folder where log files will be created.
	///   - filenamePrefix: The prefix used for log file names.
	///   - linesPerFile: Maximum number of lines per log file before rotating. Defaults to 1000; values less than 100 will be clamped to 100.
	///   - flushDelay: The delay between buffered writes and actual disk flushes. Defaults to 1 second.
	///
	/// - Throws: An error if the underlying `BufferedWriter` cannot be created, for example if the folder does not exist or is not writable.
	public init(
		logLevel: Logger.Level = .info,
		metadata: Logger.Metadata = [:],
		folderPath: FilePath,
		filenamePrefix: String,
		linesPerFile: Int = 1000,
		flushDelay: Duration = .seconds(1),
	) throws {
		self.metadata = metadata
		self.logLevel = logLevel
		self.folderPath = folderPath
		self.filenamePrefix = filenamePrefix
		writer = try BufferedWriter(
			folderPath: folderPath,
			filenamePrefix: filenamePrefix,
			linesPerFile: max(100, linesPerFile),
			flushDelay: flushDelay,
		)
	}

	/// Creates a `LogHandler` instance for a specific label, configured with the current log level and metadata.
	///
	/// This uses the global `LoggingSystem.metadataProvider` for additional metadata.
	///
	/// - Parameter label: The label identifying the logger or subsystem.
	/// - Returns: A `LogHandler` configured to write to this rotating file writer.
	public func handler(label: String) -> LogHandler {
		handler(label: label, metadataProvider: LoggingSystem.metadataProvider)
	}

	/// Creates a `LogHandler` instance for a specific label and metadata provider, configured with the current log level and metadata.
	///
	/// The provided `metadataProvider` supplies additional metadata for each log entry, which is merged with this handler's static metadata.
	///
	/// - Parameters:
	///   - label: The label identifying the logger or subsystem.
	///   - metadataProvider: An optional source of dynamic metadata for log entries.
	/// - Returns: A `LogHandler` configured to write to this rotating file writer.
	public func handler(label: String, metadataProvider: Logger.MetadataProvider?) -> LogHandler {
		var handler = StreamLogHandler(label: label, stream: writer, metadataProvider: metadataProvider)
		handler.logLevel = logLevel
		handler.metadata = metadata
		return handler
	}

	/// Forces an immediate flush of any buffered log data to disk.
	///
	/// This is useful to ensure all logs are written before application shutdown or during critical operations.
	///
	/// - Throws: Any error encountered while flushing buffered data to disk.
	public func flush() throws {
		try writer.flush()
	}
}
