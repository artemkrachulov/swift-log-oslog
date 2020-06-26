import Foundation
import Logging
import os

public struct LoggingOSLog: LogHandler {
    public var logLevel: Logger.Level = .info
    public let label: String
	
	private var _oslogger: AnyObject?
    @available(iOS 8.0, *)
    var oslogger: OSLog {
        get {
            return _oslogger as! OSLog
        }
        set {
            _oslogger = newValue
        }
    }
	
	
    public init(label: String) {
        self.label = label
		if #available(iOS 10.0, *) {
			self.oslogger = OSLog(subsystem: Bundle.main.bundleIdentifier!, category: label)
		}
    }
    
    public func log(level: Logger.Level, message: Logger.Message, metadata: Logger.Metadata?, file: String, function: String, line: UInt) {
		
		guard ProcessInfo.processInfo.environment[label] == nil || ProcessInfo.processInfo.environment[label] == "true" else { return }
		
        var combinedPrettyMetadata = self.prettyMetadata
        if let metadataOverride = metadata, !metadataOverride.isEmpty {
            combinedPrettyMetadata = self.prettify(
                self.metadata.merging(metadataOverride) {
                    return $1
                }
            )
        }
        
        var formedMessage = message.description
        if combinedPrettyMetadata != nil {
            formedMessage += " -- " + combinedPrettyMetadata!
        }
		
		let icon = LoggingOSLog.icon(loggerLevel: level)
		let log = [icon, formedMessage].filter({ !$0.isEmpty }).joined(separator: " ")
		
		if #available(iOS 10.0, *) {
			os_log("%{public}@", log: self.oslogger, type: OSLogType.from(loggerLevel: level), log)
		} else {
			NSLog(String(describing: log))
		}
    }
    
    private var prettyMetadata: String?
    public var metadata = Logger.Metadata() {
        didSet {
            self.prettyMetadata = self.prettify(self.metadata)
        }
    }
    
    /// Add, remove, or change the logging metadata.
    /// - parameters:
    ///    - metadataKey: the key for the metadata item.
    public subscript(metadataKey metadataKey: String) -> Logger.Metadata.Value? {
        get {
            return self.metadata[metadataKey]
        }
        set {
            self.metadata[metadataKey] = newValue
        }
    }
    
    private func prettify(_ metadata: Logger.Metadata) -> String? {
        if metadata.isEmpty {
            return nil
        }
        return metadata.map {
            "\($0)=\($1)"
        }.joined(separator: " ")
    }
	
	static func icon(loggerLevel: Logger.Level) -> String {
        switch loggerLevel {
        case .trace:
            return ""
        case .debug:
            return "💬"
        case .info:
            return ""
        case .notice:
            return "📌"
        case .warning:
            return "⚠️"
        case .error:
            return "❌"
        case .critical:
            return "🔥"
        }
	}
}

@available(OSX 10.12, *)
@available(iOS 10.0, *)
@available(tvOS 10.0, *)
@available(watchOS 3.0, *)
extension OSLogType {
    static func from(loggerLevel: Logger.Level) -> Self {
        switch loggerLevel {
        case .trace:
            /// `OSLog` doesn't have `trace`, so use `debug`
            return .debug
        case .debug:
            return .debug
        case .info:
            return .info
        case .notice:
            /// `OSLog` doesn't have `notice`, so use `info`
            return .info
        case .warning:
            /// `OSLog` doesn't have `warning`, so use `info`
            return .info
        case .error:
            return .error
        case .critical:
            return .fault
        }
    }
}
