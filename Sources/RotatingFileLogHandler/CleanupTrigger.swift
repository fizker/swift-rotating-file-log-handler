typealias TimeInterval = Double

/// Rules for when automatic cleanup of old logs should happen.
public enum CleanupTrigger: Equatable {
	/// Cleanup never happens.
	case never
	/// Cleanup happens when the number of logs exceed the given number.
	case fileCount(Int)
	/// Cleanup removes all files older than the given value.
	case age(Duration)
}

extension Duration {
	/// Construct a `Duration` given a number of minutes represented as a
	/// `BinaryInteger`.
	///
	///       let d: Duration = .minutes(77)
	///
	/// - Returns: A `Duration` representing a given number of minutes.
	public static func minutes(_ minutes: some BinaryInteger) -> Duration {
		seconds(minutes * 60)
	}
	/// Construct a `Duration` given a number of hours represented as a
	/// `BinaryInteger`.
	///
	///       let d: Duration = .hours(77)
	///
	/// - Returns: A `Duration` representing a given number of hours.
	public static func hours(_ hours: some BinaryInteger) -> Duration {
		minutes(hours * 60)
	}
	/// Construct a `Duration` given a number of days represented as a
	/// `BinaryInteger`.
	///
	///       let d: Duration = .days(77)
	///
	/// - Returns: A `Duration` representing a given number of days.
	public static func days(_ days: some BinaryInteger) -> Duration {
		hours(days * 24)
	}

	/// Construct a `Duration` given a number of minutes represented as a
	/// `Double` by converting the value into the closest attosecond scale value.
	///
	///       let d: Duration = .minutes(22.93)
	///
	/// - Returns: A `Duration` representing a given number of minutes.
	public static func minutes(_ minutes: Double) -> Duration {
		seconds(minutes * 60)
	}
	/// Construct a `Duration` given a number of hours represented as a
	/// `Double` by converting the value into the closest attosecond scale value.
	///
	///       let d: Duration = .hours(22.93)
	///
	/// - Returns: A `Duration` representing a given number of hours.
	public static func hours(_ hours: Double) -> Duration {
		minutes(hours * 60)
	}
	/// Construct a `Duration` given a number of days represented as a
	/// `Double` by converting the value into the closest attosecond scale value.
	///
	///       let d: Duration = .days(22.93)
	///
	/// - Returns: A `Duration` representing a given number of days.
	public static func days(_ days: Double) -> Duration {
		hours(days * 24)
	}

	var asTimeInterval: TimeInterval {
		let (seconds, attoseconds) = components
		let milliseconds = Double(attoseconds / 1_000_000_000_000_000)
		return Double(seconds) + milliseconds / 1000
	}
}
