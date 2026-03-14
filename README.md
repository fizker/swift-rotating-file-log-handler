# RotatingFileLogHandler

A SwiftLog-compatible log handler that writes to rotating files on disk.
It buffers writes for performance and automatically rotates to new files after
a configurable number of lines.

## How to use

1. Add `.package(url: "https://github.com/fizker/swift-rotating-file-log-handler.git", from: "1.0.0")` to the list of dependencies in your Package.swift file.
2. Add `.product(name: "RotatingFileLogHandler", package: "swift-rotating-file-log-handler")` to the dependencies of the targets that need to use the models.

Then hook up this LogHandler with SwiftLog:

```swift
import Logging
import RotatingFileLogHandler

let fileLogHandler = try RotatingFileLogHandler(
    folderPath: "/var/log/myapp",
    filenamePrefix: "app-log",
)

LoggingSystem.bootstrap(fileLogHandler.handler(label:))

var logger = Logger(label: "com.example.myapp")
logger.info("Application started")

... before exiting application
try logHandler.flush()
```
