public import Logging
public import SystemPackage

public class RotatingFileLogHandler {
	public var metadata: Logger.Metadata
	public var logLevel: Logger.Level
	let folderPath: FilePath
	let filenamePrefix: String
	let writer: BufferedWriter

	public init(
		logLevel: Logger.Level = .info,
		metadata: Logger.Metadata = [:],
		folderPath: FilePath,
		filenamePrefix: String,
		linesPerFile: Int = 1000,
	) throws {
		self.metadata = metadata
		self.logLevel = logLevel
		self.folderPath = folderPath
		self.filenamePrefix = filenamePrefix
		writer = try BufferedWriter(
			folderPath: folderPath,
			filenamePrefix: filenamePrefix,
			linesPerFile: max(100, linesPerFile),
		)
	}

	public func handler(label: String) -> LogHandler {
		handler(label: label, metadataProvider: LoggingSystem.metadataProvider)
	}

	public func handler(label: String, metadataProvider: Logger.MetadataProvider?) -> LogHandler {
		var handler = StreamLogHandler(label: label, stream: writer, metadataProvider: metadataProvider)
		handler.logLevel = logLevel
		handler.metadata = metadata
		return handler
	}
}
