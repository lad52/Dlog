//
//  LogProtocol.swift
//
//  Created by Iurii Khvorost <iurii.khvorost@gmail.com> on 2020/10/14.
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

/// LogProtocol parameters
///
class LogParams {
	let logger: DLog
	let category: String
	let scope: LogScope?
    let config: LogConfig?
	
	init(logger: DLog, category: String, scope: LogScope?, config: LogConfig?) {
		self.logger = logger
		self.category = category
		self.scope = scope
        self.config = config
	}
}

/// Base logger class
///
@objc
public class LogProtocol: NSObject {
    
    /// LogProtocol parameters
    lazy var params: LogParams = LogParams(logger: .disabled, category: "", scope: nil, config: nil)
    
    /// Logs a message that is essential to troubleshoot problems later.
    ///
    /// This method logs the message using the default log level.
    ///
    ///		let logger = DLog()
    ///		logger.log("message")
    ///
    /// - Parameters:
    /// 	- text: The message to be logged that can be used with any string interpolation literal.
    /// 	- file: The file this log message originates from (defaults to `#file`).
    /// 	- function: The function this log message originates from (defaults to `#function`).
    /// 	- line: The line this log message originates (defaults to `#line`).
    ///
    /// - Returns: Returns an optional string value indicating whether a log message is generated and processed.
    ///
    @objc
    @discardableResult
    public func log(_ message: @escaping @autoclosure () -> LogMessage, file: String = #file, function: String = #function, line: UInt = #line) -> String? {
        return params.logger.log(message: message, type: .log, params: params, file: file, function: function, line: line)
    }
    
    /// Logs trace information to help debug problems during the development of your code.
    ///
    /// Use it during development to record information that might aid you in debugging problems later.
    ///
    ///		let logger = DLog()
    ///		logger.trace("message")
    ///
    /// - Parameters:
    /// 	- text: The message to be logged that can be used with any string interpolation literal.
    /// 	- file: The file this log message originates from (defaults to `#file`).
    /// 	- function: The function this log message originates from (defaults to `#function`).
    /// 	- line: The line this log message originates (defaults to `#line`).
    ///
    /// - Returns: Returns an optional string value indicating whether a log message is generated and processed.
    ///
    @objc
    @discardableResult
    public func trace(_ message: @escaping @autoclosure () -> LogMessage? = nil,
                      file: String = #file, function: String = #function, line: UInt = #line,
                      addresses: [NSNumber] = Thread.callStackReturnAddresses) -> String? {
        let msg: () -> LogMessage = {
            precondition(self.params.logger.params.config != nil)
            let traceConfig = self.params.config?.traceConfig ?? self.params.logger.params.config!.traceConfig
            let info = traceInfo(title: message()?.description,
                                 function: function,
                                 addresses: addresses.dropFirst(),
                                 traceConfig: traceConfig)
            return LogMessage(stringLiteral: info)
        }
        return params.logger.log(message: msg, type: .trace, params: params, file: file, function: function, line: line)
    }
    
    /// Logs a message to help debug problems during the development of your code.
    ///
    /// Use this method during development to record information that might aid you in debugging problems later.
    ///
    ///		let logger = DLog()
    ///		logger.debug("message")
    ///
    /// - Parameters:
    /// 	- text: The message to be logged that can be used with any string interpolation literal.
    /// 	- file: The file this log message originates from (defaults to `#file`).
    /// 	- function: The function this log message originates from (defaults to `#function`).
    /// 	- line: The line this log message originates (defaults to `#line`).
    ///
    /// - Returns: Returns an optional string value indicating whether a log message is generated and processed.
    ///
    @objc
    @discardableResult
    public func debug(_ message: @escaping @autoclosure () -> LogMessage, file: String = #file, function: String = #function, line: UInt = #line) -> String? {
        return params.logger.log(message: message, type: .debug, params: params, file: file, function: function, line: line)
    }
    
    /// Logs a message that is helpful, but not essential, to diagnose issues with your code.
    ///
    /// Use this method to capture information messages and helpful data.
    ///
    ///		let logger = DLog()
    ///		logger.info("message")
    ///
    /// - Parameters:
    /// 	- text: The message to be logged that can be used with any string interpolation literal.
    /// 	- file: The file this log message originates from (defaults to `#file`).
    /// 	- function: The function this log message originates from (defaults to `#function`).
    /// 	- line: The line this log message originates (defaults to `#line`).
    ///
    /// - Returns: Returns an optional string value indicating whether a log message is generated and processed.
    ///
    @objc
    @discardableResult
    public func info(_ message: @escaping @autoclosure () -> LogMessage, file: String = #file, function: String = #function, line: UInt = #line) -> String? {
        return params.logger.log(message: message, type: .info, params: params, file: file, function: function, line: line)
    }
    
    /// Logs a warning that occurred during the execution of your code.
    ///
    /// Use this method to capture information about things that might result in an error.
    ///
    ///		let logger = DLog()
    ///		logger.warning("message")
    ///
    /// - Parameters:
    /// 	- text: The message to be logged that can be used with any string interpolation literal.
    /// 	- file: The file this log message originates from (defaults to `#file`).
    /// 	- function: The function this log message originates from (defaults to `#function`).
    /// 	- line: The line this log message originates (defaults to `#line`).
    ///
    /// - Returns: Returns an optional string value indicating whether a log message is generated and processed.
    ///
    @objc
    @discardableResult
    public func warning(_ message: @escaping @autoclosure () -> LogMessage, file: String = #file, function: String = #function, line: UInt = #line) -> String? {
        return params.logger.log(message: message, type: .warning, params: params, file: file, function: function, line: line)
    }
    
    /// Logs an error that occurred during the execution of your code.
    ///
    /// Use this method to report errors.
    ///
    ///		let logger = DLog()
    ///		logger.error("message")
    ///
    /// - Parameters:
    /// 	- text: The message to be logged that can be used with any string interpolation literal.
    /// 	- file: The file this log message originates from (defaults to `#file`).
    /// 	- function: The function this log message originates from (defaults to `#function`).
    /// 	- line: The line this log message originates (defaults to `#line`).
    ///
    /// - Returns: Returns an optional string value indicating whether a log message is generated and processed.
    ///
    @objc
    @discardableResult
    public func error(_ message: @escaping @autoclosure () -> LogMessage, file: String = #file, function: String = #function, line: UInt = #line) -> String? {
        return params.logger.log(message: message, type: .error, params: params, file: file, function: function, line: line)
    }
    
    /// Logs a traditional C-style assert notice with an optional message.
    ///
    /// Use this function for internal sanity checks.
    ///
    ///		let logger = DLog()
    ///		logger.assert(condition, "message")
    ///
    /// - Parameters:
    /// 	- condition: The condition to test.
    /// 	- text: A string to print if `condition` is evaluated to `false`. The default is an empty string.
    /// 	- file: The file this log message originates from (defaults to `#file`).
    /// 	- function: The function this log message originates from (defaults to `#function`).
    /// 	- line: The line this log message originates (defaults to `#line`).
    ///
    /// - Returns: Returns an optional string value indicating whether a log message is generated and processed.
    ///
    @objc
    @discardableResult
    public func assert(_ condition: @autoclosure () -> Bool, _ message: @escaping @autoclosure () -> LogMessage = "", file: String = #file, function: String = #function, line: UInt = #line) -> String? {
        guard params.logger != .disabled && !condition()  else { return nil }
        return params.logger.log(message: message, type: .assert, params: params, file: file, function: function, line: line)
    }
    
    /// Logs a bug or fault that occurred during the execution of your code.
    ///
    /// Use this method to capture critical errors that occurred during the execution of your code.
    ///
    ///		let logger = DLog()
    ///		logger.fault("message")
    ///
    /// - Parameters:
    /// 	- text: The message to be logged that can be used with any string interpolation literal.
    /// 	- file: The file this log message originates from (defaults to `#file`).
    /// 	- function: The function this log message originates from (defaults to `#function`).
    /// 	- line: The line this log message originates (defaults to `#line`).
    ///
    /// - Returns: Returns an optional string value indicating whether a log message is generated and processed.
    ///
    @objc
    @discardableResult
    public func fault(_ message: @escaping @autoclosure () -> LogMessage, file: String = #file, function: String = #function, line: UInt = #line) -> String? {
        return params.logger.log(message: message, type: .fault, params: params, file: file, function: function, line: line)
    }
    
    /// Creates a scope object that can assign log messages to itself.
    ///
    /// Scope provides a mechanism for grouping log messages in your program.
    ///
    ///		let logger = DLog()
    ///		logger.scope("Auth") { scope in
    ///			scope.log("message")
    ///		}
    ///
    /// - Parameters:
    /// 	- name: The name of new scope object.
    /// 	- file: The file this log message originates from (defaults to `#file`).
    /// 	- function: The function this log message originates from (defaults to `#function`).
    /// 	- line: The line this log message originates (defaults to `#line`).
    /// 	- closure: A closure to be executed with the scope. The block takes a single `LogScope` parameter and has no return value.
    ///
    /// - Returns: An `LogScope` object for the new scope.
    ///
    @objc
    @discardableResult
    public func scope(_ name: @escaping @autoclosure () -> LogMessage, file: String = #file, function: String = #function, line: UInt = #line, closure: ((LogScope) -> Void)? = nil) -> LogScope {
        return params.logger.scope(name: name, params: params, file: file, function: function, line: line, closure: closure)
    }
    
    /// Creates an interval object that logs a detailed message with accumulated statistics.
    ///
    /// Logs a point of interest in your code as time intervals for debugging performances.
    ///
    ///		let logger = DLog()
    ///		logger.interval("Sorting") {
    ///			...
    ///		}
    ///
    /// - Parameters:
    /// 	- name: The name of new interval object.
    /// 	- file: The file this log message originates from (defaults to `#file`).
    /// 	- function: The function this log message originates from (defaults to `#function`).
    /// 	- line: The line this log message originates (defaults to `#line`).
    /// 	- closure: A closure to be executed with the interval.
    ///
    /// - Returns: An `LogInterval` object for the new interval.
    ///
    @discardableResult
    public func interval(_ name: StaticString, file: String = #file, function: String = #function, line: UInt = #line, closure: (() -> Void)? = nil) -> LogInterval {
        return params.logger.interval(name: "\(name)", staticName: name, params: params, file: file, function: function, line: line, closure: closure)
    }
    
    /// Creates an interval object for Objective-C code.
    @objc
    @discardableResult
    public func interval(name: String, file: String, function: String, line: UInt, closure: (() -> Void)?) -> LogInterval {
        return params.logger.interval(name: name, staticName: nil, params: params, file: file, function: function, line: line, closure: closure)
    }
}
