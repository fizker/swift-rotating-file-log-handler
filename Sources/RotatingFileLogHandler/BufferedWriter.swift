import Dispatch
import Foundation
import FzkExtensions
import SystemPackage

/// This controls access to a file
final class BufferedWriter: @unchecked Sendable, TextOutputStream {
	private let linesPerFile = 1000

	let folderPath: FilePath
	let filenamePrefix: String

	/// The queue on which mutable state is changed. This keeps it Sendable.
	private let queue: DispatchQueue
	private var buffer: [String] = []
	private var writeTimer: Task<Void, Never>?

	private var linesWritten: Int = 0
	private var currentFile: FilePath?

	init(folderPath: FilePath, filenamePrefix: String) {
		self.queue = DispatchQueue(label: "BufferedWriter.queue.\(filenamePrefix)")
		self.folderPath = folderPath
		self.filenamePrefix = filenamePrefix
	}

	// Synchronous, thread-safe
	func write(_ value: String) {
		queue.sync {
			buffer.append(value)

			if writeTimer == nil {
				writeTimer = Task { [weak self] in
					do {
						try await Task.sleep(for: .seconds(5))
						try self?.flush()
					} catch {}
				}
			}
		}
	}

	func flush() throws {
		let (lines, currentFile) = queue.sync {
			writeTimer = nil

			let lines = buffer
			linesWritten += lines.count
			buffer.removeAll(keepingCapacity: true)

			let currentFile: FilePath
			if linesWritten >= linesPerFile || self.currentFile == nil {
				linesWritten = 0
				currentFile = folderPath.appending("\(filenamePrefix)-\(Date.now.iso8601).log")
				self.currentFile = currentFile
			} else {
				currentFile = self.currentFile!
			}

			return (lines, currentFile)
		}

		let data = Data(lines.joined(separator: "\n").utf8)

		let fd = try FileDescriptor.open(currentFile, .writeOnly, options: .append)
		try fd.closeAfter {
			_ = try fd.writeAll(data)
		}
	}
}
