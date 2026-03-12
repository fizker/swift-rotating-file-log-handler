// swift-tools-version: 6.2

import PackageDescription

let package = Package(
	name: "swift-rotating-file-log-handler",
	products: [
		.library(
			name: "RotatingFileLogHandler",
			targets: ["RotatingFileLogHandler"],
		),
	],
	dependencies: [
		.package(url: "https://github.com/apple/swift-log", from: "1.10.1"),
	],
	targets: [
		.target(
			name: "RotatingFileLogHandler",
		),
		.testTarget(
			name: "RotatingFileLogHandlerTests",
			dependencies: [
				"RotatingFileLogHandler",
				.product(name: "Logging", package: "swift-log"),
			],
		),
	],
)
