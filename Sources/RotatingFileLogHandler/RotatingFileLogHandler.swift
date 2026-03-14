public import Logging
public import SystemPackage

public class RotatingFileLogHandler {
	public var metadata: Logger.Metadata
	public var logLevel: Logger.Level
	let folderPath: FilePath
	let filenamePrefix: String
	let writer: BufferedWriter

	public init(logLevel: Logger.Level = .info, metadata: Logger.Metadata = [:], folderPath: FilePath, filenamePrefix: String) {
		self.metadata = metadata
		self.logLevel = logLevel
		self.folderPath = folderPath
		self.filenamePrefix = filenamePrefix
		writer = BufferedWriter(folderPath: folderPath, filenamePrefix: filenamePrefix)
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
