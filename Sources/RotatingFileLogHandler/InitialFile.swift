/// Defines if the ``RotatingFileLogHandler`` can reuse the latest file from the previous run.
public enum InitialFile {
	/// Always opens a new log file
	case alwaysNew
	/// Reuses the latest file from previous run, if the rotation trigger limit would allow it.
	case reuseLatest
}
