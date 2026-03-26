import Dispatch
import Foundation
import FzkExtensions
import SystemPackage

/// This controls access to a file
final class BufferedWriter: @unchecked Sendable, TextOutputStream {
	private let rotation: RotationTrigger
	private let flushDelay: Duration
	private let cleanup: CleanupTrigger

	let folderPath: FilePath
	let filenamePrefix: String

	/// The queue on which mutable state is changed. This keeps it Sendable.
	private let queue: DispatchQueue
	private var buffer: [String] = []
	private var writeTimer: Task<Void, Never>?

	private var currentSize: UInt64 = 0
	private var currentFile: FilePath?

	init(
		folderPath: FilePath,
		filenamePrefix: String,
		rotation: RotationTrigger,
		cleanup: CleanupTrigger,
		flushDelay: Duration,
	) throws {
		self.queue = DispatchQueue(label: "BufferedWriter.queue.\(filenamePrefix)")
		self.folderPath = folderPath
		self.filenamePrefix = filenamePrefix
		self.rotation = rotation
		self.cleanup = cleanup
		self.flushDelay = flushDelay

		try FileManager.default.createDirectory(atPath: folderPath.string, withIntermediateDirectories: true)
	}

	deinit {
		try? flush()
	}

	// Synchronous, thread-safe
	func write(_ value: String) {
		queue.sync {
			buffer.append(value)

			if writeTimer == nil {
				writeTimer = Task { [weak self] in
					guard let self
					else { return }
					do {
						try await Task.sleep(for: flushDelay)
						try flush()
					} catch {}
				}
			}
		}
	}

	func flush() throws {
		let (lines, currentFile) = queue.sync {
			writeTimer = nil

			let lines = buffer.map(\.utf8)
			let target: UInt64
			switch rotation {
			case let .lines(maxLines):
				target = maxLines
				currentSize += UInt64(lines.count)
			case let .size(bytes):
				target = bytes.bytes
				currentSize += lines.reduce(0) { $0 + UInt64($1.count) }
			}

			buffer.removeAll(keepingCapacity: true)

			let currentFile: FilePath
			if currentSize >= target || self.currentFile == nil {
				currentSize = 0
				currentFile = folderPath.appending("\(filenamePrefix)-\(Date.now.iso8601).log")
				self.currentFile = currentFile
			} else {
				currentFile = self.currentFile!
			}

			return (lines, currentFile)
		}

		let data = Data(lines.joined())

		let fd = try FileDescriptor.open(
			currentFile,
			.writeOnly,
			options: [.append, .create],
			permissions: [ .ownerReadWrite, .groupRead ],
		)
		try fd.closeAfter {
			_ = try fd.writeAll(data)
		}

		try performCleanup()
	}

	func performCleanup() throws {
		guard cleanup != .never
		else { return }

		let fm = FileManager.default
		let allFiles = try fm.contentsOfDirectory(atPath: folderPath.string)
			.filter { $0.starts(with: filenamePrefix) }
			.map(folderPath.appending(_:))

		let filesToRemove: [FilePath]

		switch cleanup {
		case .never:
			return
		case let .age(age):
			let cutoff = Date.now - age.asTimeInterval
			filesToRemove = try allFiles.filter { file in
				let attributes = try fm.attributesOfItem(atPath: file.string)
				guard let modDate = attributes[.modificationDate] as? Date ?? attributes[.creationDate] as? Date
				else { return false }
				return modDate < cutoff
			}
		case let .fileCount(fileCount):
			let toRemove = allFiles.count - fileCount
			guard toRemove > 0
			else { return }
			filesToRemove = Array(allFiles[0..<toRemove])
		}

		for file in filesToRemove {
			try fm.removeItem(atPath: file.string)
		}
	}
}
