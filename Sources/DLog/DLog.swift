//
//  DLog.swift
//
//  Created by Iurii Khvorost <iurii.khvorost@gmail.com> on 2020/06/03.
//  Copyright © 2020 Iurii Khvorost. All rights reserved.
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.
//

import Foundation

extension OptionSet where RawValue == Int {
	/// All available options
	public static var all: Self {
		Self.init(rawValue: Int.max)
	}
	
	init(_ shift: Int) {
		self.init(rawValue: 1 << shift)
	}
}

/// Indicates which info from the logger should be used.
public struct LogOptions: OptionSet {
	/// The corresponding value of the raw type.
	public let rawValue: Int
	
	/// Creates a new option set from the given raw value.
	public init(rawValue: Int) {
		self.rawValue = rawValue
	}
	
	/// Start sign
	public static let sign = Self(0)
	
	/// Timestamp
	public static let time = Self(1)
	
	/// Level of the current scope
	public static let level = Self(2)
	
	/// Category
	public static let category = Self(3)
	
	/// The current scope padding
	public static let padding = Self(4)
	
	/// Log type
	public static let type = Self(5)
	
	/// Location
	public static let location = Self(6)
	
	/// Compact: `.sign` and `.time`
	public static let compact: Self = [.sign, .time]
	
	/// Regular: `.sign`, `.time`, `.category`, `.padding`, `.type` and `.location`
	public static let regular: Self = [.sign, .time, .category, .padding, .type, .location]
}

/// Contains configuration values regarding to the logger
public struct LogConfig {
	/// Start sign of the logger
	public var sign: Character = "•"
	
	/// Set which info from the logger should be used. Default value is `LogOptions.regular`.
	public var options: LogOptions = .regular
	
	/// Configuration of the `trace` method
	public var traceConfig = TraceConfig()
	
	/// Configuration of intervals
	public var intervalConfig = IntervalConfig()
	
	/// Creates the logger's default configuration.
	public init() {}
}

/// The central class to emit log messages to specified outputs using one of the methods corresponding to a log level.
///
public class DLog: LogProtocol {
	
	private let output: LogOutput?

	@Atomic private var scopes = [LogScope]()
	
	/// The shared disabled logger.
	///
	/// Using this constant prevents from logging messages.
	///
	/// 	let logger = DLog.disabled
	///
	@objc
	public static let disabled = DLog(nil)
	
	/// Creates a logger object that assigns log messages to a specified category.
	///
	/// You can define category name to differentiate unique areas and parts of your app and DLog uses this value
	/// to categorize and filter related log messages.
	///
	/// 	let logger = DLog()
	/// 	let netLogger = logger["NET"]
	/// 	let netLogger.log("Hello Net!")
	///
	@objc
	public subscript(name: String) -> LogCategory {
		LogCategory(logger: self, category: name)
	}
    
    public func category(name: String, config: LogConfig? = nil) -> LogCategory {
        LogCategory(logger: self, category: name, config: config)
    }

	/// Creates the logger instance with a target output object.
	///
	/// Create an instance and use it to log text messages about your app’s behaviour and to help you assess the state
	/// of your app later. You also can choose a target output and a log level to indicate the severity of that message.
	///
	/// 	let logger = DLog()
	///     logger.log("Hello DLog!")
	///
	/// - Parameters:
	/// 	- output: A target output object. If it is omitted the logger uses `stdout` by default.
	///
	public init(_ output: LogOutput? = .stdout, config: LogConfig = LogConfig()) {
		self.output = output
		super.init()
        params = LogParams(logger: self, category: "DLOG", scope: nil, config: config)
	}
    
    /// Creates the logger instance with a list of linked outputs for both swift and objective-c code.
    ///
    /// Swift:
    ///
    ///     let logger = DLog([.textPlain, .stdout])
    ///
    /// Objective-C:
    ///
    ///     DLog* logger = [[DLog alloc] initWithOutputs:@[LogOutput.textPlain, filter, LogOutput.stdOut]];
    ///
    /// - Parameters:
    ///     - outputs: An array of outputs.
    ///
    @objc
    public convenience init(outputs: [LogOutput]) {
        let output: LogOutput? = {
            if outputs.count == 0 {
                return .stdout
            }
            else {
                return outputs.count == 1
                    ? outputs.first
                    : outputs.reduce(.textPlain, =>)
            }
        }()
        self.init(output)
    }
    
    /// Creates the default logger.
    @objc
    public override convenience init() {
        self.init(_:config:)()
	}

	// Scope

	func enter(scope: LogScope) {
		guard let out = output else { return }

		synchronized(self) {
			let level = scopes.last?.level ?? 0
			scope.level = level + 1
			scopes.append(scope)

			out.scopeEnter(scope: scope, scopes: scopes)
		}
	}

	func leave(scope: LogScope) {
		guard let out = output else { return }

		synchronized(self) {
			if scopes.contains(where: { $0.uid == scope.uid }) {
				out.scopeLeave(scope: scope, scopes: scopes)

				scopes.removeAll { $0.uid == scope.uid }
			}
		}
	}

	// Interval
	
	func begin(interval: LogInterval) {
		guard let out = output else { return }

		out.intervalBegin(interval: interval)
	}

	func end(interval: LogInterval) {
		guard let out = output else { return }

		out.intervalEnd(interval: interval, scopes: scopes)
	}

	func log(text: @escaping () -> String, type: LogType, category: String, scope: LogScope?, config: LogConfig?, file: String, function: String, line: UInt) -> String? {
        guard let out = output else { return nil }

        precondition(params.config != nil)
        
		let item = LogItem(
			category: category,
			scope: scope,
			type: type,
			file: file,
			funcName: function,
			line: line,
			text: text,
            config: config ?? params.config!)
		return out.log(item: item, scopes: scopes)
	}

	func scope(name: String, category: String, config: LogConfig?, file: String, function: String, line: UInt, closure: ((LogScope) -> Void)?) -> LogScope {
        precondition(params.config != nil)
        
        let scope = LogScope(logger: self,
							 category: category,
							 file: file,
							 funcName: function,
							 line: line,
							 name: name,
                             config: config ?? params.config!)

		if let block = closure {
			scope.enter()
			block(scope)
			scope.leave()
		}

		return scope
	}

	func interval(name: String, staticName: StaticString?, category: String, scope: LogScope?, config: LogConfig?, file: String, function: String, line: UInt, closure: (() -> Void)?) -> LogInterval {
        precondition(params.config != nil)
        
        let interval = LogInterval(logger: self,
                                   category: category,
                                   scope: scope,
                                   name: name,
                                   staticName: staticName,
                                   file: file,
                                   funcName: function,
                                   line: line,
                                   config: config ?? params.config!)
		
		if let block = closure {
			interval.begin()
			block()
			interval.end()
		}

		return interval
	}
}
