public enum RotationTrigger {
	case lines(UInt64)
	case size(Bytes)
}

public struct Bytes: Sendable, Equatable, Comparable {
	let bytes: UInt64

	init(_ bytes: UInt64) { self.bytes = bytes }

	public static func bytes(_ value: UInt64) -> Bytes { .init(value) }
	public static func kilobytes(_ value: UInt64) -> Bytes { .init(value * 1_024) }
	public static func megabytes(_ value: UInt64) -> Bytes { .init(value * 1_024 * 1_024) }
	public static func gigabytes(_ value: UInt64) -> Bytes { .init(value * 1_024 * 1_024 * 1_024) }

	public static func < (lhs: Bytes, rhs: Bytes) -> Bool { lhs.bytes < rhs.bytes }
}
