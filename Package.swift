// swift-tools-version: 6.2

import PackageDescription

let package = Package(
	name: "swift-rotating-file-log-handler",
	platforms: [
		.macOS(.v13),
	],
	products: [
		.library(
			name: "RotatingFileLogHandler",
			targets: ["RotatingFileLogHandler"],
		),
	],
	dependencies: [
		.package(url: "https://github.com/apple/swift-log", from: "1.10.1"),
		.package(url: "https://github.com/apple/swift-system", from: "1.6.4"),
		.package(url: "https://github.com/fizker/swift-extensions.git", from:"1.4.0"),
	],
	targets: [
		.target(
			name: "RotatingFileLogHandler",
			dependencies: [
				.product(name: "FzkExtensions", package: "swift-extensions"),
				.product(name: "Logging", package: "swift-log"),
				.product(name: "SystemPackage", package: "swift-system"),
			],
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
