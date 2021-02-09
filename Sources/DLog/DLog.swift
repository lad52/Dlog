//
//  DLog
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


/// A `DLog` is the central class to emit log messages to specified outputs using one of the methods corresponding to
/// a log level.
///
/// Create an instance and use it to log text messages about your app’s behaviour and to help you assess the state
/// of your app later. You also can choose a target output and a log level to indicate the severity of that message.
///
///     let log = DLog()
///     log.log("Hello DLog!")
///
public class DLog {
	
	private let output: LogOutput?

	@Atomic private var categories = [String : LogCategory]()
	@Atomic private var scopes = [LogScope]()
	@Atomic private var intervals = [LogInterval]()
	
	/// The shared disabled log.
	///
	/// Using this constant prevents from logging messages.
	///
	/// 	let log = DLog.disabled
	///
	public static let disabled = DLog(nil)

	/// Creates a logger object that assigns log messages to the specified category.
	///
	/// 	let log = DLog()
	/// 	let netLog = log["NET"]
	/// 	let netLog.log("Hello Net!")
	///
	public subscript(category: String) -> LogCategory {
		synchronized(self) {
			if let log = categories[category] {
				return log
			}
			let log = LogCategory(log: self, category: category)
			categories[category] = log
			return log
		}
	}

	/// Creates a logger instance with an existing output object.
	///
	/// If an output is not provided DLog uses Standard output as a target.
	///
	/// - Parameters:
	/// 	- output: a target output object
	///
	public init(_ output: LogOutput? = .stdout) {
		self.output = output
	}

	// Scope

	func enter(scope: LogScope) {
		guard let out = output else { return }

		synchronized(self) {
			if let current = self.scope {
				scope.level = current.level + 1
			}
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

	private func interval(id: String, name: StaticString, category: String, scope: LogScope?, file: String, function: String, line: UInt, scopes: [LogScope]) -> LogInterval {
		if let interval = intervals.first(where: { $0.id == id }) {
			return interval
		}
		else {
			let interval = LogInterval(log: self,
									   category: category,
									   scope: scope,
									   fileName: file,
									   funcName: function,
									   line: line,
									   name: name)
			intervals.append(interval)
			return interval
		}
	}
}

extension DLog : LogProtocol {
	
	var category : String { "DLOG" }
	
	var scope: LogScope? {
		synchronized(self) {
			scopes.last
		}
	}

	func log(_ text: String, type: LogType, category: String, scope: LogScope?, file: String, function: String, line: UInt) -> String? {
		guard let out = output else { return nil }

		let fileName = NSString(string: file).lastPathComponent
		let item = LogItem(
			time: Date(),
			category: category,
			scope: scope,
			type: type,
			fileName: fileName,
			funcName: function,
			line: line,
			text: text)
		return out.log(item: item, scopes: scopes)
	}

	func scope(_ text: String, category: String, file: String, function: String, line: UInt, closure: ((LogScope) -> Void)?) -> LogScope {
		let fileName = NSString(string: file).lastPathComponent
		let scope = LogScope(log: self,
							 category: category,
							 fileName: fileName,
							 funcName: function,
							 line: line,
							 text: text)

		if let block = closure {
			scope.enter()

			block(scope)

			scope.leave()
		}

		return scope
	}

	func interval(_ name: StaticString, category: String, scope: LogScope?, file: String, function: String, line: UInt, closure: (() -> Void)?) -> LogInterval {
		let fileName = NSString(string: file).lastPathComponent
		let id = "\(fileName):\(line)"

		let sp = interval(id: id, name: name, category: category, scope: scope, file: fileName, function: function, line: line, scopes: scopes)

		guard closure != nil else {
			return sp
		}

		sp.begin()

		closure?()

		sp.end()

		return sp
	}
}
